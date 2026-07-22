/// App-wide constants. Keep magic values out of widgets and services.
abstract final class AppConstants {
  static const appName = 'ForgeOS';
  static const appTagline = 'Open Source Project Finder';
  static const appVersion = '1.0.0';
  static const repoUrl = 'https://github.com/your-username/forgeos';

  // ── GitHub ────────────────────────────────────────────────────────────
  static const githubApiBase = 'https://api.github.com';
  static const githubGraphqlUrl = 'https://api.github.com/graphql';
  static const githubApiVersion = '2022-11-28';
  static const pageSize = 30;

  /// Labels commonly used to mark newcomer-friendly issues.
  static const issueLabels = <String>[
    'good first issue',
    'help wanted',
    'documentation',
    'bug',
    'enhancement',
    'beginner friendly',
  ];

  /// Popular languages offered as quick filters.
  static const languages = <String>[
    'Dart', 'JavaScript', 'TypeScript', 'Python', 'Go', 'Rust', 'Java',
    'Kotlin', 'Swift', 'C', 'C++', 'C#', 'Ruby', 'PHP', 'Elixir', 'Haskell',
  ];

  // ── Gemini ────────────────────────────────────────────────────────────
  static const geminiApiBase =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Models available on the Gemini free tier.
  static const geminiModels = <String>[
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];
  static const defaultGeminiModel = 'gemini-2.5-flash';

  // ── Local storage limits ─────────────────────────────────────────────
  static const maxSearchHistory = 15;
  static const maxRecentlyViewed = 20;
}