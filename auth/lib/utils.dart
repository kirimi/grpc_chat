import 'dart:convert';

import 'package:auth/data/user/user.dart';
import 'package:auth/env.dart';
import 'package:auth/generated/auth.pbgrpc.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

abstract class Utils {
  static String getHashPassword(String password) {
    final bytes = utf8.encode(password + Env.sk);

    return sha256.convert(bytes).toString();
  }

  static String encrypt(String value) {
    final iv = IV.fromLength(16);
    final key = Key.fromUtf8(Env.dbSk);
    final encrypter = Encrypter(AES(key));
    return encrypter.encrypt(value, iv: iv).base64;
  }

  static String decrypt(String value) {
    final iv = IV.fromLength(16);
    final key = Key.fromUtf8(Env.dbSk);
    final encrypter = Encrypter(AES(key));

    return encrypter.decrypt64(value, iv: iv);
  }

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

  static UserDto convertUserDto(UserView user) => UserDto(
        id: user.id.toString(),
        username: user.username,
        email: decrypt(user.email),
      );
}
