import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/router/app_router.dart';
import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/core/widgets/hover_effect.dart';
import 'package:forgeos/core/widgets/language_dot.dart';
import 'package:forgeos/features/bookmarks/bookmarks_providers.dart';
import 'package:forgeos/features/github/domain/models/repo.dart';

/// Repository card used in every grid/list across the app.
class RepoCard extends ConsumerWidget {
  const RepoCard({super.key, required this.repo, this.compact = false});

  final Repo repo;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bookmarked = ref.watch(
      repoBookmarksProvider.select((list) => list.any((r) => r.id == repo.id)),
    );

    return HoverEffect(
      onTap: () => context.openRepo(repo),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with a subtle accent ring.
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.surfaceContainerHigh,
                    foregroundImage: repo.avatarUrl.isNotEmpty
                        ? NetworkImage(repo.avatarUrl)
                        : null,
                    child: Icon(Icons.folder_outlined,
                        size: 15, color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.ownerLogin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        repo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                  visualDensity: VisualDensity.compact,
                  isSelected: bookmarked,
                  icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    size: 20,
                    color: bookmarked ? scheme.secondary : null,
                  ),
                  onPressed: () =>
                      ref.read(repoBookmarksProvider.notifier).toggle(repo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                repo.description?.trim().isNotEmpty == true
                    ? repo.description!.trim()
                    : 'No description provided.',
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatChip(
                  icon: Icons.star_rounded,
                  label: compactNumber(repo.stars),
                  color: scheme.secondary,
                ),
                StatChip(
                    icon: Icons.call_split, label: compactNumber(repo.forks)),
                if (repo.language != null) LanguageDot(language: repo.language!),
                if (!compact && repo.updatedAt != null)
                  StatChip(icon: Icons.update, label: timeAgo(repo.updatedAt)),
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
        maxCrossAxisExtent: 440,
        mainAxisExtent: 186,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: repos.length,
      itemBuilder: (_, i) => RepoCard(repo: repos[i]),
    );
  }
}