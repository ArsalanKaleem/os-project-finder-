import 'package:intl/intl.dart';

/// Human-friendly number: 1234 -> 1.2K, 4500000 -> 4.5M.
String compactNumber(int value) => NumberFormat.compact().format(value);

/// Relative time: "3h ago", "2d ago", "5mo ago".
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

/// `yyyy-MM-dd`, the format GitHub search qualifiers expect.
String githubDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Deterministic color for a programming language dot.
int languageColor(String language) {
  const known = <String, int>{
    'Dart': 0xFF00B4AB, 'JavaScript': 0xFFF1E05A, 'TypeScript': 0xFF3178C6,
    'Python': 0xFF3572A5, 'Go': 0xFF00ADD8, 'Rust': 0xFFDEA584,
    'Java': 0xFFB07219, 'Kotlin': 0xFFA97BFF, 'Swift': 0xFFF05138,
    'C': 0xFF555555, 'C++': 0xFFF34B7D, 'C#': 0xFF178600,
    'Ruby': 0xFF701516, 'PHP': 0xFF4F5D95, 'HTML': 0xFFE34C26,
    'CSS': 0xFF563D7C, 'Shell': 0xFF89E051, 'Elixir': 0xFF6E4A7E,
    'Haskell': 0xFF5E5086, 'Vue': 0xFF41B883, 'Scala': 0xFFC22D40,
  };
  if (known.containsKey(language)) return known[language]!;
  // Stable pseudo-random hue for anything else.
  final hue = language.codeUnits.fold<int>(0, (a, b) => (a + b * 31) % 360);
  return 0xFF000000 | _hsl(hue.toDouble());
}

int _hsl(double h) {
  // Fixed s=0.55 l=0.6 HSL->RGB, packed as 0xRRGGBB.
  const s = 0.55, l = 0.6;
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;
  double r = 0, g = 0, b = 0;
  if (h < 60) { r = c; g = x; } else if (h < 120) { r = x; g = c; }
  else if (h < 180) { g = c; b = x; } else if (h < 240) { g = x; b = c; }
  else if (h < 300) { r = x; b = c; } else { r = c; b = x; }
  int ch(double v) => ((v + m).clamp(0, 1) * 255).round();
  return (ch(r) << 16) | (ch(g) << 8) | ch(b);
}
