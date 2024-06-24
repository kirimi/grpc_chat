import 'dart:async';
import 'dart:isolate';

import 'package:chats/data/chat/chat.dart';
import 'package:chats/data/db.dart';
import 'package:chats/data/message/message.dart';
import 'package:chats/generated/chats.pbgrpc.dart';
import 'package:chats/utils.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:stormberry/stormberry.dart';

class ChatRpc extends ChatsRpcServiceBase {
  final StreamController<MessageDto> _messageStreamController =
      StreamController.broadcast();

  @override
  Future<ResponseDto> createChat(
    ServiceCall call,
    ChatDto request,
  ) async {
    if (request.name.isEmpty) {
      throw GrpcError.invalidArgument('Chat name is empty');
    }

    if (request.memberId.isEmpty) {
      throw GrpcError.invalidArgument('Member id is empty');
    }

    final userId = Utils.getUserIdFromMetadata(call);

    await db.chats.insertOne(ChatInsertRequest(
      name: request.name,
      authorId: userId.toString(),
      memberId: request.memberId,
    ));

    return ResponseDto(message: 'success');
  }

  @override
  Future<ResponseDto> deleteChat(
    ServiceCall call,
    ChatDto request,
  ) async {
    if (request.id.isEmpty) {
      throw GrpcError.invalidArgument('Chat id is empty');
    }

    final chat = await db.chats.queryShortView(int.parse(request.id));
    if (chat == null) {
      throw GrpcError.notFound('Chat not found');
    }

    final userId = Utils.getUserIdFromMetadata(call);
    final authorId = int.parse(chat.authorId);
    if (authorId != userId) {
      throw GrpcError.permissionDenied();
    }

    await db.chats.deleteOne(chat.id);

    return ResponseDto(message: 'success');
  }

  @override
  Future<ListChatsDto> fetchAllChats(
    ServiceCall call,
    RequestDto request,
  ) async {
    final userId = Utils.getUserIdFromMetadata(call);
    final listChats = await db.chats.queryShortViews(
      QueryParams(
        where: "author_id='$userId' OR member_id='$userId'",
      ),
    );
    if (listChats.isEmpty) {
      return ListChatsDto(chats: []);
    }

    return await Isolate.run(() => Utils.parseChats(listChats));
  }

  @override
  Future<ChatDto> fetchChat(
    ServiceCall call,
    ChatDto request,
  ) async {
    if (request.id.isEmpty) {
      throw GrpcError.invalidArgument('Chat id is empty');
    }

    final chat = await db.chats.queryFullView(int.parse(request.id));
    if (chat == null) {
      throw GrpcError.notFound('Chat not found');
    }

    final userId = Utils.getUserIdFromMetadata(call);
    if (chat.authorId != userId.toString() ||
        chat.memberId != userId.toString()) {
      throw GrpcError.permissionDenied();
    }

    return await Isolate.run(() => Utils.parseChat(chat));
  }

  @override
  Future<ResponseDto> sendMessage(
    ServiceCall call,
    MessageDto request,
  ) async {
    final userId = Utils.getUserIdFromMetadata(call);
    final chatId = int.tryParse(request.chatId);
    if (chatId == null) {
      throw GrpcError.invalidArgument('Chat not found');
    }

    if (request.body.isEmpty) {
      throw GrpcError.invalidArgument('Body is empty');
    }

    final messageId = await db.messages.insertOne(MessageInsertRequest(
      body: request.body,
      authorId: userId.toString(),
      chatId: chatId,
    ));

    _messageStreamController.sink.add(request.deepCopy()
      ..authorId = userId.toString()
      ..id = messageId.toString());

    return ResponseDto(message: 'success');
  }

  @override
  Future<ResponseDto> deleteMessage(
    ServiceCall call,
    MessageDto request,
  ) async {
    if (request.id.isEmpty) {
      throw GrpcError.invalidArgument('Message id is empty');
    }

    final message = await db.messages.queryMessage(int.parse(request.id));
    if (message == null) {
      throw GrpcError.notFound('Message not found');
    }

    final userId = Utils.getUserIdFromMetadata(call);
    if (int.parse(message.authorId) != userId) {
      throw GrpcError.permissionDenied();
    }

    await db.messages.deleteOne(message.id);

    return ResponseDto(message: 'success');
  }

  @override
  Stream<MessageDto> listenChat(
    ServiceCall call,
    ChatDto request,
  ) async* {
    if (request.id.isEmpty) {
      throw GrpcError.invalidArgument('Chat id is empty');
    }
    yield* _messageStreamController.stream
        .where((message) => message.chatId == request.id);
  }
}
