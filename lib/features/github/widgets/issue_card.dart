import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/router/app_router.dart';
import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/core/utils/launcher.dart';
import 'package:forgeos/core/widgets/hover_effect.dart';
import 'package:forgeos/core/widgets/language_dot.dart';
import 'package:forgeos/features/ai/presentation/ai_assistant_sheet.dart';
import 'package:forgeos/features/bookmarks/bookmarks_providers.dart';
import 'package:forgeos/features/github/domain/models/contribution.dart';
import 'package:forgeos/features/github/domain/models/issue.dart';

/// Issue card with label chips, bookmark, AI-explain, and status tracking.
class IssueCard extends ConsumerWidget {
  const IssueCard({super.key, required this.issue, this.showRepo = true});

  final Issue issue;
  final bool showRepo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarked = ref.watch(issueBookmarksProvider
        .select((list) => list.any((i) => i.id == issue.id)));
    final status = ref.watch(contributionsProvider.select(
      (list) => list
          .where((c) => c.issue.id == issue.id)
          .map((c) => c.status)
          .firstOrNull,
    ));

    return HoverEffect(
      onTap: () => openUrl(context, issue.htmlUrl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.adjust,
                    size: 18,
                    color: issue.isOpen
                        ? const Color(0xFF4CAF7D)
                        : theme.colorScheme.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showRepo && issue.repoFullName.isNotEmpty)
                        InkWell(
                          onTap: () =>
                              context.openRepoByFullName(issue.repoFullName),
                          child: Text(
                            issue.repoFullName,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary),
                          ),
                        ),
                      Text(
                        issue.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _IssueMenu(issue: issue, status: status),
              ],
            ),
            if (issue.labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in issue.labels.take(4))
                    _LabelChip(label: label),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                StatChip(
                    icon: Icons.mode_comment_outlined,
                    label: '${issue.comments}'),
                const SizedBox(width: 14),
                StatChip(icon: Icons.schedule, label: timeAgo(issue.updatedAt)),
                const Spacer(),
                if (status != null)
                  _StatusBadge(status: status)
                else
                  IconButton(
                    tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark issue',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                      size: 19,
                      color:
                          bookmarked ? theme.colorScheme.secondary : null,
                    ),
                    onPressed: () => ref
                        .read(issueBookmarksProvider.notifier)
                        .toggle(issue),
                  ),
                IconButton(
                  tooltip: 'Explain with AI',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.auto_awesome,
                      size: 19, color: theme.colorScheme.secondary),
                  onPressed: () =>
                      AiAssistantSheet.forIssue(context, issue: issue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueMenu extends ConsumerWidget {
  const _IssueMenu({required this.issue, required this.status});

  final Issue issue;
  final ContributionStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributionsProvider.notifier);
    return PopupMenuButton<String>(
      tooltip: 'Track contribution',
      icon: const Icon(Icons.more_vert, size: 19),
      onSelected: (value) {
        switch (value) {
          case 'open':
            openUrl(context, issue.htmlUrl);
          case 'remove':
            notifier.remove(issue.id);
          default:
            final newStatus = ContributionStatus.values
                .firstWhere((s) => s.name == value);
            notifier.setStatus(issue, newStatus);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Marked as ${newStatus.label.toLowerCase()}')));
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'open', child: Text('Open on GitHub')),
        const PopupMenuDivider(),
        for (final s in ContributionStatus.values)
          PopupMenuItem(
            value: s.name,
            child: Row(children: [
              Icon(
                status == s
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(s.label),
            ]),
          ),
        if (status != null)
          const PopupMenuItem(value: 'remove', child: Text('Stop tracking')),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ContributionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ContributionStatus.saved => Theme.of(context).colorScheme.outline,
      ContributionStatus.inProgress => Theme.of(context).colorScheme.secondary,
      ContributionStatus.completed => const Color(0xFF4CAF7D),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(status.label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});
  final IssueLabel label;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.tryParse('FF${label.color}', radix: 16) ??
        0xFF808080);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? Color.lerp(color, Colors.white, 0.35)
                  : Color.lerp(color, Colors.black, 0.45),
            ),
      ),
    );
  }
}
