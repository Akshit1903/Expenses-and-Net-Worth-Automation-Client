/// Represents the status of a journey step.
/// [stepStatus] from the API is the single source of truth.
enum StepStatus {
  completed,
  inProgress,
  pending;

  static StepStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return StepStatus.completed;
      case 'IN_PROGRESS':
        return StepStatus.inProgress;
      case 'PENDING':
        return StepStatus.pending;
      default:
        return StepStatus.pending;
    }
  }
}

/// A single step in the finance journey.
class JourneyStep {
  final String id;
  final String title;
  final StepStatus stepStatus;
  final Map<String, dynamic> context;

  const JourneyStep({
    required this.id,
    required this.title,
    required this.stepStatus,
    required this.context,
  });

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    return JourneyStep(
      id: json['id'] as String,
      title: json['title'] as String,
      stepStatus: StepStatus.fromString(json['stepStatus'] as String),
      context: json['context'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Represents the full journey state from GET /finance/journey.
class Journey {
  final List<JourneyStep> steps;
  final bool complete;

  const Journey({
    required this.steps,
    required this.complete,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List<dynamic>? ?? [];
    return Journey(
      steps: stepsJson
          .map((s) => JourneyStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      complete: json['complete'] as bool? ?? false,
    );
  }

  /// Returns the first step whose stepStatus is IN_PROGRESS.
  /// Only one step is guaranteed to be in-progress at a time.
  JourneyStep? get inProgressStep {
    try {
      return steps.firstWhere((s) => s.stepStatus == StepStatus.inProgress);
    } catch (_) {
      return null;
    }
  }
}
