import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:os_project_finder/core/utils/launcher.dart';
import 'package:os_project_finder/core/utils/responsive.dart';
import 'package:os_project_finder/features/ai/data/gemini_api.dart';
import 'package:os_project_finder/features/ai/domain/prompts.dart';
import 'package:os_project_finder/features/github/domain/models/issue.dart';
import 'package:os_project_finder/features/github/domain/models/repo.dart';
import 'package:os_project_finder/features/settings/settings_providers.dart';

/// What the assistant was opened for; determines quick actions and the
/// initial prompt.
enum _AiContext { issue, repo }

/// AI assistant panel (bottom sheet on mobile, dialog on desktop).
///
/// Runs an initial action (explain / hints / roadmap / summary), renders the
/// markdown reply, and then supports free-form follow-up questions — the
/// whole conversation is kept client-side and resent each turn, since the
/// Gemini API is stateless.
class AiAssistantSheet extends ConsumerStatefulWidget {
  const AiAssistantSheet._({
    required this.title,
    required this.initialPrompt,
    required this.contextType,
    this.issue,
    this.repo,
  });

  final String title;
  final String initialPrompt;
  final _AiContext contextType;
  final Issue? issue;
  final Repo? repo;

  /// Opens the assistant for an issue (default action: explain).
  static Future<void> forIssue(BuildContext context, {required Issue issue}) =>
      _show(
        context,
        AiAssistantSheet._(
          title: 'AI · Issue #${issue.number}',
          initialPrompt: Prompts.explainIssue(issue),
          contextType: _AiContext.issue,
          issue: issue,
        ),
      );

  /// Opens the assistant for a repository roadmap.
  static Future<void> forRepoRoadmap(BuildContext context,
          {required Repo repo}) =>
      _show(
        context,
        AiAssistantSheet._(
          title: 'AI · Learning roadmap',
          initialPrompt: Prompts.learningRoadmap(repo),
          contextType: _AiContext.repo,
          repo: repo,
        ),
      );

  /// Opens the assistant with a README summary.
  static Future<void> forReadmeSummary(BuildContext context,
          {required Repo repo, required String readme}) =>
      _show(
        context,
        AiAssistantSheet._(
          title: 'AI · README summary',
          initialPrompt: Prompts.summarizeReadme(repo, readme),
          contextType: _AiContext.repo,
          repo: repo,
        ),
      );

  static Future<void> _show(BuildContext context, AiAssistantSheet sheet) {
    if (context.isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: sheet,
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: sheet),
    );
  }

  @override
  ConsumerState<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends ConsumerState<AiAssistantSheet> {
  final _messages = <AiMessage>[];
  final _visible = <AiMessage>[]; // hides the long engineered first prompt
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = false;
  String? _error;
  String _lastAttempt = '';
  bool _lastVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(settingsProvider).hasGeminiKey) {
        _send(widget.initialPrompt, visibleAsUser: false);
      }
    });
  }

  Future<void> _send(String text, {bool visibleAsUser = true}) async {
    if (text.trim().isEmpty || _loading) return;
    _lastAttempt = text;
    _lastVisible = visibleAsUser;
    setState(() {
      _loading = true;
      _error = null;
      _messages.add(AiMessage(text: text, isUser: true));
      if (visibleAsUser) {
        _visible.add(AiMessage(text: text, isUser: true));
      }
    });
    _scrollToEnd();

    try {
      final reply = await ref.read(geminiApiProvider).generate(_messages);
      final message = AiMessage(text: reply, isUser: false);
      setState(() {
        _messages.add(message);
        _visible.add(message);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeLast(); // let the user retry the same turn
        if (visibleAsUser && _visible.isNotEmpty) _visible.removeLast();
        _error = e.toString();
        _loading = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey =
        ref.watch(settingsProvider.select((s) => s.hasGeminiKey));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child:
                    Text(widget.title, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: !hasKey
              ? _MissingKeyView(onOpenSettings: () {
                  Navigator.of(context).pop();
                  context.go('/settings');
                })
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final message in _visible)
                      _MessageBubble(message: message),
                    if (_loading) const _TypingIndicator(),
                    if (_error != null)
                      _ErrorBubble(
                        error: _error!,
                        onRetry: () => _send(
                          _lastAttempt.isEmpty
                              ? widget.initialPrompt
                              : _lastAttempt,
                          visibleAsUser: _lastVisible,
                        ),
                      ),
                  ],
                ),
        ),
        if (hasKey) ...[
          const Divider(height: 1),
          _QuickActions(
            contextType: widget.contextType,
            enabled: !_loading,
            onAction: (prompt) => _send(prompt, visibleAsUser: false),
            issue: widget.issue,
            repo: widget.repo,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: TextField(
              controller: _inputController,
              enabled: !_loading,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                _inputController.clear();
                _send(v);
              },
              decoration: InputDecoration(
                hintText: 'Ask a follow-up question…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _loading
                      ? null
                      : () {
                          final v = _inputController.text;
                          _inputController.clear();
                          _send(v);
                        },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.contextType,
    required this.enabled,
    required this.onAction,
    this.issue,
    this.repo,
  });

  final _AiContext contextType;
  final bool enabled;
  final ValueChanged<String> onAction;
  final Issue? issue;
  final Repo? repo;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, String)>[
      if (contextType == _AiContext.issue && issue != null) ...[
        ('Explain again', Prompts.explainIssue(issue!)),
        ('How do I approach it?', Prompts.implementationHints(issue!)),
      ],
      if (contextType == _AiContext.repo && repo != null)
        ('Learning roadmap', Prompts.learningRoadmap(repo!)),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final (label, prompt) in actions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.bolt, size: 16),
                label: Text(label),
                onPressed: enabled ? () => onAction(prompt) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.secondary.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isUser
            ? Text(message.text)
            : MarkdownBody(
                data: message.text,
                selectable: true,
                onTapLink: (_, href, __) {
                  if (href != null) openUrl(context, href);
                },
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Thinking…'),
          ],
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MissingKeyView extends StatelessWidget {
  const _MissingKeyView({required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_off,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('AI features need a Gemini API key',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Get a free key from Google AI Studio (aistudio.google.com) '
              'and paste it in Settings. It is stored only on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
