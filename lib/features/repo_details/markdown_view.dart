import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:os_project_finder/core/utils/launcher.dart';

/// README renderer: GitHub-flavoured markdown with syntax-highlighted code
/// blocks and working relative image URLs.
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.imageBaseUrl,
  });

  final String data;

  /// Base for relative image paths, e.g.
  /// `https://raw.githubusercontent.com/owner/repo/HEAD/`.
  final String? imageBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: true,
      imageDirectory: imageBaseUrl,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      onTapLink: (_, href, __) {
        if (href != null) openUrl(context, href);
      },
      builders: {'code': _CodeBuilder(brightness: theme.brightness)},
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: theme.colorScheme.secondary, width: 3),
          ),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

/// Renders fenced code blocks with `flutter_highlight`; inline code falls
/// back to a subtly tinted span.
class _CodeBuilder extends MarkdownElementBuilder {
  _CodeBuilder({required this.brightness});
  final Brightness brightness;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    final classAttr = element.attributes['class'] ?? '';
    final isBlock = classAttr.startsWith('language-') || text.contains('\n');

    if (!isBlock) return null; // let flutter_markdown style inline code

    final language = classAttr.startsWith('language-')
        ? classAttr.substring('language-'.length)
        : 'plaintext';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          text.trimRight(),
          language: language,
          theme: brightness == Brightness.dark
              ? atomOneDarkTheme
              : atomOneLightTheme,
          padding: const EdgeInsets.all(14),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}
