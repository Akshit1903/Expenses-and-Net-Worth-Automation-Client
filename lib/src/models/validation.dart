/// A single validation entry comparing two sources.
class Validation {
  final String name;
  final double valueA;
  final String sourceA;
  final double valueB;
  final String sourceB;
  final double tolerance;
  final bool passed;

  const Validation({
    required this.name,
    required this.valueA,
    required this.sourceA,
    required this.valueB,
    required this.sourceB,
    required this.tolerance,
    required this.passed,
  });

  factory Validation.fromJson(Map<String, dynamic> json) {
    return Validation(
      name: json['name'] as String? ?? '',
      valueA: (json['valueA'] as num?)?.toDouble() ?? 0.0,
      sourceA: json['sourceA'] as String? ?? '',
      valueB: (json['valueB'] as num?)?.toDouble() ?? 0.0,
      sourceB: json['sourceB'] as String? ?? '',
      tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
    );
  }
}

/// Wraps the list of validations with an overall success flag.
class ValidationResponse {
  final List<Validation> validations;
  final bool isSuccess;

  const ValidationResponse({
    required this.validations,
    required this.isSuccess,
  });

  factory ValidationResponse.fromJson(Map<String, dynamic> json) {
    final validationsJson = json['validations'] as List<dynamic>? ?? [];
    return ValidationResponse(
      validations: validationsJson
          .map((v) => Validation.fromJson(v as Map<String, dynamic>))
          .toList(),
      isSuccess: json['isSuccess'] as bool? ?? false,
    );
  }

  List<Validation> get failedValidations =>
      validations.where((v) => !v.passed).toList();

  List<Validation> get passedValidations =>
      validations.where((v) => v.passed).toList();
}
