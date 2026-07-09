import 'package:flutter/material.dart';

import 'package:os_project_finder/core/utils/formatters.dart';

/// GitHub-style colored dot + language name.
class LanguageDot extends StatelessWidget {
  const LanguageDot({super.key, required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Color(languageColor(language)),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(language, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Icon + compact number, e.g. ★ 12.3K.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 15, color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
