import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/router/app_router.dart';
import 'package:os_project_finder/core/theme/app_theme.dart';
import 'package:os_project_finder/features/settings/settings_providers.dart';

/// Root widget: wires the router and the (dark-by-default) Material 3 theme.
class OSProjectFinderApp extends ConsumerWidget {
  const OSProjectFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: 'Open Source Project Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
