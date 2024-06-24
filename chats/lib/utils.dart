import 'package:chats/data/chat/chat.dart';
import 'package:chats/data/message/message.dart';
import 'package:chats/env.dart';
import 'package:chats/generated/chats.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

abstract class Utils {
  static int getUserIdFromToken(String token) {
    final jwtClaim = verifyJwtHS256Signature(token, Env.sk);
    final id = int.tryParse(jwtClaim['user_id']);
    if (id == null) {
      throw GrpcError.dataLoss('JWT error. User id not found');
    }
    return id;
  }

  static int getUserIdFromMetadata(ServiceCall serviceCall) {
    final accessToken = serviceCall.clientMetadata?['access_token'] ?? '';
    return getUserIdFromToken(accessToken);
  }

  static ListChatsDto parseChats(List<ShortChatView> list) {
    try {
      return ListChatsDto(
        chats: [
          ...list.map((chat) => ChatDto(
                id: chat.id.toString(),
                name: chat.name,
                authorId: chat.authorId,
                memberId: chat.memberId
              ))
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  static ChatDto parseChat(FullChatView chatView) {
    return ChatDto(
      id: chatView.id.toString(),
      name: chatView.name,
      authorId: chatView.authorId,
      memberId: chatView.memberId,
      messages: [
        ...chatView.messages.map((messageView) => parseMessage(messageView))
      ],
    );
  }

  static MessageDto parseMessage(MessageView messageView) {
    return MessageDto(
      id: messageView.id.toString(),
      authorId: messageView.authorId,
      body: messageView.body,
    );
  }
}
