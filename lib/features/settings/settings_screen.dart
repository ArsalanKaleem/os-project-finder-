import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/core/storage/local_storage.dart';
import 'package:forgeos/core/utils/launcher.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/features/explore/history_providers.dart';
import 'package:forgeos/features/settings/settings_providers.dart';

/// Settings: theme, Gemini API key/model, GitHub token, data management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _geminiController;
  late final TextEditingController _tokenController;
  bool _obscureGemini = true;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _geminiController = TextEditingController(text: settings.geminiApiKey);
    _tokenController = TextEditingController(text: settings.githubToken);
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: CenteredContent(
        child: ListView(
          padding: context.pagePadding.copyWith(top: 16, bottom: 32),
          children: [
            // ── Appearance ─────────────────────────────────────────────
            Text('Appearance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System')),
              ],
              selected: {settings.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (set) => notifier.setThemeMode(set.first),
            ),
            const SizedBox(height: 28),

            // ── AI assistant ───────────────────────────────────────────
            Text('AI assistant (Gemini)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'AI features use Google\'s free Gemini API with your own key. '
              'The key is stored only on this device.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiController,
              obscureText: _obscureGemini,
              decoration: InputDecoration(
                labelText: 'Gemini API key',
                helperText: 'Free at aistudio.google.com → Get API key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureGemini
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureGemini = !_obscureGemini),
                ),
              ),
              onChanged: notifier.setGeminiApiKey,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: AppConstants.geminiModels.contains(settings.geminiModel)
                  ? settings.geminiModel
                  : AppConstants.defaultGeminiModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
              items: [
                for (final model in AppConstants.geminiModels)
                  DropdownMenuItem(value: model, child: Text(model)),
              ],
              onChanged: (model) {
                if (model != null) notifier.setGeminiModel(model);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Get a free Gemini key'),
                onPressed: () =>
                    openUrl(context, 'https://aistudio.google.com/apikey'),
              ),
            ),
            const SizedBox(height: 20),

            // ── GitHub ─────────────────────────────────────────────────
            Text('GitHub (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Without a token, GitHub allows about 60 requests per hour. '
              'A free personal access token (no scopes needed) raises this '
              'to 5000/h and unlocks extra contribution insights.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'Personal access token',
                helperText: 'github.com → Settings → Developer settings',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              onChanged: notifier.setGithubToken,
            ),
            const SizedBox(height: 28),

            // ── Data ───────────────────────────────────────────────────
            Text('Data', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('Clear search history'),
              onTap: () {
                ref.read(searchHistoryProvider.notifier).clear();
                _confirm(context, 'Search history cleared');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Clear recently viewed'),
              onTap: () {
                ref.read(recentlyViewedProvider.notifier).clear();
                _confirm(context, 'Recently viewed cleared');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cached),
              title: const Text('Clear offline README cache'),
              onTap: () async {
                await LocalStorage.clear(LocalStorage.readmeCacheBox);
                if (context.mounted) _confirm(context, 'README cache cleared');
              },
            ),
            const SizedBox(height: 20),

            // ── About ──────────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('About this app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
