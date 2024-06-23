import 'dart:async';
import 'dart:developer';

import 'package:auth/data/db.dart';
import 'package:auth/domain/auth_rpc.dart';
import 'package:grpc/grpc.dart';

Future<void> startServer() async {
  runZonedGuarded(() async {
    final authServer = Server.create(
      services: [AuthRpc()],
      interceptors: [],
      codecRegistry: CodecRegistry(
        codecs: [GzipCodec()],
      ),
    );
    await authServer.serve(port: 4400);
    log('Auth server listen porn ${authServer.port}');
    db = initDatabase();
    db.debugPrint = true;
    db.open();
  }, (error, stackTrace) {
    log(
      'Error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}
