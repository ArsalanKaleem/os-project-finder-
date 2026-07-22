import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:forgeos/core/utils/launcher.dart';

/// README renderer: GitHub-flavoured markdown with syntax-highlighted code
/// blocks and correctly resolved images (relative paths, `blob` links, and
/// `?raw=true` URLs all handled).
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.imageBaseUrl,
  });

  final String data;

  /// Base for relative image/link paths, e.g.
  /// `https://raw.githubusercontent.com/owner/repo/HEAD/`.
  final String? imageBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      onTapLink: (_, href, __) {
        if (href != null) openUrl(context, _resolveUrl(href));
      },
      // Resolve image URLs ourselves — flutter_markdown's imageDirectory does
      // not reliably prepend a *remote* base, which is why relative README
      // images (the common case) were not showing.
      imageBuilder: (uri, title, alt) => _MarkdownImage(
        rawUrl: uri.toString(),
        alt: alt,
        resolve: _resolveImageUrl,
      ),
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

  /// Resolve a link href against the repo base (for relative links).
  String _resolveUrl(String href) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    if (href.startsWith('#') || href.startsWith('mailto:')) return href;
    final base = imageBaseUrl;
    if (base == null) return href;
    return _join(base, href);
  }

  /// Resolve an image URL so it points at raw image bytes GitHub will serve.
  String _resolveImageUrl(String raw) {
    var url = raw.trim();

    // Protocol-relative URL (//host/path).
    if (url.startsWith('//')) return 'https:$url';

    // Absolute URL: normalise GitHub "blob" and "?raw=true" forms to raw host.
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // github.com/<owner>/<repo>/blob/<ref>/<path>  ->  raw.githubusercontent
      final blob = RegExp(
          r'^https?://github\.com/([^/]+)/([^/]+)/(?:blob|raw)/(.+)$');
      final m = blob.firstMatch(url);
      if (m != null) {
        return 'https://raw.githubusercontent.com/'
            '${m.group(1)}/${m.group(2)}/${m.group(3)}';
      }
      // Strip a trailing ?raw=true (raw host serves bytes already).
      url = url.replaceFirst(RegExp(r'\?raw=true$'), '');
      return url;
    }

    // Root-relative or relative path -> prepend the raw base.
    final base = imageBaseUrl;
    if (base == null) return url;
    return _join(base, url);
  }

  /// Join a base ending in `/` with a possibly `./` or `/`-prefixed path.
  static String _join(String base, String path) {
    var p = path;
    if (p.startsWith('./')) p = p.substring(2);
    if (p.startsWith('/')) p = p.substring(1);
    final b = base.endsWith('/') ? base : '$base/';
    return '$b$p';
  }
}

/// Network image with a loading placeholder and a graceful failure state so a
/// broken image never blocks the README.
class _MarkdownImage extends StatelessWidget {
  const _MarkdownImage({
    required this.rawUrl,
    required this.alt,
    required this.resolve,
  });

  final String rawUrl;
  final String? alt;
  final String Function(String) resolve;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = resolve(rawUrl);

    // SVGs can't be decoded by Image.network; show a tappable chip instead.
    if (url.toLowerCase().contains('.svg')) {
      return _Fallback(
        icon: Icons.image_outlined,
        label: alt?.isNotEmpty == true ? alt! : 'View image',
        onTap: () => openUrl(context, url),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, _, __) => _Fallback(
          icon: Icons.broken_image_outlined,
          label: alt?.isNotEmpty == true ? alt! : 'Image unavailable',
          onTap: () => openUrl(context, url),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.secondary)),
              ),
            ],
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