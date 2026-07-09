import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/storage/local_storage.dart';
import 'package:os_project_finder/features/github/domain/models/contribution.dart';
import 'package:os_project_finder/features/github/domain/models/issue.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';

/// Bookmarked repositories.
///
/// The full JSON of each repo is persisted, so bookmarks double as an
/// offline cache: details pages can render from this data with no network.
final repoBookmarksProvider =
    NotifierProvider<RepoBookmarksNotifier, List<Repo>>(
        RepoBookmarksNotifier.new);

class RepoBookmarksNotifier extends Notifier<List<Repo>> {
  @override
  List<Repo> build() => LocalStorage.allJson(LocalStorage.repoBookmarksBox)
      .map(Repo.fromJson)
      .toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));

  bool isBookmarked(int id) => state.any((r) => r.id == id);

  void toggle(Repo repo) {
    final box = LocalStorage.repoBookmarksBox;
    if (isBookmarked(repo.id)) {
      LocalStorage.box(box).delete(repo.id.toString());
    } else {
      LocalStorage.putJson(box, repo.id.toString(), repo.toJson());
    }
    ref.invalidateSelf();
  }

  /// Offline fallback used by the details page.
  Repo? cached(String owner, String name) {
    final fullName = '$owner/$name'.toLowerCase();
    for (final repo in state) {
      if (repo.fullName.toLowerCase() == fullName) return repo;
    }
    return null;
  }
}

/// Bookmarked issues (same offline-caching approach).
final issueBookmarksProvider =
    NotifierProvider<IssueBookmarksNotifier, List<Issue>>(
        IssueBookmarksNotifier.new);

class IssueBookmarksNotifier extends Notifier<List<Issue>> {
  @override
  List<Issue> build() => LocalStorage.allJson(LocalStorage.issueBookmarksBox)
      .map(Issue.fromJson)
      .toList();

  bool isBookmarked(int id) => state.any((i) => i.id == id);

  void toggle(Issue issue) {
    final box = LocalStorage.issueBookmarksBox;
    if (isBookmarked(issue.id)) {
      LocalStorage.box(box).delete(issue.id.toString());
    } else {
      LocalStorage.putJson(box, issue.id.toString(), issue.toJson());
    }
    ref.invalidateSelf();
  }
}

/// Contribution tracker: issues the user saved to work on, with status.
final contributionsProvider =
    NotifierProvider<ContributionsNotifier, List<Contribution>>(
        ContributionsNotifier.new);

class ContributionsNotifier extends Notifier<List<Contribution>> {
  @override
  List<Contribution> build() =>
      LocalStorage.allJson(LocalStorage.contributionsBox)
          .map(Contribution.fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  ContributionStatus? statusOf(int issueId) {
    for (final c in state) {
      if (c.issue.id == issueId) return c.status;
    }
    return null;
  }

  void setStatus(Issue issue, ContributionStatus status) {
    final contribution = Contribution(
        issue: issue, status: status, updatedAt: DateTime.now());
    LocalStorage.putJson(LocalStorage.contributionsBox, issue.id.toString(),
        contribution.toJson());
    ref.invalidateSelf();
  }

  void remove(int issueId) {
    LocalStorage.box(LocalStorage.contributionsBox).delete(issueId.toString());
    ref.invalidateSelf();
  }

  int get completedCount =>
      state.where((c) => c.status == ContributionStatus.completed).length;
}
