import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:os_project_finder/core/utils/formatters.dart';
import 'package:os_project_finder/core/utils/launcher.dart';
import 'package:os_project_finder/core/utils/responsive.dart';
import 'package:os_project_finder/core/widgets/language_dot.dart';
import 'package:os_project_finder/core/widgets/skeletons.dart';
import 'package:os_project_finder/core/widgets/status_views.dart';
import 'package:os_project_finder/features/ai/presentation/ai_assistant_sheet.dart';
import 'package:os_project_finder/features/bookmarks/bookmarks_providers.dart';
import 'package:os_project_finder/features/explore/history_providers.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';
import 'package:os_project_finder/features/github/widgets/issue_card.dart';
import 'package:os_project_finder/features/issues/issues_providers.dart';
import 'package:os_project_finder/features/repo_details/markdown_view.dart';
import 'package:os_project_finder/features/repo_details/repo_details_providers.dart';

/// Full repository page: header + README / Issues / About tabs.
class RepoDetailsScreen extends ConsumerStatefulWidget {
  const RepoDetailsScreen({
    super.key,
    required this.owner,
    required this.name,
    this.initial,
  });

  final String owner;
  final String name;

  /// Repo passed via navigation `extra`, shown instantly while fresh data
  /// loads.
  final Repo? initial;

  @override
  ConsumerState<RepoDetailsScreen> createState() => _RepoDetailsScreenState();
}

class _RepoDetailsScreenState extends ConsumerState<RepoDetailsScreen> {
  RepoRef get _id => (owner: widget.owner, name: widget.name);
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repoDetailsProvider(_id));
    final repo = repoAsync.valueOrNull ?? widget.initial;

    // Record the visit once we have a full repo object.
    if (!_recorded && repo != null) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(recentlyViewedProvider.notifier).add(repo));
    }

    if (repo == null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.owner}/${widget.name}')),
        body: repoAsync.isLoading
            ? const Padding(
                padding: EdgeInsets.all(16), child: SkeletonCard(height: 220))
            : ErrorView(
                message: repoAsync.error.toString(),
                onRetry: () => ref.invalidate(repoDetailsProvider(_id)),
              ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(repo.name),
          actions: [
            _BookmarkAction(repo: repo),
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareLink(repo.fullName, repo.htmlUrl),
            ),
            IconButton(
              tooltip: 'Open on GitHub',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => openUrl(context, repo.htmlUrl),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'README'),
            Tab(text: 'Issues'),
            Tab(text: 'About'),
          ]),
        ),
        body: CenteredContent(
          child: Column(
            children: [
              _Header(repo: repo),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    _ReadmeTab(id: _id, repo: repo),
                    _IssuesTab(repo: repo),
                    _AboutTab(id: _id, repo: repo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkAction extends ConsumerWidget {
  const _BookmarkAction({required this.repo});
  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(
      repoBookmarksProvider.select((list) => list.any((r) => r.id == repo.id)),
    );
    return IconButton(
      tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark (available offline)',
      icon: Icon(
        bookmarked ? Icons.bookmark : Icons.bookmark_outline,
        color: bookmarked ? Theme.of(context).colorScheme.secondary : null,
      ),
      onPressed: () => ref.read(repoBookmarksProvider.notifier).toggle(repo),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.repo});
  final Repo repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundImage: repo.avatarUrl.isNotEmpty
                    ? NetworkImage(repo.avatarUrl)
                    : null,
                child: const Icon(Icons.folder_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.push('/user/${repo.ownerLogin}'),
                      child: Text(
                        repo.ownerLogin,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ),
                    Text(repo.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if ((repo.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(repo.description!.trim(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatChip(
                  icon: Icons.star_rounded,
                  label: compactNumber(repo.stars),
                  color: theme.colorScheme.secondary),
              StatChip(
                  icon: Icons.fork_right, label: compactNumber(repo.forks)),
              StatChip(
                  icon: Icons.adjust,
                  label: '${compactNumber(repo.openIssues)} issues'),
              if (repo.language != null) LanguageDot(language: repo.language!),
              if (repo.license?.spdxId != null &&
                  repo.license!.spdxId != 'NOASSERTION')
                StatChip(icon: Icons.balance, label: repo.license!.spdxId!),
              StatChip(icon: Icons.update, label: timeAgo(repo.updatedAt)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.route, size: 18),
                label: const Text('AI learning roadmap'),
                onPressed: () =>
                    AiAssistantSheet.forRepoRoadmap(context, repo: repo),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ReadmeTab extends ConsumerWidget {
  const _ReadmeTab({required this.id, required this.repo});

  final RepoRef id;
  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readme = ref.watch(readmeProvider(id));

    return readme.when(
      loading: () => const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          SkeletonBox(height: 20),
          SizedBox(height: 12),
          SkeletonBox(),
          SizedBox(height: 8),
          SkeletonBox(),
          SizedBox(height: 8),
          SkeletonBox(width: 240),
        ]),
      ),
      error: (e, _) => EmptyView(
        icon: Icons.description_outlined,
        title: 'README unavailable',
        subtitle: e.toString(),
      ),
      data: (markdown) => SingleChildScrollView(
        padding: context.pagePadding.copyWith(top: 16, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Summarize with AI'),
                onPressed: () => AiAssistantSheet.forReadmeSummary(context,
                    repo: repo, readme: markdown),
              ),
            ),
            const SizedBox(height: 16),
            MarkdownView(
              data: markdown,
              imageBaseUrl:
                  'https://raw.githubusercontent.com/${repo.fullName}/HEAD/',
            ),
          ],
        ),
      ),
    );
  }
}

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab({required this.repo});
  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(repoIssuesProvider(repo.fullName));

    return issues.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonCard(height: 130),
      ),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(repoIssuesProvider(repo.fullName)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyView(
            icon: Icons.adjust,
            title: 'No beginner-friendly issues right now',
            subtitle: 'Check all open issues on GitHub instead.',
            action: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open issues on GitHub'),
              onPressed: () =>
                  openUrl(context, '${repo.htmlUrl}/issues'),
            ),
          );
        }
        return ListView.separated(
          padding: context.pagePadding.copyWith(top: 16, bottom: 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => IssueCard(issue: items[i], showRepo: false),
        );
      },
    );
  }
}

