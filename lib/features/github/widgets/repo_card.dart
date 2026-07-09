import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/router/app_router.dart';
import 'package:os_project_finder/core/utils/formatters.dart';
import 'package:os_project_finder/core/widgets/hover_effect.dart';
import 'package:os_project_finder/core/widgets/language_dot.dart';
import 'package:os_project_finder/features/bookmarks/bookmarks_providers.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';

/// Repository card used in every grid/list across the app.
class RepoCard extends ConsumerWidget {
  const RepoCard({super.key, required this.repo, this.compact = false});

  final Repo repo;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarked = ref.watch(
      repoBookmarksProvider.select((list) => list.any((r) => r.id == repo.id)),
    );

    return HoverEffect(
      onTap: () => context.openRepo(repo),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundImage: repo.avatarUrl.isNotEmpty
                      ? NetworkImage(repo.avatarUrl)
                      : null,
                  child: const Icon(Icons.folder_outlined, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    repo.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    size: 20,
                    color: bookmarked ? theme.colorScheme.secondary : null,
                  ),
                  onPressed: () =>
                      ref.read(repoBookmarksProvider.notifier).toggle(repo),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                repo.description?.trim().isNotEmpty == true
                    ? repo.description!.trim()
                    : 'No description provided.',
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatChip(
                  icon: Icons.star_rounded,
                  label: compactNumber(repo.stars),
                  color: theme.colorScheme.secondary,
                ),
                StatChip(
                    icon: Icons.fork_right, label: compactNumber(repo.forks)),
                if (repo.language != null)
                  LanguageDot(language: repo.language!),
                if (!compact && repo.updatedAt != null)
                  StatChip(
                      icon: Icons.update, label: timeAgo(repo.updatedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive grid of [RepoCard]s (1 → 2 → 3 columns) as slivers.
class RepoSliverGrid extends StatelessWidget {
  const RepoSliverGrid({super.key, required this.repos});

  final List<Repo> repos;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 176,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: repos.length,
      itemBuilder: (_, i) => RepoCard(repo: repos[i]),
    );
  }
}
