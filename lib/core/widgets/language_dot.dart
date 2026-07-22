import 'package:flutter/material.dart';

import 'package:forgeos/core/utils/formatters.dart';

/// GitHub-style colored dot + language name, with a soft glow ring.
class LanguageDot extends StatelessWidget {
  const LanguageDot({super.key, required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    final color = Color(languageColor(language));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 5,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          language,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Icon + compact number, e.g. ★ 12.3K. Reads as a quiet metadata pill.
class StatChip extends StatelessWidget {
  const StatChip(
      {super.key, required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: tint),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}