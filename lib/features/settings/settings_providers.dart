import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/constants/app_constants.dart';
import 'package:os_project_finder/core/storage/local_storage.dart';

/// Everything the user can configure, persisted to Hive.
@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark, // dark by default, per the design brief
    this.geminiApiKey = '',
    this.geminiModel = AppConstants.defaultGeminiModel,
    this.githubToken = '',
  });

  final ThemeMode themeMode;
  final String geminiApiKey;
  final String geminiModel;
  final String githubToken;

  bool get hasGeminiKey => geminiApiKey.trim().isNotEmpty;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? geminiApiKey,
    String? geminiModel,
    String? githubToken,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        geminiApiKey: geminiApiKey ?? this.geminiApiKey,
        geminiModel: geminiModel ?? this.geminiModel,
        githubToken: githubToken ?? this.githubToken,
      );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  static const _key = 'settings';

  @override
  SettingsState build() {
    final json = LocalStorage.getJson(LocalStorage.settingsBox, _key);
    if (json == null) return const SettingsState();
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      geminiApiKey: json['geminiApiKey'] as String? ?? '',
      geminiModel:
          json['geminiModel'] as String? ?? AppConstants.defaultGeminiModel,
      githubToken: json['githubToken'] as String? ?? '',
    );
  }

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));
  void setGeminiApiKey(String key) =>
      _update(state.copyWith(geminiApiKey: key.trim()));
  void setGeminiModel(String model) =>
      _update(state.copyWith(geminiModel: model));
  void setGithubToken(String token) =>
      _update(state.copyWith(githubToken: token.trim()));

  void _update(SettingsState next) {
    state = next;
    LocalStorage.putJson(LocalStorage.settingsBox, _key, {
      'themeMode': next.themeMode.name,
      'geminiApiKey': next.geminiApiKey,
      'geminiModel': next.geminiModel,
      'githubToken': next.githubToken,
    });
  }
}
