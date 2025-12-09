import 'package:expense_and_net_worth_automation/src/home/expenses_page.dart';
import 'package:expense_and_net_worth_automation/src/home/investment_page.dart';
import 'package:expense_and_net_worth_automation/src/home/net_worth_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:expense_and_net_worth_automation/src/home/vars_config/vars_config_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  static const routeName = '/';

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ExpensesPage(),
    NetWorthPage(),
    InvestmentPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, VarsConfigPage.routeName);
              setState(() {});
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Configure Variables',
          ),
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
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Net Worth',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Investment',
          ),
        ],
      ),
    );
  }
}
