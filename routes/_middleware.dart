import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_backend/core/config/env.dart';
import 'package:dart_frog_backend/core/db/mongo_client.dart';
import 'package:dart_frog_backend/core/errors/app_error.dart';
import 'package:dart_frog_backend/core/redis/redis_client.dart';
import 'package:dart_frog_backend/core/security/crypto.dart';
import 'package:dart_frog_backend/core/security/jwt_service.dart';

/// Global Middleware pipeline:
/// 1. Universal unrestricted CORS
/// 2. Dependency Injection for core services
/// 3. Centralized error handling
Handler middleware(Handler handler) {
  return (context) async {
    final req = context.request;
    final origin = req.headers['origin'] ?? '*';

    // Universal CORS response headers
    final corsHeaders = <String, String>{
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Expose-Headers': '*',
    };

    // Fast-path for OPTIONS pre-flight requests
    if (req.method == HttpMethod.options) {
      return Response(
        headers: corsHeaders,
      );
    }

    try {
      // Execute inner handler pipeline with injected core services
      final response = await handler(
        context
            .provide<EnvConfig>(() => EnvConfig.instance)
            .provide<MongoClient>(() => MongoClient.instance)
            .provide<RedisService>(() => RedisService.instance)
            .provide<CryptoService>(() => CryptoService.instance)
            .provide<JwtService>(() => JwtService.instance),
      );

      // Add CORS headers to all outgoing responses
      return response.copyWith(
        headers: {
          ...response.headers,
          ...corsHeaders,
        },
      );
    } catch (error, stackTrace) {
      // Global Error Handler
      final env = EnvConfig.instance;
      final isDev = env.isDevelopment;

      if (error is AppError) {
        final body = error.toJson(
          isDevelopment: isDev,
          error: error,
          stack: stackTrace,
        );
        return Response.json(
          statusCode: error.statusCode,
          body: body,
          headers: corsHeaders,
        );
      }

      print('💥 UNHANDLED SERVER ERROR: $error');
      print(stackTrace);

      final errorBody = <String, dynamic>{
        'status': 'error',
        'message': isDev ? error.toString() : 'Something went wrong on the server.',
        if (isDev) 'stack': stackTrace.toString(),
      };

      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: errorBody,
        headers: corsHeaders,
      );
    }
  };
}
