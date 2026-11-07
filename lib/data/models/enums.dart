enum IncidentStatus {
  submitted('Submitted'),
  inReview('In Review'),
  inProgress('In Progress'),
  resolved('Resolved');

  const IncidentStatus(this.label);
  final String label;

  bool get isOpen => this != resolved;
}

enum IncidentCategory {
  facilities('Facilities'),
  water('Water'),
  electricity('Electricity'),
  safety('Safety'),
  sanitation('Sanitation'),
  furniture('Furniture');

  const IncidentCategory(this.label);
  final String label;
}

enum IncidentPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const IncidentPriority(this.label);
  final String label;
}

enum UserRole { student, staff }

/// Safe enum lookup for values read from the database.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);
