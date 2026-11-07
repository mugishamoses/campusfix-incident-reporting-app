import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/incident.dart';

abstract interface class IncidentRepository {
  /// Every incident, newest first. Visibility filtering happens in logic.
  Stream<List<Incident>> watchAll();

  Stream<Incident?> watchOne(String id);

  Stream<List<StatusChange>> watchHistory(String incidentId);

  Stream<List<AppNotification>> watchNotifications(String uid);

  /// [photoPath] is a local file; [onProgress] reports upload 0..1.
  Future<String> create({
    required Incident draft,
    String? photoPath,
    void Function(double progress)? onProgress,
  });

  /// Owner edit while still submitted. [removePhoto] clears the attached photo.
  Future<void> update(Incident incident, {String? newPhotoPath, bool removePhoto = false});

  Future<void> delete(String id);

  /// Staff: writes incident + history entry + reporter notification together.
  Future<void> changeStatus({
    required Incident incident,
    required IncidentStatus to,
    required AppUser by,
    String? note,
  });

  Future<void> setPriority(String id, IncidentPriority priority);

  Future<void> setHidden(String id, bool hidden);

  Future<void> markNotificationRead(String uid, String notificationId);
}
