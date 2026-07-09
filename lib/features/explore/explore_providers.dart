import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/features/github/data/github_api.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';

/// Filters for the Home (trending) page.
@immutable
class TrendingFilter {
  const TrendingFilter({this.period = TrendingPeriod.week, this.language});

  final TrendingPeriod period;
  final String? language;

  TrendingFilter copyWith({
    TrendingPeriod? period,
    String? language,
    bool clearLanguage = false,
  }) =>
      TrendingFilter(
        period: period ?? this.period,
        language: clearLanguage ? null : (language ?? this.language),
      );

  @override
  bool operator ==(Object other) =>
      other is TrendingFilter &&
      other.period == period &&
      other.language == language;

  @override
  int get hashCode => Object.hash(period, language);
}

final trendingFilterProvider =
    StateProvider<TrendingFilter>((ref) => const TrendingFilter());

/// Trending repositories, re-fetched whenever the filter changes.
final trendingReposProvider = FutureProvider.autoDispose<List<Repo>>((ref) {
  final filter = ref.watch(trendingFilterProvider);
  return ref.watch(githubApiProvider).trendingRepositories(
        period: filter.period,
        language: filter.language,
      );
});

/// "Active this week" strip on Home.
final recentlyUpdatedReposProvider =
    FutureProvider.autoDispose<List<Repo>>((ref) {
  final language = ref.watch(trendingFilterProvider).language;
  return ref
      .watch(githubApiProvider)
      .recentlyUpdatedRepositories(language: language);
});

/// Filters for the Search page.
@immutable
class RepoSearchFilter {
  const RepoSearchFilter({
    this.query = '',
    this.language,
    this.topic,
    this.minStars,
    this.sort = RepoSort.bestMatch,
  });

  final String query;
  final String? language;
  final String? topic;
  final int? minStars;
  final RepoSort sort;

  bool get isEmpty =>
      query.trim().isEmpty &&
      language == null &&
      topic == null &&
      minStars == null;

  RepoSearchFilter copyWith({
    String? query,
    String? language,
    String? topic,
    int? minStars,
    RepoSort? sort,
    bool clearLanguage = false,
    bool clearTopic = false,
    bool clearMinStars = false,
  }) =>
      RepoSearchFilter(
        query: query ?? this.query,
        language: clearLanguage ? null : (language ?? this.language),
        topic: clearTopic ? null : (topic ?? this.topic),
        minStars: clearMinStars ? null : (minStars ?? this.minStars),
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is RepoSearchFilter &&
      other.query == query &&
      other.language == language &&
      other.topic == topic &&
      other.minStars == minStars &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, language, topic, minStars, sort);
}

/// Accumulated pages of a paginated fetch.
@immutable
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.isLoadingMore = false,
    this.error,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => items.length < totalCount;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? totalCount,
    int? page,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) =>
      PaginatedState<T>(
        items: items ?? this.items,
        totalCount: totalCount ?? this.totalCount,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Repository search with infinite scrolling.
final repoSearchProvider = AsyncNotifierProvider.autoDispose.family<
    RepoSearchNotifier,
    PaginatedState<Repo>,
    RepoSearchFilter>(RepoSearchNotifier.new);

class RepoSearchNotifier extends AutoDisposeFamilyAsyncNotifier<
    PaginatedState<Repo>, RepoSearchFilter> {
  @override
  Future<PaginatedState<Repo>> build(RepoSearchFilter arg) async {
    final result = await ref.read(githubApiProvider).searchRepositories(
          query: arg.query,
          language: arg.language,
          topic: arg.topic,
          minStars: arg.minStars,
          sort: arg.sort,
        );
    return PaginatedState(items: result.items, totalCount: result.totalCount);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final result = await ref.read(githubApiProvider).searchRepositories(
            query: arg.query,
            language: arg.language,
            topic: arg.topic,
            minStars: arg.minStars,
            sort: arg.sort,
            page: current.page + 1,
          );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...result.items],
        totalCount: result.totalCount,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(
          current.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }
}
