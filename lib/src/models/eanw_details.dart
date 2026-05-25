import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';

/// A single financial section (e.g., income, recurring_expenses).
/// Contains a total and a split of named categories.
class EanwSection {
  final String total;
  final Map<String, String> split;

  const EanwSection({required this.total, required this.split});

  factory EanwSection.fromJson(Map<String, dynamic> json) {
    final splitRaw = json['split'] as Map<String, dynamic>? ?? {};
    final sortedMap = Map.fromEntries(splitRaw.entries.toList()
      ..sort((a, b) => double.parse(b.value).compareTo(double.parse(a.value))));
    return EanwSection(
      total: TransformUtils.formatMoneyString(json['total']?.toString() ?? '0',
          decimalDigits: 0),
      split: sortedMap.map((k, v) => MapEntry(
          k, TransformUtils.formatMoneyString(v.toString(), decimalDigits: 0))),
    );
  }
}

/// Full EANW financial details (working or main sheet).
class EanwDetails {
  final EanwSection recurringExpenses;
  final EanwSection oneTimeExpenses;
  final String totalExpenses;
  final EanwSection investment;
  final EanwSection income;
  final String growth;
  final EanwSection netWorth;

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
      income:
          EanwSection.fromJson(json['income'] as Map<String, dynamic>? ?? {}),
      recurringExpenses: EanwSection.fromJson(
          json['recurring_expenses'] as Map<String, dynamic>? ?? {}),
      netWorth: EanwSection.fromJson(
          json['net_worth'] as Map<String, dynamic>? ?? {}),
      oneTimeExpenses: EanwSection.fromJson(
          json['one_time_expenses'] as Map<String, dynamic>? ?? {}),
      investment: EanwSection.fromJson(
          json['investment'] as Map<String, dynamic>? ?? {}),
      growth: TransformUtils.formatMoneyString(
          json['growth']?.toString() ?? '0',
          decimalDigits: 0),
      totalExpenses: TransformUtils.formatMoneyString(
          json['total_expenses']?.toString() ?? '0',
          decimalDigits: 0),
    );
  }

  /// All sections as a list of (label, section) pairs for iteration.
  List<MapEntry<String, EanwSection>> get allSections => [
        MapEntry('Recurring Expenses', recurringExpenses),
        MapEntry('One-Time Expenses', oneTimeExpenses),
        MapEntry('Investment', investment),
        MapEntry('Income', income),
        MapEntry('Net Worth', netWorth),
      ];
}
