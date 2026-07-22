import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/core/widgets/skeletons.dart';
import 'package:forgeos/core/widgets/status_views.dart';
import 'package:forgeos/features/explore/explore_providers.dart';
import 'package:forgeos/features/explore/history_providers.dart';
import 'package:forgeos/features/github/data/github_api.dart';
import 'package:forgeos/features/github/widgets/repo_card.dart';

/// Repository search: keyword + language/topic/stars/sort filters,
/// search history, and infinite scrolling.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery ?? '');
  final _scrollController = ScrollController();

  RepoSearchFilter _filter = const RepoSearchFilter();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialQuery ?? '').isNotEmpty) {
      _filter = RepoSearchFilter(query: widget.initialQuery!);
      _submitted = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_submitted) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(repoSearchProvider(_filter).notifier).loadMore();
    }
  }

  void _submit([String? query]) {
    final q = (query ?? _controller.text).trim();
    if (query != null) _controller.text = q;
    setState(() {
      _filter = _filter.copyWith(query: q);
      _submitted = !_filter.isEmpty;
    });
    if (q.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(q);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search projects')),
      body: CenteredContent(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText:
                      'Search repositories, e.g. "flutter charts" or "cli tool"',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _submit,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _FilterRow(
                filter: _filter,
                onChanged: (f) => setState(() {
                  _filter = f;
                  _submitted = !f.isEmpty;
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _submitted
                    ? _Results(
                        filter: _filter, scrollController: _scrollController)
                    : _HistoryView(onQueryTap: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final RepoSearchFilter filter;
  final ValueChanged<RepoSearchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _dropdownChip<String?>(
            context,
            icon: Icons.code,
            label: filter.language ?? 'Language',
            selected: filter.language != null,
            values: [null, ...AppConstants.languages],
            display: (v) => v ?? 'Any language',
            onSelected: (v) => onChanged(
                filter.copyWith(language: v, clearLanguage: v == null)),
          ),
          _dropdownChip<int?>(
            context,
            icon: Icons.star_outline,
            label: filter.minStars == null
                ? 'Stars'
                : '≥ ${compactNumber(filter.minStars!)} stars',
            selected: filter.minStars != null,
            values: const [null, 10, 100, 1000, 10000],
            display: (v) => v == null ? 'Any' : '≥ ${compactNumber(v)}',
            onSelected: (v) =>
                onChanged(filter.copyWith(minStars: v, clearMinStars: v == null)),
          ),
          _dropdownChip<RepoSort>(
            context,
            icon: Icons.sort,
            label: filter.sort.label,
            selected: filter.sort != RepoSort.bestMatch,
            values: RepoSort.values,
            display: (v) => v.label,
            onSelected: (v) => onChanged(filter.copyWith(sort: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              avatar: const Icon(Icons.tag, size: 16),
              label: Text(filter.topic ?? 'Topic'),
              selected: filter.topic != null,
              onPressed: () async {
                final topic = await _askTopic(context, filter.topic);
                if (topic != null) {
                  onChanged(filter.copyWith(
                      topic: topic.isEmpty ? null : topic,
                      clearTopic: topic.isEmpty));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownChip<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required List<T> values,
    required String Function(T) display,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<T>(
        tooltip: label,
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final v in values)
            PopupMenuItem<T>(value: v, child: Text(display(v))),
        ],
        child: Chip(
          avatar: Icon(icon,
              size: 16,
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : null),
          label: Text(label),
        ),
      ),
    );
  }

  Future<String?> _askTopic(BuildContext context, String? current) {
    final controller = TextEditingController(text: current ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by topic'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. machine-learning, game-engine'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.filter, required this.scrollController});

  final RepoSearchFilter filter;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(repoSearchProvider(filter));

    return results.when(
      loading: () => const SingleChildScrollView(child: SkeletonGrid()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(repoSearchProvider(filter)),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const EmptyView(
            icon: Icons.search_off,
            title: 'No repositories matched',
            subtitle: 'Try different keywords or remove a filter.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(repoSearchProvider(filter));
            await ref.read(repoSearchProvider(filter).future);
          },
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${compactNumber(state.totalCount)} repositories',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              RepoSliverGrid(repos: state.items),
              SliverToBoxAdapter(
                child: state.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox(height: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryView extends ConsumerWidget {
  const _HistoryView({required this.onQueryTap});
  final ValueChanged<String> onQueryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) {
      return const EmptyView(
        icon: Icons.manage_search,
        title: 'Search all of GitHub',
        subtitle:
            'Enter a keyword above, then narrow results by language, topic, '
            'stars, or sort order.',
      );
    }

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent searches',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).clear(),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final query in history)
              InputChip(
                avatar: const Icon(Icons.history, size: 16),
                label: Text(query),
                onPressed: () => onQueryTap(query),
                onDeleted: () =>
                    ref.read(searchHistoryProvider.notifier).remove(query),
              ),
          ],
        ),
      ],
    );
  }
}
