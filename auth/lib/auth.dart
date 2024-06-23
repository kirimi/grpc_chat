import 'dart:async';
import 'dart:developer';

import 'package:auth/data/db.dart';
import 'package:auth/data/grpc_interceptors.dart';
import 'package:auth/domain/auth_rpc.dart';
import 'package:grpc/grpc.dart';

Future<void> startServer() async {
  runZonedGuarded(() async {
    final authServer = Server.create(
      services: [AuthRpc()],
      interceptors: [
        GrpcInterceptors.tokenInterceptor,
      ],
      codecRegistry: CodecRegistry(
        codecs: [GzipCodec()],
      ),
    );
    await authServer.serve(port: 4400);
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
