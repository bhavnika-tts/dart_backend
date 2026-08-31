/// Centralized AppError class for operational errors.
/// Exactly matches Node.js AppError behavior and serialization.
class AppError implements Exception {
  AppError(
    this.message, {
    this.statusCode = 500,
    this.code,
    this.isOperational = true,
  }) : status = '$statusCode'.startsWith('4') ? 'fail' : 'error';

  factory AppError.badRequest(String message, {String? code}) =>
      AppError(message, statusCode: 400, code: code);

  factory AppError.unauthorized(String message, {String? code}) =>
      AppError(message, statusCode: 401, code: code);

  factory AppError.forbidden(String message, {String? code}) =>
      AppError(message, statusCode: 403, code: code);

  factory AppError.notFound(String message, {String? code}) =>
      AppError(message, statusCode: 404, code: code);

  factory AppError.internal(String message, {String? code}) =>
      AppError(message, code: code);

  final String message;
  final int statusCode;
  final String status;
  final String? code;
  final bool isOperational;

  Map<String, dynamic> toJson({bool isDevelopment = false, dynamic error, StackTrace? stack}) {
    final map = <String, dynamic>{
      'status': status,
      'message': message,
    };
    if (code != null) {
      map['code'] = code;
    }
    if (isDevelopment) {
      if (error != null) map['error'] = error.toString();
      if (stack != null) map['stack'] = stack.toString();
    }
    return map;
  }

  @override
  String toString() => 'AppError(statusCode: $statusCode, message: $message, code: $code)';
}
