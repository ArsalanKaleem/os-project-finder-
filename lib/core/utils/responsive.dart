import 'package:flutter/material.dart';

/// Single source of truth for breakpoints across the app.
abstract final class Breakpoints {
  static const double tablet = 640;
  static const double desktop = 1024;
  static const double large = 1440;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.tablet;
  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Pick a value per form factor, falling back to the next smaller one.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Horizontal page padding that scales with the viewport.
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0),
        vertical: 8,
      );

  /// Max content width so text and grids stay readable on ultra-wide screens.
  double get maxContentWidth => 1200;
}

/// Constrains and centers its child; used as the outer wrapper of pages.
class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.maxContentWidth),
        child: child,
      ),
    );
  }
}
