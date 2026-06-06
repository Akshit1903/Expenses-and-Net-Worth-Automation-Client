import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transactions_view_model.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/transaction_form_page.dart';
import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/material.dart';

class ExternalTransactionsPage extends StatefulWidget {
  const ExternalTransactionsPage({super.key});

  static const routeName = '/external-transactions';

  @override
  State<ExternalTransactionsPage> createState() =>
      _ExternalTransactionsPageState();
}

class _ExternalTransactionsPageState extends State<ExternalTransactionsPage> {
  late final ExternalTransactionsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExternalTransactionsViewModel();
    _viewModel.loadTransactions();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _addOrEditTransaction(
      {Transaction? transaction, int? index}) async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          transaction: transaction,
          index: index,
        ),
      ),
    );

    if (result != null) {
      if (index != null) {
        await _viewModel.updateTransaction(index, result);
        if (mounted) {
          SnackbarService.showSnackBar('Transaction updated', context);
        }
      } else {
        await _viewModel.addTransaction(result);
        if (mounted) {
          SnackbarService.showSnackBar('Transaction added', context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('External Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from Server',
            onPressed: () async {
              try {
                await _viewModel.refreshFromApi();
                if (mounted) {
                  SnackbarService.showSnackBar(
                      'Refreshed from server successfully!', context);
                }
              } catch (e) {
                if (mounted) {
                  SnackbarService.showSnackBar('Refresh failed: $e', context);
                }
              }
            },
          )
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (_viewModel.error != null)
                MaterialBanner(
                  backgroundColor: theme.colorScheme.errorContainer,
                  content: Text(
                    _viewModel.error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _viewModel.loadTransactions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: _viewModel.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 64,
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _viewModel.refreshFromApi();
                                } catch (e) {
                                  if (mounted) {
                                    SnackbarService.showSnackBar(
                                        'Fetch failed: $e', context);
                                  }
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Fetch from Server'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _viewModel.transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _viewModel.transactions[index];
                          final isCr = tx.drcr == 'CR';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: _viewModel
                                    .getTransactionColor(tx)
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  isCr
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: _viewModel.getTransactionColor(tx),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.category,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '₹${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _viewModel.getTransactionColor(tx),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.account,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    if (tx.tags != null &&
                                        tx.tags!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        tx.tags!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.7),
                                onPressed: () async {
                                  await _viewModel.deleteTransaction(index);
                                  if (mounted) {
                                    SnackbarService.showSnackBar(
                                        'Transaction deleted', context);
                                  }
                                },
                              ),
                              onTap: () => _addOrEditTransaction(
                                  transaction: tx, index: index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTransaction(),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
