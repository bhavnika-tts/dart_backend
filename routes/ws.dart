import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';
import 'package:dart_frog_backend/services/socket_service.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

Future<Response> onRequest(RequestContext context) async {
  final handler = webSocketHandler(
    (channel, protocol) {
      final query = context.request.uri.queryParameters;
      var userId = query['userId'];

      final token = query['token'] ?? context.request.headers['authorization'];
      if (token != null && token.isNotEmpty) {
        final claims = JwtService.instance.verifyAuthHeader(token);
        if (claims != null) {
          userId = claims.userId;
        }
      }

      SocketService.instance.handleConnection(channel, userId: userId);
    },
  );

  return handler(context);
}
