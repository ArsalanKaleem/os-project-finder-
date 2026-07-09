import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/constants/app_constants.dart';
import 'package:os_project_finder/core/storage/local_storage.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';

/// Recent search queries (newest first, de-duplicated, capped).
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'queries';

  @override
  List<String> build() =>
      LocalStorage.getStringList(LocalStorage.searchHistoryBox, _key);

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ...state.where((e) => e.toLowerCase() != q.toLowerCase())]
        .take(AppConstants.maxSearchHistory)
        .toList();
    _save(next);
  }

  void remove(String query) => _save(state.where((e) => e != query).toList());
  void clear() => _save(const []);

  void _save(List<String> next) {
    state = next;
    LocalStorage.putStringList(LocalStorage.searchHistoryBox, _key, next);
  }
}

/// Repositories the user opened recently (newest first, capped).
final recentlyViewedProvider =
    NotifierProvider<RecentlyViewedNotifier, List<Repo>>(
        RecentlyViewedNotifier.new);

class RecentlyViewedNotifier extends Notifier<List<Repo>> {
  static const _key = 'repos';

  @override
  List<Repo> build() {
    final json = LocalStorage.getJson(LocalStorage.recentlyViewedBox, _key);
    if (json == null) return const [];
    return (json['items'] as List)
        .map((e) => Repo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void add(Repo repo) {
    final next = [repo, ...state.where((r) => r.id != repo.id)]
        .take(AppConstants.maxRecentlyViewed)
        .toList();
    state = next;
    LocalStorage.putJson(LocalStorage.recentlyViewedBox, _key,
        {'items': next.map((r) => r.toJson()).toList()});
  }

  void clear() {
    state = const [];
    LocalStorage.clear(LocalStorage.recentlyViewedBox);
  }
}
