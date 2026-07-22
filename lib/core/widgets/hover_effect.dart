import 'package:flutter/material.dart';

import 'package:forgeos/core/theme/app_theme.dart';

/// Wraps interactive cards with a refined lift, accent border, and glow on
/// hover.
///
/// Purely additive on desktop/web (mouse); on touch devices the hover state
/// never triggers, so the widget is safe everywhere. Also animates a pressed
/// state on tap for tactile feedback across platforms.
class HoverEffect extends StatefulWidget {
  const HoverEffect({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadii.card,
    this.scale = 1.012,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scale;

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

    final scale = _pressed ? 0.992 : (_hovered ? widget.scale : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
      widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: _hovered
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface,
                Color.alphaBlend(
                  scheme.secondary.withValues(alpha: isDark ? 0.05 : 0.03),
                  scheme.surface,
                ),
              ],
            )
                : null,
            color: _hovered ? null : scheme.surface,
            border: Border.all(
              color: _hovered
                  ? scheme.secondary.withValues(alpha: 0.6)
                  : scheme.outlineVariant,
              width: _hovered ? 1.4 : 1,
            ),
            boxShadow: _hovered
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: scheme.secondary
                    .withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 20,
                spreadRadius: -6,
                offset: const Offset(0, 4),
              ),
            ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              borderRadius: radius,
              splashColor: scheme.secondary.withValues(alpha: 0.08),
              highlightColor: scheme.secondary.withValues(alpha: 0.04),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}