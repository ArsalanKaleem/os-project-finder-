import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:os_project_finder/core/utils/formatters.dart';
import 'package:os_project_finder/core/utils/responsive.dart';
import 'package:os_project_finder/core/widgets/status_views.dart';
import 'package:os_project_finder/features/bookmarks/bookmarks_providers.dart';
import 'package:os_project_finder/features/github/domain/models/contribution.dart';
import 'package:os_project_finder/features/github/widgets/issue_card.dart';
import 'package:os_project_finder/features/github/widgets/repo_card.dart';

/// Saved tab: bookmarked repos, bookmarked issues, and tracked contributions.
/// Everything here is stored locally and available offline.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Repositories'),
            Tab(text: 'Issues'),
            Tab(text: 'Contributions'),
          ]),
        ),
        body: const CenteredContent(
          child: TabBarView(children: [
            _ReposTab(),
            _IssuesTab(),
            _ContributionsTab(),
          ]),
        ),
      ),
    );
  }
}

class _ReposTab extends ConsumerWidget {
  const _ReposTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(repoBookmarksProvider);

    if (repos.isEmpty) {
      return EmptyView(
        icon: Icons.bookmark_outline,
        title: 'No bookmarked repositories',
        subtitle: 'Bookmark a repository to keep it here — it will also be '
            'readable offline.',
        action: FilledButton.tonal(
          onPressed: () => context.go('/'),
          child: const Text('Browse trending'),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: context.pagePadding.copyWith(top: 16, bottom: 32),
          sliver: RepoSliverGrid(repos: repos),
        ),
      ],
    );
  }
}

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(issueBookmarksProvider);

    if (issues.isEmpty) {
      return EmptyView(
        icon: Icons.adjust,
        title: 'No bookmarked issues',
        subtitle: 'Save interesting issues from the Issues tab and come back '
            'to them anytime.',
        action: FilledButton.tonal(
          onPressed: () => context.go('/issues'),
          child: const Text('Find an issue'),
        ),
      );
    }

    return ListView.separated(
      padding: context.pagePadding.copyWith(top: 16, bottom: 32),
      itemCount: issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => IssueCard(issue: issues[i]),
    );
  }
}

class _ContributionsTab extends ConsumerWidget {
  const _ContributionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionsProvider);

    if (contributions.isEmpty) {
      return const EmptyView(
        icon: Icons.emoji_events_outlined,
        title: 'No tracked contributions yet',
        subtitle: 'Use the ⋮ menu on any issue to mark it as saved, '
            'in progress, or completed.',
      );
    }

    final completed = contributions
        .where((c) => c.status == ContributionStatus.completed)
        .length;

    return ListView(
      padding: context.pagePadding.copyWith(top: 16, bottom: 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$completed of ${contributions.length} tracked '
                    'contributions completed',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final status in [
          ContributionStatus.inProgress,
          ContributionStatus.saved,
          ContributionStatus.completed,
        ]) ...[
          if (contributions.any((c) => c.status == status)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(status.label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final c in contributions.where((c) => c.status == status))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IssueCard(issue: c.issue),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        'Updated ${timeAgo(c.updatedAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }
}
