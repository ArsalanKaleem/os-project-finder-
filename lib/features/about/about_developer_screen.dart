import 'package:flutter/material.dart';

import 'package:forgeos/core/theme/app_theme.dart';
import 'package:forgeos/core/utils/launcher.dart';
import 'package:forgeos/core/utils/responsive.dart';
import 'package:forgeos/core/widgets/hover_effect.dart';

/// A single clickable social/contact link shown on the developer card.
class _SocialLink {
  const _SocialLink({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;
}

// ── Developer profile ──────────────────────────────────────────────────
// Edit these constants to personalize the screen.
const String _devName = 'Arsalan Kaleem';
const String _devHandle = 'Somi';
const String _devRole = 'Flutter Developer · Firebase · AI Integrations';
const String _devAvatarUrl = 'https://github.com/identicons/somi.png';
const String _devBio =
    'I build cross-platform apps with Flutter — mobile, desktop and web — '
    'with a focus on clean architecture, real-time systems, and weaving AI '
    'into everyday tools. ForgeOS is one of the ways I like to give back to '
    'the open-source community that taught me most of what I know.';

const _socialLinks = <_SocialLink>[
  _SocialLink(
    label: 'GitHub',
    icon: Icons.code_rounded,
    url: 'https://github.com/your-username',
  ),
  _SocialLink(
    label: 'LinkedIn',
    icon: Icons.work_rounded,
    url: 'https://linkedin.com/in/your-username',
  ),
  _SocialLink(
    label: 'Email',
    icon: Icons.mail_rounded,
    url: 'mailto:you@example.com',
  ),
  _SocialLink(
    label: 'Portfolio',
    icon: Icons.language_rounded,
    url: 'https://your-portfolio.example.com',
  ),
];

/// A polished "about the developer" page: circular avatar with a gradient
/// ring, name & role, a short bio, and a row of clickable social links.
class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About the Developer')),
      body: Stack(
        children: [
          // Soft ambient glow behind the header, purely decorative.
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.12),
                        scheme.secondary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CenteredContent(
              child: ListView(
                padding: context.pagePadding.copyWith(top: 12, bottom: 40),
                children: [
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _AvatarWithRing(imageUrl: _devAvatarUrl),
                        const SizedBox(height: 20),
                        Text(
                          _devName,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.secondary
                                .withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            '“$_devHandle”',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _devRole,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _devBio,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Connect',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _SocialLinksGrid(links: _socialLinks),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'Thanks for using ForgeOS — issues, stars and pull\n'
                      'requests are always welcome.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar wrapped in a soft gradient ring with a subtle glow,
/// falling back to an initials icon if the network image fails to load.
class _AvatarWithRing extends StatelessWidget {
  const _AvatarWithRing({required this.imageUrl});

  final String imageUrl;

  static const double _size = 132;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.secondary,
            AppColors.accentBright,
            scheme.secondary.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: scheme.secondary.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: Icon(Icons.person_rounded,
                  size: 56, color: scheme.secondary),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: scheme.secondary.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: scheme.secondary,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Responsive wrap of clickable, hoverable social link chips.
class _SocialLinksGrid extends StatelessWidget {
  const _SocialLinksGrid({required this.links});

  final List<_SocialLink> links;

  @override
  Widget build(BuildContext context) {
    final wide = !context.isMobile;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final link in links)
          SizedBox(
            width: wide ? (context.maxContentWidth - 12) / 2 : double.infinity,
            child: _SocialLinkTile(link: link),
          ),
      ],
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  const _SocialLinkTile({required this.link});

  final _SocialLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return HoverEffect(
      onTap: () => openUrl(context, link.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondary.withValues(alpha: 0.14),
              ),
              child: Icon(link.icon, color: scheme.secondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayUrl(link.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.north_east_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _displayUrl(String url) {
    if (url.startsWith('mailto:')) return url.substring('mailto:'.length);
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }
}
