import 'dart:async';
import 'dart:developer';


import 'package:chats/data/db.dart';
import 'package:chats/data/grpc_interceptors.dart';
import 'package:chats/domain/chat_rpc.dart';
import 'package:chats/env.dart';
import 'package:grpc/grpc.dart';

Future<void> startServer() async {
  runZonedGuarded(() async {
    final authServer = Server.create(
      services: [ChatRpc(),],
      interceptors: [
        GrpcInterceptors.tokenInterceptor,
      ],
      codecRegistry: CodecRegistry(
        codecs: [GzipCodec()],
      ),
    );
    await authServer.serve(port: Env.port);
    log('Auth server listen porn ${authServer.port}');
    initDatabase();
  }, (error, stackTrace) {
    log(
      'Error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}
