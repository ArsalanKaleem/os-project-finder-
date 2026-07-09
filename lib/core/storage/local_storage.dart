import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper around Hive.
///
/// Every value is stored as a JSON string, so no type adapters (and no extra
/// codegen) are needed and the same code runs on web, mobile and desktop.
/// This is also what powers offline access: bookmarking a repository or an
/// issue persists its full JSON payload locally.
abstract final class LocalStorage {
  static const _boxNames = [
    settingsBox,
    repoBookmarksBox,
    issueBookmarksBox,
    contributionsBox,
    recentlyViewedBox,
    searchHistoryBox,
    readmeCacheBox,
  ];

  static const settingsBox = 'settings';
  static const repoBookmarksBox = 'repo_bookmarks';
  static const issueBookmarksBox = 'issue_bookmarks';
  static const contributionsBox = 'contributions';
  static const recentlyViewedBox = 'recently_viewed';
  static const searchHistoryBox = 'search_history';
  static const readmeCacheBox = 'readme_cache';

  static Future<void> init() async {
    await Hive.initFlutter('os_project_finder');
    for (final name in _boxNames) {
      await Hive.openBox<String>(name);
    }
  }

  static Box<String> box(String name) => Hive.box<String>(name);

  // ── JSON helpers ─────────────────────────────────────────────────────
  static void putJson(String boxName, String key, Map<String, dynamic> json) =>
      box(boxName).put(key, jsonEncode(json));

  static Map<String, dynamic>? getJson(String boxName, String key) {
    final raw = box(boxName).get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> allJson(String boxName) => box(boxName)
      .values
      .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
      .toList();

  static void putStringList(String boxName, String key, List<String> list) =>
      box(boxName).put(key, jsonEncode(list));

  static List<String> getStringList(String boxName, String key) {
    final raw = box(boxName).get(key);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> clear(String boxName) => box(boxName).clear();
}