class _AboutTab extends ConsumerWidget {
  const _AboutTab({required this.id, required this.repo});

  final RepoRef id;
  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final languages = ref.watch(languagesProvider(id));
    final contributors = ref.watch(contributorsProvider(id));
    final insights = ref.watch(repoInsightsProvider(id));

    return ListView(
      padding: context.pagePadding.copyWith(top: 16, bottom: 32),
      children: [
        if (repo.topics.isNotEmpty) ...[
          Text('Topics', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in repo.topics.take(16))
                Chip(label: Text(topic)),
            ],
          ),
          const SizedBox(height: 24),
        ],
        insights.maybeWhen(
          data: (data) => data == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contribution insights',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                            avatar: const Icon(Icons.flag, size: 16),
                            label: Text(
                                '${data.goodFirstIssueCount} good first issues')),
                        Chip(
                            avatar:
                                const Icon(Icons.handshake, size: 16),
                            label: Text(
                                '${data.helpWantedCount} help wanted')),
                        Chip(
                            avatar: const Icon(Icons.commit, size: 16),
                            label: Text(
                                '${compactNumber(data.totalContributions)} commits')),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        Text('Languages', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        languages.when(
          loading: () => const SkeletonBox(height: 12),
          error: (_, __) => const Text('Language data unavailable.'),
          data: (map) => _LanguageBar(languages: map),
        ),
        const SizedBox(height: 24),
        Text('Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _DetailRow(label: 'License', value: repo.license?.name ?? 'None'),
        _DetailRow(
            label: 'Created',
            value: repo.createdAt != null ? timeAgo(repo.createdAt) : '—'),
        _DetailRow(
            label: 'Default branch', value: repo.defaultBranch ?? 'main'),
        if ((repo.homepage ?? '').isNotEmpty)
          InkWell(
            onTap: () => openUrl(context, repo.homepage!),
            child: _DetailRow(
                label: 'Website', value: repo.homepage!, isLink: true),
          ),
        const SizedBox(height: 24),
        Text('Top contributors', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        contributors.when(
          loading: () => const SkeletonBox(height: 48),
          error: (_, __) => const Text('Contributor data unavailable.'),
          data: (people) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final person in people)
                Tooltip(
                  message:
                      '${person.login} · ${person.contributions ?? 0} commits',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push('/user/${person.login}'),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundImage: person.avatarUrl.isNotEmpty
                          ? NetworkImage(person.avatarUrl)
                          : null,
                      child: Text(person.login.characters.first
                          .toUpperCase()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({required this.languages});
  final Map<String, int> languages;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const Text('No language data.');
    final total = languages.values.fold<int>(0, (a, b) => a + b);
    final entries = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (final entry in entries)
                  Expanded(
                    flex: ((entry.value / total) * 1000).round().clamp(1, 1000),
                    child: Container(color: Color(languageColor(entry.key))),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final entry in entries.take(8))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LanguageDot(language: entry.key),
                  const SizedBox(width: 4),
                  Text(
                    '${(entry.value / total * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, this.isLink = false});

  final String label;
  final String value;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLink ? theme.colorScheme.secondary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
