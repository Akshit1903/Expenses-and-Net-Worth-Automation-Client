import 'package:flutter/material.dart';

class NetWorthPage extends StatelessWidget {
  const NetWorthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Net Worth\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
