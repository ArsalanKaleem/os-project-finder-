import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:os_project_finder/core/constants/app_constants.dart';
import 'package:os_project_finder/core/utils/responsive.dart';
import 'package:os_project_finder/core/widgets/skeletons.dart';
import 'package:os_project_finder/core/widgets/status_views.dart';
import 'package:os_project_finder/features/explore/explore_providers.dart';
import 'package:os_project_finder/features/explore/history_providers.dart';
import 'package:os_project_finder/features/github/data/github_api.dart';
import 'package:os_project_finder/features/github/widgets/repo_card.dart';

/// Home: trending repositories + recently active + recently viewed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingReposProvider);
    final recentlyUpdated = ref.watch(recentlyUpdatedReposProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);
    final filter = ref.watch(trendingFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: CenteredContent(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trendingReposProvider);
            ref.invalidate(recentlyUpdatedReposProvider);
            await ref.read(trendingReposProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: context.pagePadding,
                sliver: SliverToBoxAdapter(
                  child: _FilterBar(filter: filter),
                ),
              ),
              if (recentlyViewed.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.pagePadding.horizontal / 2),
                  sliver: const SliverToBoxAdapter(
                      child: SectionHeader(title: 'Recently viewed')),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.pagePadding.horizontal / 2),
                      itemCount: recentlyViewed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 320,
                        child:
                            RepoCard(repo: recentlyViewed[i], compact: true),
                      ),
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding.horizontal / 2),
                sliver: const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Trending repositories')),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding.horizontal / 2),
                sliver: trending.when(
                  data: (repos) => repos.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyView(
                            icon: Icons.travel_explore,
                            title: 'No trending repositories found',
                            subtitle:
                                'Try a longer period or a different language.',
                          ),
                        )
                      : RepoSliverGrid(repos: repos),
                  loading: () =>
                      const SliverToBoxAdapter(child: SkeletonGrid()),
                  error: (e, _) => SliverToBoxAdapter(
                    child: ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(trendingReposProvider),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding.horizontal / 2),
                sliver: const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Active this week')),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: recentlyUpdated.when(
                    data: (repos) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.pagePadding.horizontal / 2),
                      itemCount: repos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 320,
                        child: RepoCard(repo: repos[i], compact: true),
                      ),
                    ),
                    loading: () => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.pagePadding.horizontal / 2),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, __) => const SizedBox(
                          width: 320, child: SkeletonCard(height: 150)),
                    ),
                    error: (e, _) => Center(
                        child: Text(e.toString(),
                            textAlign: TextAlign.center)),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});
  final TrendingFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(trendingFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find your first open source contribution',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Trending projects and beginner-friendly issues, all in one place.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SegmentedButton<TrendingPeriod>(
              segments: [
                for (final p in TrendingPeriod.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {filter.period},
              showSelectedIcon: false,
              onSelectionChanged: (set) =>
                  notifier.state = filter.copyWith(period: set.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All languages'),
                  selected: filter.language == null,
                  onSelected: (_) =>
                      notifier.state = filter.copyWith(clearLanguage: true),
                ),
              ),
              for (final lang in AppConstants.languages)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lang),
                    selected: filter.language == lang,
                    onSelected: (sel) => notifier.state = filter.copyWith(
                        language: sel ? lang : null,
                        clearLanguage: !sel),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
