import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/constants/app_constants.dart';
import 'package:os_project_finder/features/settings/settings_providers.dart';

final githubGraphqlProvider = Provider<GithubGraphql>((ref) {
  return GithubGraphql(
    Dio(),
    () => ref.read(settingsProvider).githubToken,
  );
});

/// Extra repository insights fetched in a single GraphQL round-trip.
class RepoInsights {
  const RepoInsights({
    required this.goodFirstIssueCount,
    required this.helpWantedCount,
    required this.totalContributions,
  });

  final int goodFirstIssueCount;
  final int helpWantedCount;
  final int totalContributions;
}

/// GitHub GraphQL API v4.
///
/// GraphQL requires authentication, so this client is used opportunistically:
/// when the user has added a token in Settings, detail pages are enriched
/// with beginner-friendly issue counts; without a token the app silently
/// falls back to REST-only data.
class GithubGraphql {
  GithubGraphql(this._dio, this._tokenProvider);

  final Dio _dio;
  final String Function() _tokenProvider;

  bool get isAvailable => _tokenProvider().isNotEmpty;

  Future<RepoInsights?> repoInsights(String owner, String name) async {
    final token = _tokenProvider();
    if (token.isEmpty) return null;

    const query = r'''
      query RepoInsights($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          goodFirst: issues(states: OPEN, labels: ["good first issue"]) {
            totalCount
          }
          helpWanted: issues(states: OPEN, labels: ["help wanted"]) {
            totalCount
          }
          defaultBranchRef {
            target {
              ... on Commit { history { totalCount } }
            }
          }
        }
      }
    ''';

    try {
      final res = await _dio.post(
        AppConstants.githubGraphqlUrl,
        data: {
          'query': query,
          'variables': {'owner': owner, 'name': name},
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final repo = res.data?['data']?['repository'];
      if (repo == null) return null;
      return RepoInsights(
        goodFirstIssueCount: repo['goodFirst']?['totalCount'] as int? ?? 0,
        helpWantedCount: repo['helpWanted']?['totalCount'] as int? ?? 0,
        totalContributions: repo['defaultBranchRef']?['target']?['history']
                ?['totalCount'] as int? ??
            0,
      );
    } catch (_) {
      // Insights are optional; never break the page over them.
      return null;
    }
  }
}
