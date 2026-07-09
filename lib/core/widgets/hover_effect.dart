import 'package:flutter/material.dart';

/// Wraps interactive cards with a subtle lift + border glow on hover.
///
/// Purely additive on desktop/web (mouse); on touch devices the hover state
/// simply never triggers, so the widget is safe everywhere.
class HoverEffect extends StatefulWidget {
  const HoverEffect({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.scale = 1.015,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(widget.borderRadius);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _hovered
                  ? scheme.secondary.withValues(alpha: 0.55)
                  : scheme.outlineVariant,
            ),
            color: scheme.surface,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
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
              borderRadius: radius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
