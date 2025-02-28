import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class UnprocessedTransactionsPage extends StatelessWidget {
  const UnprocessedTransactionsPage({super.key});

  static const String routeName = "/unprocessed-transactions";

  String _formatIndianCurrency(String amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return formatter.format(double.parse(amount));
  }

  @override
  Widget build(BuildContext context) {
    final _unprocessedTransactions =
        ModalRoute.of(context)?.settings.arguments as List<List<String>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unprocessed Transactions'),
      ),
      body: ListView.builder(
        itemCount: _unprocessedTransactions.length,
        itemBuilder: (context, index) {
          List<String> _unprocessedTransaction =
              _unprocessedTransactions[index];

          final [
            ISSUE,
            TIME,
            PLACE,
            AMOUNT,
            DRCR,
            ACCOUNT,
            EXPENSE,
            INCOME,
            CATEGORY,
            TAGS,
            NOTE
          ] = _unprocessedTransaction;
          return ListTile(
              leading: CircleAvatar(
                backgroundColor: (EXPENSE == "Yes" || INCOME == "Yes")
                    ? (DRCR == "DR"
                        ? Colors.red.shade100
                        : Colors.green.shade100)
                    : Colors.transparent,
                child: Text(DRCR,
                    style: TextStyle(
                      color: DRCR == "DR" ? Colors.red : Colors.green,
                    )),
              ),
              title: Text("$CATEGORY : $ACCOUNT"),
              subtitle: Text(ISSUE),
              trailing: Text(
                _formatIndianCurrency(AMOUNT),
                style: TextStyle(fontSize: 16),
              ),
              onTap: () => {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // Allows full-screen height if needed
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // Ensures it doesn't take full screen
                            children: [
                              Text(_unprocessedTransaction.join("\n")),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Done"),
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
