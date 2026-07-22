import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:forgeos/core/utils/responsive.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Home', Icons.explore_outlined, Icons.explore),
  _Destination('Search', Icons.search_outlined, Icons.search),
  _Destination('Issues', Icons.adjust_outlined, Icons.adjust),
  _Destination('Saved', Icons.bookmark_outline, Icons.bookmark),
  _Destination('Settings', Icons.settings_outlined, Icons.settings),
];

/// Responsive navigation shell:
///  * < 640 px  — Material 3 bottom [NavigationBar]
///  * ≥ 640 px  — [NavigationRail] (extended with labels on large screens)
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _goBranch(int index) => shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final useRail = !context.isMobile;
    final extended = context.screenWidth >= Breakpoints.large;

    if (!useRail) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _goBranch,
            extended: extended,
            minExtendedWidth: 200,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.hub,
                  color: Theme.of(context).colorScheme.secondary, size: 28),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
