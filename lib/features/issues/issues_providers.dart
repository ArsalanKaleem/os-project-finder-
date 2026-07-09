import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/features/explore/explore_providers.dart';
import 'package:os_project_finder/features/github/data/github_api.dart';
import 'package:os_project_finder/features/github/domain/models/issue.dart';

/// Filters for the beginner-friendly issue finder.
@immutable
class IssueFilter {
  const IssueFilter({
    this.labels = const ['good first issue'],
    this.language,
    this.keyword = '',
  });

  final List<String> labels;
  final String? language;
  final String keyword;

  IssueFilter copyWith({
    List<String>? labels,
    String? language,
    String? keyword,
    bool clearLanguage = false,
  }) =>
      IssueFilter(
        labels: labels ?? this.labels,
        language: clearLanguage ? null : (language ?? this.language),
        keyword: keyword ?? this.keyword,
      );

  @override
  bool operator ==(Object other) =>
      other is IssueFilter &&
      listEquals(other.labels, labels) &&
      other.language == language &&
      other.keyword == keyword;

  @override
  int get hashCode => Object.hash(Object.hashAll(labels), language, keyword);
}

final issueFilterProvider =
    StateProvider<IssueFilter>((ref) => const IssueFilter());

/// Global issue search with infinite scrolling.
final issueSearchProvider = AsyncNotifierProvider.autoDispose
    .family<IssueSearchNotifier, PaginatedState<Issue>, IssueFilter>(
        IssueSearchNotifier.new);

class IssueSearchNotifier
    extends AutoDisposeFamilyAsyncNotifier<PaginatedState<Issue>, IssueFilter> {
  @override
  Future<PaginatedState<Issue>> build(IssueFilter arg) async {
    final result = await ref.read(githubApiProvider).searchIssues(
          labels: arg.labels,
          language: arg.language,
          keyword: arg.keyword,
        );
    return PaginatedState(items: result.items, totalCount: result.totalCount);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final result = await ref.read(githubApiProvider).searchIssues(
            labels: arg.labels,
            language: arg.language,
            keyword: arg.keyword,
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

/// Beginner-friendly issues inside a single repository (details page tab).
final repoIssuesProvider = FutureProvider.autoDispose
    .family<List<Issue>, String>((ref, repoFullName) async {
  final result = await ref.read(githubApiProvider).searchIssues(
        labels: const ['good first issue'],
        repoFullName: repoFullName,
        noAssignee: false,
      );
  if (result.items.isNotEmpty) return result.items;
  // Fall back to "help wanted" when a project uses different labels.
  final fallback = await ref.read(githubApiProvider).searchIssues(
        labels: const ['help wanted'],
        repoFullName: repoFullName,
        noAssignee: false,
      );
  return fallback.items;
});
