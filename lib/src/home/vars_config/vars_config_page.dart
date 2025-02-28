import 'package:expense_and_net_worth_automation/src/home/vars_config/vars_config.dart';
import 'package:flutter/material.dart';

class VarsConfigPage extends StatelessWidget {
  VarsConfigPage({super.key});

  static const String routeName = "/vars-config";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vars Config',
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: VarsConfig(),
      ),
    );
  }
}
