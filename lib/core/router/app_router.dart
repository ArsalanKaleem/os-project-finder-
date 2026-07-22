import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forgeos/core/router/adaptive_shell.dart';
import 'package:forgeos/features/about/about_developer_screen.dart';
import 'package:forgeos/features/about/about_screen.dart';
import 'package:forgeos/features/bookmarks/saved_screen.dart';
import 'package:forgeos/features/explore/home_screen.dart';
import 'package:forgeos/features/explore/search_screen.dart';
import 'package:forgeos/features/github/domain/models/repo.dart';
import 'package:forgeos/features/issues/issues_screen.dart';
import 'package:forgeos/features/profile/profile_screen.dart';
import 'package:forgeos/features/repo_details/repo_details_screen.dart';
import 'package:forgeos/features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration.
///
/// Five tabs live inside a [StatefulShellRoute] so each keeps its own
/// navigation stack; detail pages (repository, profile, about) are pushed on
/// the root navigator so they cover the navigation rail / bar.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdaptiveShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              builder: (_, state) =>
                  SearchScreen(initialQuery: state.uri.queryParameters['q']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/issues', builder: (_, __) => const IssuesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/repo/:owner/:name',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => RepoDetailsScreen(
          owner: state.pathParameters['owner']!,
          name: state.pathParameters['name']!,
          initial: state.extra is Repo ? state.extra as Repo : null,
        ),
      ),
      GoRoute(
        path: '/user/:login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ProfileScreen(login: state.pathParameters['login']!),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: '/about-developer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AboutDeveloperScreen(),
      ),
    ],
  );
});

/// Convenience for navigating to a repository's detail page.
extension RepoNavigation on BuildContext {
  void openRepo(Repo repo) =>
      push('/repo/${repo.ownerLogin}/${repo.name}', extra: repo);

  void openRepoByFullName(String fullName) {
    final parts = fullName.split('/');
    if (parts.length == 2) push('/repo/${parts[0]}/${parts[1]}');
  }
}
