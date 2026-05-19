import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class UnprocessedTransactionsPage extends StatelessWidget {
  const UnprocessedTransactionsPage({super.key});

  static const String routeName = "/unprocessed-transactions";

  String _formatIndianCurrency(String amount) {
    final parsed = double.tryParse(amount);
    if (parsed == null) return amount;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return formatter.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final List<List<String>> unprocessedTransactions =
        (args is List<List<String>>) ? args : [];

    if (unprocessedTransactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unprocessed Transactions'),
        ),
        body: const Center(
          child: Text('No unprocessed transactions found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unprocessed Transactions'),
      ),
      body: ListView.builder(
        itemCount: unprocessedTransactions.length,
        itemBuilder: (context, index) {
          final unprocessedTransaction = unprocessedTransactions[index];

          // Guard against malformed data with fewer than expected fields
          if (unprocessedTransaction.length < 11) {
            return ListTile(
              title: Text('Malformed transaction at index $index'),
              subtitle: Text(unprocessedTransaction.join(', ')),
            );
          }

          final [
            issue,
            time,
            place,
            amount,
            drCr,
            account,
            expense,
            income,
            category,
            tags,
            note,
          ] = unprocessedTransaction;
          return ListTile(
              leading: CircleAvatar(
                backgroundColor: (expense == "Yes" || income == "Yes")
                    ? (drCr == "DR"
                        ? Colors.red.shade100
                        : Colors.green.shade100)
                    : Colors.transparent,
                child: Text(drCr,
                    style: TextStyle(
                      color: drCr == "DR" ? Colors.red : Colors.green,
                    )),
              ),
              title: Text("$category : $account"),
              subtitle: Text(issue),
              trailing: Text(
                _formatIndianCurrency(amount),
                style: const TextStyle(fontSize: 16),
              ),
              onTap: () => {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // Allows full-screen height if needed
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // Ensures it doesn't take full screen
                            children: [
                              Text(unprocessedTransaction.join("\n")),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Done"),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  });
        },
      ),
    );
  }
}
