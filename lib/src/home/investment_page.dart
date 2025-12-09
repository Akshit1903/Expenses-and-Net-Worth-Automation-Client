import 'package:flutter/material.dart';

class InvestmentPage extends StatelessWidget {
  const InvestmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Investment\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
