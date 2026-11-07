import 'enums.dart';

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.priority,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.resolutionNote,
    this.isAnonymous = false,
    this.isHidden = false,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? resolutionNote;
  final bool isAnonymous;
  final bool isHidden;

  /// Students may edit/delete their own report until staff pick it up.
  bool get isEditable => status == IncidentStatus.submitted;

  Incident copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    String? location,
    String? reporterName,
    IncidentStatus? status,
    IncidentPriority? priority,
    DateTime? updatedAt,
    String? photoUrl,
    String? resolutionNote,
    bool? isAnonymous,
    bool? isHidden,
    bool clearPhoto = false,
    bool clearResolution = false,
  }) =>
      Incident(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        location: location ?? this.location,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        reporterId: reporterId,
        reporterName: reporterName ?? this.reporterName,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        photoUrl: clearPhoto ? null : photoUrl ?? this.photoUrl,
        resolutionNote: clearResolution ? null : resolutionNote ?? this.resolutionNote,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        isHidden: isHidden ?? this.isHidden,
      );
}

/// One step in an incident's status history (drives the timeline).
class StatusChange {
  const StatusChange({
    required this.to,
    required this.byName,
    required this.at,
    this.from,
    this.note,
  });

  final IncidentStatus? from;
  final IncidentStatus to;
  final String byName;
  final DateTime at;
  final String? note;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.message,
    required this.at,
    this.read = false,
  });

  final String id;
  final String incidentId;
  final String title;
  final String message;
  final DateTime at;
  final bool read;
}
