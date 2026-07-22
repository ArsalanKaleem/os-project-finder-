import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeos/core/constants/app_constants.dart';
import 'package:forgeos/core/utils/formatters.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/core/widgets/skeletons.dart';
import 'package:forgeos/core/widgets/status_views.dart';
import 'package:forgeos/features/github/widgets/issue_card.dart';
import 'package:forgeos/features/issues/issues_providers.dart';

/// Beginner-friendly issue finder: filter by label, language and keyword,
/// with infinite scrolling.
class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  final _scrollController = ScrollController();
  final _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      final filter = ref.read(issueFilterProvider);
      ref.read(issueSearchProvider(filter).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(issueFilterProvider);
    final results = ref.watch(issueSearchProvider(filter));
    final notifier = ref.read(issueFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Find an issue')),
      body: CenteredContent(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _keywordController,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) =>
                notifier.state = filter.copyWith(keyword: v.trim()),
                decoration: InputDecoration(
                  hintText: 'Optional keyword, e.g. "dark mode" or "parser"',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filter.keyword.isNotEmpty
                      ? IconButton(
                    tooltip: 'Clear keyword',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _keywordController.clear();
                      notifier.state = filter.copyWith(keyword: '');
                    },
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final label in AppConstants.issueLabels)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label, softWrap: false, maxLines: 1),
                          selected: filter.labels.contains(label),
                          onSelected: (sel) {
                            final labels = [...filter.labels];
                            sel ? labels.add(label) : labels.remove(label);
                            // Always keep at least one label selected so the
                            // search stays focused on contributable issues.
                            if (labels.isEmpty) return;
                            notifier.state = filter.copyWith(labels: labels);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All languages', softWrap: false, maxLines: 1),
                        selected: filter.language == null,
                        onSelected: (_) => notifier.state =
                            filter.copyWith(clearLanguage: true),
                      ),
                    ),
                    for (final lang in AppConstants.languages)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(lang, softWrap: false, maxLines: 1),
                          selected: filter.language == lang,
                          onSelected: (sel) => notifier.state =
                              filter.copyWith(
                                  language: sel ? lang : null,
                                  clearLanguage: !sel),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.when(
                  loading: () => ListView.separated(
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const SkeletonCard(height: 140),
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(issueSearchProvider(filter)),
                  ),
                  data: (state) {
                    if (state.items.isEmpty) {
                      return const EmptyView(
                        icon: Icons.celebration_outlined,
                        title: 'No open issues matched',
                        subtitle:
                        'Try removing a label or switching language.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(issueSearchProvider(filter));
                        await ref.read(issueSearchProvider(filter).future);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.items.length + 2,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${compactNumber(state.totalCount)} open, '
                                    'unassigned issues',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            );
                          }
                          if (i == state.items.length + 1) {
                            return state.isLoadingMore
                                ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            )
                                : const SizedBox(height: 32);
                          }
                          return IssueCard(issue: state.items[i - 1]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}