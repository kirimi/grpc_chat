import 'package:chats/env.dart';
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
}
