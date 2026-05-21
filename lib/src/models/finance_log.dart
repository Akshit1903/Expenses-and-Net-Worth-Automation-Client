/// A group of metrics within a finance log period (e.g., "[M] Net Worth").
class FinanceLogGroup {
  final String name;
  final Map<String, String> metrics;

  const FinanceLogGroup({required this.name, required this.metrics});

  /// Returns metrics sorted by numeric value descending.
  /// Non-numeric values sort to the bottom.
  List<MapEntry<String, String>> get sortedMetrics {
    final entries = metrics.entries.toList();
    entries.sort((a, b) {
      final aVal = double.tryParse(a.value);
      final bVal = double.tryParse(b.value);
      // Both numeric → sort descending
      if (aVal != null && bVal != null) return bVal.compareTo(aVal);
      // Non-numeric values go to bottom
      if (aVal == null && bVal != null) return 1;
      if (aVal != null && bVal == null) return -1;
      return a.key.compareTo(b.key);
    });
    return entries;
  }
}

/// Finance log with period-based categories.
class FinanceLog {
  final List<FinanceLogGroup> month;
  final List<FinanceLogGroup> quarter;
  final List<FinanceLogGroup> year;

  const FinanceLog({
    required this.month,
    required this.quarter,
    required this.year,
  });

  factory FinanceLog.fromJson(Map<String, dynamic> json) {
    return FinanceLog(
      month: _parseGroups(json['month'] as Map<String, dynamic>? ?? {}),
      quarter: _parseGroups(json['quarter'] as Map<String, dynamic>? ?? {}),
      year: _parseGroups(json['year'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Parses a period map like { "[M] Net Worth": { "Coin": "123" } }
  /// into a list of FinanceLogGroup.
  static List<FinanceLogGroup> _parseGroups(Map<String, dynamic> periodJson) {
    return periodJson.entries.map((entry) {
      final metricsRaw = entry.value as Map<String, dynamic>? ?? {};
      return FinanceLogGroup(
        name: entry.key,
        metrics: metricsRaw.map((k, v) => MapEntry(k, v.toString())),
      );
    }).toList();
  }

  /// Whether all periods are empty.
  bool get isEmpty => month.isEmpty && quarter.isEmpty && year.isEmpty;
}
