/// A single financial section (e.g., income, recurring_expenses).
/// Contains a total and a split of named categories.
class EanwSection {
  final String total;
  final Map<String, String> split;

  const EanwSection({required this.total, required this.split});

  factory EanwSection.fromJson(Map<String, dynamic> json) {
    final splitRaw = json['split'] as Map<String, dynamic>? ?? {};
    return EanwSection(
      total: json['total']?.toString() ?? '0',
      split: splitRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

/// Full EANW financial details (working or main sheet).
class EanwDetails {
  final EanwSection income;
  final EanwSection recurringExpenses;
  final EanwSection netWorth;
  final EanwSection oneTimeExpenses;
  final EanwSection investment;
  final String growth;
  final String totalExpenses;

  const EanwDetails({
    required this.income,
    required this.recurringExpenses,
    required this.netWorth,
    required this.oneTimeExpenses,
    required this.investment,
    required this.growth,
    required this.totalExpenses,
  });

  factory EanwDetails.fromJson(Map<String, dynamic> json) {
    return EanwDetails(
      income: EanwSection.fromJson(
          json['income'] as Map<String, dynamic>? ?? {}),
      recurringExpenses: EanwSection.fromJson(
          json['recurring_expenses'] as Map<String, dynamic>? ?? {}),
      netWorth: EanwSection.fromJson(
          json['net_worth'] as Map<String, dynamic>? ?? {}),
      oneTimeExpenses: EanwSection.fromJson(
          json['one_time_expenses'] as Map<String, dynamic>? ?? {}),
      investment: EanwSection.fromJson(
          json['investment'] as Map<String, dynamic>? ?? {}),
      growth: json['growth']?.toString() ?? '0',
      totalExpenses: json['total_expenses']?.toString() ?? '0',
    );
  }

  /// All sections as a list of (label, section) pairs for iteration.
  List<MapEntry<String, EanwSection>> get allSections => [
        MapEntry('Income', income),
        MapEntry('Recurring Expenses', recurringExpenses),
        MapEntry('One-Time Expenses', oneTimeExpenses),
        MapEntry('Investment', investment),
        MapEntry('Net Worth', netWorth),
      ];
}
