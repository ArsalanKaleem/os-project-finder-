import 'package:flutter_test/flutter_test.dart';

import 'package:os_project_finder/core/utils/formatters.dart';

void main() {
  group('compactNumber', () {
    test('formats small numbers as-is', () {
      expect(compactNumber(999), '999');
    });
    test('formats thousands and millions compactly', () {
      expect(compactNumber(1200), '1.2K');
      expect(compactNumber(4500000), '4.5M');
    });
  });

  group('timeAgo', () {
    test('handles null', () => expect(timeAgo(null), ''));
    test('minutes', () {
      final t = DateTime.now().subtract(const Duration(minutes: 5));
      expect(timeAgo(t), '5m ago');
    });
    test('days', () {
      final t = DateTime.now().subtract(const Duration(days: 3));
      expect(timeAgo(t), '3d ago');
    });
  });

  group('githubDate', () {
    test('yyyy-MM-dd', () {
      expect(githubDate(DateTime(2026, 7, 9)), '2026-07-09');
    });
  });

  group('languageColor', () {
    test('known language returns its GitHub color', () {
      expect(languageColor('Dart'), 0xFF00B4AB);
    });
    test('unknown language is deterministic and opaque', () {
      final a = languageColor('SomeNewLang');
      expect(a, languageColor('SomeNewLang'));
      expect(a & 0xFF000000, 0xFF000000);
    });
  });
}
