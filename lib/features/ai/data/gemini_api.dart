import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/network/api_exception.dart';
import 'package:os_project_finder/core/network/dio_client.dart';
import 'package:os_project_finder/features/settings/settings_providers.dart';

final geminiApiProvider = Provider<GeminiApi>((ref) {
  return GeminiApi(
    ref.watch(geminiDioProvider),
    () => ref.read(settingsProvider),
  );
});

/// One turn of an AI conversation.
class AiMessage {
  const AiMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

/// Client for the Gemini `generateContent` REST endpoint (free tier).
///
/// The user supplies their own free API key from Google AI Studio via the
/// Settings page; the key never leaves the device except in requests to
/// Google's API.
class GeminiApi {
  GeminiApi(this._dio, this._settings);

  final Dio _dio;
  final SettingsState Function() _settings;

  /// Sends the whole conversation (Gemini is stateless) and returns the
  /// model's reply as markdown text.
  Future<String> generate(List<AiMessage> conversation) async {
    final settings = _settings();
    if (!settings.hasGeminiKey) {
      throw const ApiException(
          'Add your free Gemini API key in Settings to use AI features.');
    }

    try {
      final res = await _dio.post(
        '/models/${settings.geminiModel}:generateContent',
        queryParameters: {'key': settings.geminiApiKey},
        data: {
          'contents': [
            for (final m in conversation)
              {
                'role': m.isUser ? 'user' : 'model',
                'parts': [
                  {'text': m.text}
                ],
              },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1024,
          },
        },
      );

      final candidates = res.data?['candidates'] as List?;
      final parts =
          candidates?.firstOrNull?['content']?['parts'] as List?;
      final text = parts
          ?.map((p) => p['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n');

      if (text == null || text.isEmpty) {
        throw const ApiException(
            'Gemini returned an empty response. Please try again.');
      }
      return text;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw switch (status) {
        400 || 403 => const ApiException(
            'Gemini rejected the API key. Check it in Settings.'),
        429 => const ApiException(
            'Gemini free-tier rate limit reached. Wait a minute and retry.'),
        _ => ApiException.fromDio(e),
      };
    }
  }
}
