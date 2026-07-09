import 'package:flutter/material.dart';

import 'package:os_project_finder/core/constants/app_constants.dart';
import 'package:os_project_finder/core/utils/launcher.dart';
import 'package:os_project_finder/core/utils/responsive.dart';

/// About page: what the app is, the stack, and how to contribute.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: CenteredContent(
        child: ListView(
          padding: context.pagePadding.copyWith(top: 24, bottom: 32),
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.hub,
                      color: theme.colorScheme.secondary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConstants.appName,
                          style: theme.textTheme.titleLarge),
                      Text('Version ${AppConstants.appVersion} · MIT License',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Open Source Project Finder helps developers — especially '
              'first-time contributors — discover trending repositories, '
              'find beginner-friendly issues, and get AI guidance for making '
              'their first contribution.\n\n'
              'It is itself open source, free to use, and built entirely on '
              'free APIs: the GitHub REST & GraphQL APIs and the Gemini free '
              'tier. No paid services, no accounts, no tracking. All your '
              'data (bookmarks, history, keys) stays on your device.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Built with', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Flutter')),
                Chip(label: Text('Riverpod')),
                Chip(label: Text('GoRouter')),
                Chip(label: Text('Dio')),
                Chip(label: Text('Freezed')),
                Chip(label: Text('Hive')),
                Chip(label: Text('GitHub API')),
                Chip(label: Text('Gemini API')),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source code & contributing'),
                subtitle: const Text(
                    'Star the repo, report bugs, or open your first PR here!'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openUrl(context, AppConstants.repoUrl),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.balance),
                title: const Text('License'),
                subtitle: const Text(
                    'MIT — free to use, modify, and distribute.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
