import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/features/settings/settings_providers.dart';

/// Dio instance for the GitHub REST API.
///
/// An optional personal access token (from Settings) is attached per-request,
/// which lifts the anonymous rate limit (60/h) to 5000/h. The app works fully
/// without one.
final githubDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.githubApiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': AppConstants.githubApiVersion,
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(settingsProvider).githubToken;
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});

/// Separate Dio instance for the Gemini API (different base URL / headers).
final geminiDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConstants.geminiApiBase,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));
});
