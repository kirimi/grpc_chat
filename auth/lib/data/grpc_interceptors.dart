import 'dart:async';

import 'package:auth/data/db.dart';
import 'package:auth/env.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

const excludeMethods = ['SignUp', 'SignIn', 'Refreshtokens'];

abstract class GrpcInterceptors {
  static FutureOr<GrpcError?> tokenInterceptor(
    ServiceCall call,
    ServiceMethod method,
  ) {
    _checkDatabase();

    if (excludeMethods.contains(method.name)) {
      return null;
    }

    try {
      final token = call.clientMetadata?['access_token'] ?? '';
      final jwtClaim = verifyJwtHS256Signature(token, Env.sk);
      jwtClaim.validate();
      return null;
    } catch (_) {
      return GrpcError.unauthenticated();
    }
  }

  static void _checkDatabase() {
    if (!db.isOpen) {
      initDatabase();
    }
  }
}
