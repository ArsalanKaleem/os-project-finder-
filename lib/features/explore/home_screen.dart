import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/core/widgets/skeletons.dart';
import 'package:forgeos/core/widgets/status_views.dart';
import 'package:forgeos/features/explore/explore_providers.dart';
import 'package:forgeos/features/explore/history_providers.dart';
import 'package:forgeos/features/github/data/github_api.dart';
import 'package:forgeos/features/github/widgets/repo_card.dart';

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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branded hero panel.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    scheme.secondary.withValues(alpha: 0.14), scheme.surface),
                scheme.surface,
                Color.alphaBlend(
                    scheme.secondary.withValues(alpha: 0.05), scheme.surface),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 15, color: scheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'DISCOVER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Make your first\nopen source contribution',
                style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
              ),
              const SizedBox(height: 10),
              Text(
                'Trending projects and beginner-friendly issues, '
                    'with AI guidance from first look to first PR.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<TrendingPeriod>(
            segments: [
              for (final p in TrendingPeriod.values)
                ButtonSegment(
                  value: p,
                  label: Text(p.label, softWrap: false, maxLines: 1),
                ),
            ],
            selected: {filter.period},
            showSelectedIcon: false,
            onSelectionChanged: (set) =>
            notifier.state = filter.copyWith(period: set.first),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All languages',
                      softWrap: false, maxLines: 1),
                  selected: filter.language == null,
                  onSelected: (_) =>
                  notifier.state = filter.copyWith(clearLanguage: true),
                ),
              ),
              for (final lang in AppConstants.languages)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lang, softWrap: false, maxLines: 1),
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