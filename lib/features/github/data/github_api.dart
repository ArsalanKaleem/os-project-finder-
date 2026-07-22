import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/core/network/api_exception.dart';
import 'package:forgeos/core/network/dio_client.dart';
import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/features/github/domain/models/github_user.dart';
import 'package:forgeos/features/github/domain/models/issue.dart';
import 'package:forgeos/features/github/domain/models/paged_result.dart';
import 'package:forgeos/features/github/domain/models/repo.dart';

final githubApiProvider =
    Provider<GithubApi>((ref) => GithubApi(ref.watch(githubDioProvider)));

/// How far back "trending" looks.
enum TrendingPeriod {
  day('Today', Duration(days: 1)),
  week('This week', Duration(days: 7)),
  month('This month', Duration(days: 30));

  const TrendingPeriod(this.label, this.duration);
  final String label;
  final Duration duration;
}

/// Sort options for repository search.
enum RepoSort {
  bestMatch('Best match', ''),
  stars('Most stars', 'stars'),
  updated('Recently updated', 'updated'),
  forks('Most forks', 'forks');

  const RepoSort(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

/// GitHub REST API v3 — the data source behind every remote repository /
/// issue / user query in the app.
class GithubApi {
  GithubApi(this._dio);
  final Dio _dio;

  // ── Repositories ─────────────────────────────────────────────────────

  /// Free-text + qualifier search over repositories.
  Future<PagedResult<Repo>> searchRepositories({
    String query = '',
    String? language,
    String? topic,
    int? minStars,
    RepoSort sort = RepoSort.bestMatch,
    int page = 1,
    int perPage = AppConstants.pageSize,
  }) async {
    final q = <String>[
      if (query.trim().isNotEmpty) query.trim(),
      if (language != null && language.isNotEmpty) 'language:"$language"',
      if (topic != null && topic.isNotEmpty) 'topic:$topic',
      if (minStars != null) 'stars:>=$minStars',
    ];
    if (q.isEmpty) q.add('stars:>1000');

    return _guard(() async {
      final res = await _dio.get('/search/repositories', queryParameters: {
        'q': q.join(' '),
        if (sort.apiValue.isNotEmpty) 'sort': sort.apiValue,
        'order': 'desc',
        'page': page,
        'per_page': perPage,
      });
      return _pagedRepos(res.data as Map<String, dynamic>);
    });
  }

  /// Approximation of GitHub trending: repos created within [period] with
  /// the most stars (the trending page itself has no public API).
  Future<List<Repo>> trendingRepositories({
    TrendingPeriod period = TrendingPeriod.week,
    String? language,
  }) async {
    final since = githubDate(DateTime.now().subtract(period.duration));
    final result = await searchRepositories(
      query: 'created:>$since stars:>10',
      language: language,
      sort: RepoSort.stars,
    );
    return result.items;
  }

  /// Active projects: pushed recently, reasonably popular.
  Future<List<Repo>> recentlyUpdatedRepositories({String? language}) async {
    final since =
        githubDate(DateTime.now().subtract(const Duration(days: 7)));
    final result = await searchRepositories(
      query: 'pushed:>$since stars:>200',
      language: language,
      sort: RepoSort.updated,
      perPage: 12,
    );
    return result.items;
  }

  Future<Repo> getRepository(String owner, String name) => _guard(() async {
        final res = await _dio.get('/repos/$owner/$name');
        return Repo.fromJson(res.data as Map<String, dynamic>);
      });

  /// Raw README markdown; GitHub resolves the default branch itself.
  Future<String> getReadme(String owner, String name) => _guard(() async {
        final res = await _dio.get(
          '/repos/$owner/$name/readme',
          options: Options(
            headers: {'Accept': 'application/vnd.github.raw+json'},
            responseType: ResponseType.plain,
          ),
        );
        return res.data.toString();
      });

  Future<List<Owner>> getContributors(String owner, String name) =>
      _guard(() async {
        final res = await _dio.get(
          '/repos/$owner/$name/contributors',
          queryParameters: {'per_page': 24},
        );
        return (res.data as List)
            .map((e) => Owner.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// Language name → bytes of code.
  Future<Map<String, int>> getLanguages(String owner, String name) =>
      _guard(() async {
        final res = await _dio.get('/repos/$owner/$name/languages');
        return (res.data as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
      });

  // ── Issues ───────────────────────────────────────────────────────────

  /// Search open issues across GitHub (or within one repo).
  Future<PagedResult<Issue>> searchIssues({
    List<String> labels = const ['good first issue'],
    String? language,
    String? keyword,
    String? repoFullName,
    bool noAssignee = true,
    int page = 1,
    int perPage = AppConstants.pageSize,
  }) async {
    final q = <String>[
      'is:issue',
      'is:open',
      if (noAssignee) 'no:assignee',
      for (final label in labels) 'label:"$label"',
      if (language != null && language.isNotEmpty) 'language:"$language"',
      if (repoFullName != null) 'repo:$repoFullName',
      if (keyword != null && keyword.trim().isNotEmpty) keyword.trim(),
    ];

    return _guard(() async {
      final res = await _dio.get('/search/issues', queryParameters: {
        'q': q.join(' '),
        'sort': 'updated',
        'order': 'desc',
        'page': page,
        'per_page': perPage,
      });
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Issue.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult(
          items: items, totalCount: (data['total_count'] as int?) ?? 0);
    });
  }

  // ── Users ────────────────────────────────────────────────────────────

  Future<GithubUser> getUser(String login) => _guard(() async {
        final res = await _dio.get('/users/$login');
        return GithubUser.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<Repo>> getUserRepositories(String login) => _guard(() async {
        final res = await _dio.get('/users/$login/repos', queryParameters: {
          'sort': 'updated',
          'per_page': 30,
        });
        return (res.data as List)
            .map((e) => Repo.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  // ── Helpers ──────────────────────────────────────────────────────────

  PagedResult<Repo> _pagedRepos(Map<String, dynamic> data) {
    final items = (data['items'] as List)
        .map((e) => Repo.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResult(
        items: items, totalCount: (data['total_count'] as int?) ?? 0);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
