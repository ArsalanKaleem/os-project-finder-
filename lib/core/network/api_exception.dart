import 'package:dio/dio.dart';

/// Uniform, user-presentable failure type for every remote call.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 403 || statusCode == 429;

  /// Translate low-level Dio failures into something users can act on.
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
            'The request timed out. Check your connection and try again.');
      case DioExceptionType.connectionError:
        return const ApiException(
            'No internet connection. Bookmarked items are still available offline.');
      case DioExceptionType.badResponse:
        return switch (status) {
          401 => const ApiException(
              'Authentication failed. Check the token in Settings.',
              statusCode: 401),
          403 || 429 => const ApiException(
              'GitHub rate limit reached. Add a personal access token in '
              'Settings to raise the limit, or try again in a minute.',
              statusCode: 403),
          404 =>
            const ApiException('Not found on GitHub.', statusCode: 404),
          422 => const ApiException(
              'GitHub could not process this search query.',
              statusCode: 422),
          _ => ApiException('Server error ($status). Please try again.',
              statusCode: status),
        };
      default:
        return const ApiException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}
