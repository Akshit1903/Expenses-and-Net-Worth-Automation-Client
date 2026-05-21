import 'package:expense_and_net_worth_automation/src/features/action/action_tab.dart';
import 'package:expense_and_net_worth_automation/src/features/journey/journey_tab.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main scaffold with 2-tab navigation: Action (left) and Journey (right).
///
/// The AppBar title reflects the current in-progress step when on the
/// Action tab, or "Finance" otherwise.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  static const routeName = '/';

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();

    // Dynamic AppBar title based on active tab and journey state
    String appBarTitle;
    if (_selectedIndex == 0) {
      // Action tab: show in-progress step title, or "Finance" if complete
      final inProgress = journeyProvider.inProgressStep;
      appBarTitle = inProgress?.title ?? 'Finance';
    } else {
      appBarTitle = 'Journey';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SettingsView.routeName);
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ActionTab(),
          JourneyTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.play_arrow_outlined),
            selectedIcon: Icon(Icons.play_arrow),
            label: 'Action',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Journey',
          ),
        ],
      ),
    );
  }
}
