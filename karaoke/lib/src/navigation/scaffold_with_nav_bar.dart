import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/navigation/routes.dart';
import 'package:karaoke/src/navigation/scaffold_with_nav_bar_destination.dart';

final class ScaffoldWithNavBar extends StatefulWidget {

  const ScaffoldWithNavBar({
    required this.child,
    super.key
  });
  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBar();
}

class _ScaffoldWithNavBar extends State<ScaffoldWithNavBar> {
  List<ScaffoldWithNavBarDestination> getTabs(BuildContext context) => [
    ScaffoldWithNavBarDestination(
        icon: const Icon(Icons.home),
        initialLocation: RouteNames.home,
        label: AppLocalizations.of(context)!.homePage_title
    ),
    ScaffoldWithNavBarDestination(
        icon: const Icon(Icons.person),
        initialLocation: RouteNames.account,
        label: AppLocalizations.of(context)!.accountPage_title
    ),
    //TODO: Add more tabs here
  ];

  // getter that computes the current index from the current location,
  // using the helper method below
  int get _currentIndex => _locationToTabIndex(GoRouterState.of(context).matchedLocation);

  int _locationToTabIndex(String location) {
    final index =
    getTabs(context).indexWhere((t) => location.startsWith(t.initialLocation));
    // if index not found (-1), return 0
    return index < 0 ? 0 : index;
  }

  // callback used to navigate to the desired tab
  void _onItemTapped(BuildContext context, int tabIndex) {
    if (tabIndex != _currentIndex) {
      // go to the initial location of the selected tab (by index)
      context.go(getTabs(context)[tabIndex].initialLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: getTabs(context),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index)
      ),
      body: widget.child,
    );
  }
}
