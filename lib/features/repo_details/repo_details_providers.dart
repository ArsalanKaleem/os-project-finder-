import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/storage/local_storage.dart';
import 'package:forgeos/features/bookmarks/bookmarks_providers.dart';
import 'package:forgeos/features/github/data/github_api.dart';
import 'package:forgeos/features/github/data/github_graphql.dart';
import 'package:forgeos/features/github/domain/models/repo.dart';

typedef RepoRef = ({String owner, String name});

/// Repository details with an offline fallback: if the network call fails
/// but the repo is bookmarked, the bookmarked JSON is served instead.
final repoDetailsProvider =
    FutureProvider.autoDispose.family<Repo, RepoRef>((ref, id) async {
  try {
    return await ref
        .read(githubApiProvider)
        .getRepository(id.owner, id.name);
  } catch (_) {
    final cached = ref
        .read(repoBookmarksProvider.notifier)
        .cached(id.owner, id.name);
    if (cached != null) return cached;
    rethrow;
  }
});

/// README markdown, cached locally so bookmarked repos read offline.
final readmeProvider =
    FutureProvider.autoDispose.family<String, RepoRef>((ref, id) async {
  final cacheKey = '${id.owner}/${id.name}'.toLowerCase();
  try {
    final readme =
        await ref.read(githubApiProvider).getReadme(id.owner, id.name);
    // Only persist for bookmarked repos to keep the cache small.
    final bookmarked = ref
            .read(repoBookmarksProvider.notifier)
            .cached(id.owner, id.name) !=
        null;
    if (bookmarked) {
      LocalStorage.box(LocalStorage.readmeCacheBox).put(cacheKey, readme);
    }
    return readme;
  } catch (_) {
    final cached = LocalStorage.box(LocalStorage.readmeCacheBox).get(cacheKey);
    if (cached != null) return cached;
    rethrow;
  }
});

final contributorsProvider =
    FutureProvider.autoDispose.family<List<Owner>, RepoRef>(
        (ref, id) => ref.read(githubApiProvider).getContributors(
              id.owner,
              id.name,
            ));

final languagesProvider =
    FutureProvider.autoDispose.family<Map<String, int>, RepoRef>(
        (ref, id) => ref.read(githubApiProvider).getLanguages(
              id.owner,
              id.name,
            ));

/// GraphQL enrichment; resolves to null without a GitHub token.
final repoInsightsProvider =
    FutureProvider.autoDispose.family<RepoInsights?, RepoRef>(
        (ref, id) => ref.read(githubGraphqlProvider).repoInsights(
              id.owner,
              id.name,
            ));
