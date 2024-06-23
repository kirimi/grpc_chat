import 'package:auth/data/db.dart';
import 'package:auth/data/user/user.dart';
import 'package:auth/generated/auth.pbgrpc.dart';
import 'package:auth/utils.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:stormberry/stormberry.dart';

import '../env.dart';

class AuthRpc extends AuthRpcServiceBase {
  @override
  Future<ResponseDto> deleteUser(ServiceCall call, RequestDto request) async {
    final userId = Utils.getUserIdFromMetadata(call);

    final user = await db.users.queryUser(userId);
    if (user == null) {
      throw GrpcError.notFound('User not found');
    }

    await db.users.deleteOne(userId);

    return ResponseDto(message: 'success');
  }

  @override
  Future<UserDto> fetchUser(ServiceCall call, RequestDto request) async {
    final userId = Utils.getUserIdFromMetadata(call);

    final user = await db.users.queryUser(userId);
    if (user == null) {
      throw GrpcError.notFound('User not found');
    }

    return Utils.convertUserDto(user);
  }

  @override
  Future<TokensDto> refreshtokens(ServiceCall call, TokensDto request) async {
    if (request.refreshToken.isEmpty) {
      throw GrpcError.invalidArgument('Refresh token is empty');
    }

    final userId = Utils.getUserIdFromToken(request.refreshToken);
    final user = await db.users.queryUser(userId);

    if (user == null) {
      throw GrpcError.notFound('User not found');
    }

    return _createTokens(user.id.toString());
  }

  @override
  Future<TokensDto> signIn(ServiceCall call, UserDto request) async {
    if (request.email.isEmpty) {
      throw GrpcError.invalidArgument('Email is empty');
    }
    if (request.password.isEmpty) {
      throw GrpcError.invalidArgument('Password is empty');
    }

    final users = await db.users.queryUsers(
        QueryParams(where: "email='${Utils.encrypt(request.email)}'"));
    if (users.isEmpty) {
      throw GrpcError.notFound('User not found');
    }

    final user = users[0];
    final hashPassword = Utils.getHashPassword(request.password);
    if (hashPassword != user.password) {
      throw GrpcError.unauthenticated('Password wrong');
    }

    return _createTokens(user.id.toString());
  }

  @override
  Future<TokensDto> signUp(ServiceCall call, UserDto request) async {
    if (request.email.isEmpty) {
      throw GrpcError.invalidArgument('Email is empty');
    }
    if (request.username.isEmpty) {
      throw GrpcError.invalidArgument('Username is empty');
    }
    if (request.password.isEmpty) {
      throw GrpcError.invalidArgument('Password is empty');
    }

    final userId = await db.users.insertOne(
      UserInsertRequest(
        username: request.username,
        email: Utils.encrypt(request.email),
        password: Utils.getHashPassword(request.password),
      ),
    );

    return _createTokens(userId.toString());
  }

  @override
  Future<UserDto> updateUser(ServiceCall call, UserDto request) async {
    final userId = Utils.getUserIdFromMetadata(call);

    await db.users.updateOne(
      UserUpdateRequest(
        id: userId,
        username: request.username.isEmpty ? null : request.username,
        email: request.email.isEmpty ? null : Utils.encrypt(request.email),
        password: request.password.isEmpty
            ? null
            : Utils.getHashPassword(request.password),
      ),
    );

    final user = await db.users.queryUser(userId);
    if (user == null) {
      throw GrpcError.notFound('User not found');
    }

    return Utils.convertUserDto(user);
  }

  TokensDto _createTokens(String userId) {
    final accessTokenSet = JwtClaim(
        maxAge: Duration(hours: Env.accessTokenLife),
        otherClaims: {'user_id': userId});

    final refreshTokenSet = JwtClaim(
        maxAge: Duration(hours: Env.refreshTokenLife),
        otherClaims: {'user_id': userId});

    return TokensDto(
        accessToken: issueJwtHS256(accessTokenSet, Env.sk),
        refreshToken: issueJwtHS256(refreshTokenSet, Env.sk));
  }
}
