class Transaction {
  final double amount;
  final String account;
  final String category;
  final String? tags;
  final bool expense;
  final String drcr; // "DR" or "CR"

  Transaction({
    required this.amount,
    required this.account,
    required this.category,
    this.tags,
    required this.expense,
    required this.drcr,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      amount: (json['amount'] as num).toDouble(),
      account: json['account'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tags: json['tags'] as String?,
      expense: json['expense'] as bool? ?? false,
      drcr: json['drcr'] as String? ?? 'DR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'account': account,
      'category': category,
      'tags': tags,
      'expense': expense,
      'drcr': drcr,
    };
  }

  Map<String, dynamic> toAppsScriptFormat() {
    return {
      'amount': amount,
      'DRCR': drcr,
      'account': account,
      'expense': expense,
      'category': category,
      'tags': tags ?? '',
    };
  }
}
