import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';

class SnackbarHistory extends StatelessWidget {
  const SnackbarHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Snackbar History",
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: Utils.snackbarHistory,
                builder: (context, history, child) {
                  if (history.isEmpty) {
                    return Center(child: Text("No snackbars shown yet."));
                  }
                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final message = history[history.length - 1 - index];
                      return ListTile(
                        title: Text(message),
                        leading: Icon(Icons.info_outline),
                        dense: true,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
