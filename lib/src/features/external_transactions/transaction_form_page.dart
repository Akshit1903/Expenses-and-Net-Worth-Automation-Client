import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction? transaction;
  final int? index;

  const TransactionFormPage({
    super.key,
    this.transaction,
    this.index,
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _accountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;
  late bool _expense;
  late String _drcr;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController =
        TextEditingController(text: tx?.amount.toString() ?? '');
    _accountController = TextEditingController(text: tx?.account ?? '');
    _categoryController = TextEditingController(text: tx?.category ?? '');
    _tagsController = TextEditingController(text: tx?.tags ?? '');
    _expense = tx?.expense ?? true;
    _drcr = tx?.drcr ?? 'DR';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final transaction = Transaction(
      amount: amount,
      account: _accountController.text.trim(),
      category: _categoryController.text.trim(),
      tags: _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.trim(),
      expense: _expense,
      drcr: _drcr,
    );

    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (e.g. #Online)',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _drcr,
                        decoration: const InputDecoration(
                          labelText: 'Type (DR/CR)',
                          prefixIcon: Icon(Icons.swap_vert),
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'DR', child: Text('DR (Debit)')),
                          DropdownMenuItem(
                              value: 'CR', child: Text('CR (Credit)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _drcr = value;
                              // If CR, it is usually income (not expense), if DR it is usually expense
                              _expense = (value == 'DR');
                            });
                          }
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Is Expense?'),
                        value: _expense,
                        onChanged: (bool value) {
                          setState(() {
                            _expense = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Add Transaction'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
