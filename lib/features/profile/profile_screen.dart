import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/core/utils/launcher.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/core/widgets/skeletons.dart';
import 'package:forgeos/core/widgets/status_views.dart';
import 'package:forgeos/features/github/data/github_api.dart';
import 'package:forgeos/features/github/domain/models/github_user.dart';
import 'package:forgeos/features/github/domain/models/repo.dart';
import 'package:forgeos/features/github/widgets/repo_card.dart';

final _userProvider = FutureProvider.autoDispose.family<GithubUser, String>(
    (ref, login) => ref.read(githubApiProvider).getUser(login));

final _userReposProvider = FutureProvider.autoDispose
    .family<List<Repo>, String>(
        (ref, login) => ref.read(githubApiProvider).getUserRepositories(login));

/// Public GitHub profile viewer.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.login});
  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(_userProvider(login));
    final repos = ref.watch(_userReposProvider(login));

    return Scaffold(
      appBar: AppBar(title: Text(login)),
      body: CenteredContent(
        child: user.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(16), child: SkeletonCard(height: 200)),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(_userProvider(login)),
          ),
          data: (profile) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: context.pagePadding.copyWith(top: 16),
                sliver: SliverToBoxAdapter(child: _ProfileHeader(profile)),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding.horizontal / 2),
                sliver: const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Repositories')),
              ),
              SliverPadding(
                padding: context.pagePadding.copyWith(bottom: 32),
                sliver: repos.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: SkeletonGrid(count: 4)),
                  error: (e, _) => SliverToBoxAdapter(
                      child: Center(child: Text(e.toString()))),
                  data: (items) => items.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyView(
                              icon: Icons.folder_off_outlined,
                              title: 'No public repositories'))
                      : RepoSliverGrid(repos: items),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader(this.profile);
  final GithubUser profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name ?? profile.login,
                          style: theme.textTheme.titleLarge),
                      Text('@${profile.login}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open on GitHub',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => openUrl(context, profile.htmlUrl),
                ),
              ],
            ),
            if ((profile.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(profile.bio!),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Stat(Icons.people_outline,
                    '${compactNumber(profile.followers)} followers'),
                _Stat(Icons.person_add_alt,
                    '${compactNumber(profile.following)} following'),
                _Stat(Icons.folder_outlined,
                    '${compactNumber(profile.publicRepos)} repos'),
                if ((profile.location ?? '').isNotEmpty)
                  _Stat(Icons.place_outlined, profile.location!),
                if ((profile.company ?? '').isNotEmpty)
                  _Stat(Icons.business_outlined, profile.company!),
              ],
            ),
            if ((profile.blog ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  final blog = profile.blog!;
                  openUrl(context,
                      blog.startsWith('http') ? blog : 'https://$blog');
                },
                child: Text(
                  profile.blog!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
