import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_failure.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import 'incident_repository.dart';

/// incidents/{id}(/history), users/{uid}/notifications; photos at Storage incidents/{uid}/{id}.jpg.
class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');
  CollectionReference<Map<String, dynamic>> _history(String id) =>
      _incidents.doc(id).collection('history');
  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _db.collection('users/$uid/notifications');

  static Object _map(Object e) =>
      e is FirebaseException ? AppFailure(messageForCode(e.code)) : e;

  /// Converts Firebase errors on streams into user-readable [AppFailure]s.
  static Stream<T> _safe<T>(Stream<T> s) =>
      s.handleError((Object e) => throw _map(e));

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _map(e);
    }
  }

  // ------------------------------------------------------------ reads

  @override
  Stream<List<Incident>> watchAll() => _safe(
    _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _incidentFrom(d.id, d.data())).toList()),
  );

  @override
  Stream<Incident?> watchOne(String id) => _safe(
    _incidents
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? _incidentFrom(d.id, d.data()!) : null),
  );

  @override
  Stream<List<StatusChange>> watchHistory(String incidentId) => _safe(
    _history(incidentId)
        .orderBy('at')
        .snapshots()
        .map((s) => s.docs.map((d) => _changeFrom(d.data())).toList()),
  );

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) => _safe(
    _notifications(uid)
        .orderBy('at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => _notificationFrom(d.id, d.data())).toList(),
        ),
  );

  // ------------------------------------------------------------ writes

  Future<String> _upload(
    String uid,
    String incidentId,
    String localPath,
    void Function(double)? onProgress,
  ) async {
    final ref = _storage.ref('incidents/$uid/$incidentId.jpg');
    // Bytes (not File) so the same code uploads from Android, iOS and web (blob URLs).
    final task = ref.putData(
      await XFile(localPath).readAsBytes(),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return ref.getDownloadURL();
  }

  @override
  Future<String> create({
    required Incident draft,
    String? photoPath,
    void Function(double progress)? onProgress,
  }) => _guard(() async {
    final doc = _incidents.doc();
    final photoUrl = photoPath == null
        ? null
        : await _upload(draft.reporterId, doc.id, photoPath, onProgress);
    final batch = _db.batch()
      ..set(doc, {
        'title': draft.title,
        'description': draft.description,
        'category': draft.category.name,
        'location': draft.location,
        'status': IncidentStatus.submitted.name,
        'priority': IncidentPriority.medium.name,
        'reporterId': draft.reporterId,
        'reporterName': draft.reporterName,
        'isAnonymous': draft.isAnonymous,
        'isHidden': false,
        'photoUrl': photoUrl,
        'resolutionNote': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_history(doc.id).doc(), {
        'from': null,
        'to': IncidentStatus.submitted.name,
        'byName': draft.reporterName,
        'note': null,
        'at': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return doc.id;
  });

  @override
  Future<void> update(
    Incident incident, {
    String? newPhotoPath,
    bool removePhoto = false,
  }) => _guard(() async {
    final photoUrl = removePhoto
        ? null
        : newPhotoPath == null
        ? incident.photoUrl
        : await _upload(incident.reporterId, incident.id, newPhotoPath, null);
    await _incidents.doc(incident.id).update({
      'title': incident.title,
      'description': incident.description,
      'category': incident.category.name,
      'location': incident.location,
      'reporterName': incident.reporterName,
      'isAnonymous': incident.isAnonymous,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (removePhoto) await _deletePhoto(incident.reporterId, incident.id);
  });

  /// Best effort: a leftover photo is harmless, failing the user's action is not.
  Future<void> _deletePhoto(String uid, String id) async {
    try {
      await _storage.ref('incidents/$uid/$id.jpg').delete();
    } on FirebaseException catch (_) {}
  }

  @override
  Future<void> delete(String id) => _guard(() async {
    final doc = await _incidents.doc(id).get();
    final data = doc.data();
    if (data == null) return;
    final batch = _db.batch();
    for (final h in (await _history(id).get()).docs) {
      batch.delete(h.reference);
    }
    batch.delete(doc.reference);
    await batch.commit();
    if (data['photoUrl'] != null) {
      await _deletePhoto(data['reporterId'] as String, id);
    }
  });

  @override
  Future<void> changeStatus({
    required Incident incident,
    required IncidentStatus to,
    required AppUser by,
    String? note,
  }) => _guard(() async {
    final trimmed = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    final batch = _db.batch()
      ..update(_incidents.doc(incident.id), {
        'status': to.name,
        'resolutionNote': to == IncidentStatus.resolved ? trimmed : null,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_history(incident.id).doc(), {
        'from': incident.status.name,
        'to': to.name,
        'byName': by.name,
        'note': trimmed,
        'at': FieldValue.serverTimestamp(),
      })
      ..set(_notifications(incident.reporterId).doc(), {
        'incidentId': incident.id,
        'title': '${incident.title} is now ${to.label}',
        'message': trimmed ?? 'Updated by ${by.name}',
        'read': false,
        'at': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  });

  @override
  Future<void> setPriority(String id, IncidentPriority priority) => _guard(
    () => _incidents.doc(id).update({
      'priority': priority.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> setHidden(String id, bool hidden) => _guard(
    () => _incidents.doc(id).update({
      'isHidden': hidden,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> markNotificationRead(String uid, String notificationId) =>
      _guard(
        () => _notifications(uid).doc(notificationId).update({'read': true}),
      );

  // ------------------------------------------------------------ mapping

  /// Pending server timestamps read back as null on the local echo.
  static DateTime _date(Object? v) =>
      (v as Timestamp?)?.toDate() ?? DateTime.now();

  static Incident _incidentFrom(String id, Map<String, dynamic> m) => Incident(
    id: id,
    title: m['title'] as String? ?? '',
    description: m['description'] as String? ?? '',
    category: enumByName(
      IncidentCategory.values,
      m['category'],
      IncidentCategory.facilities,
    ),
    location: m['location'] as String? ?? '',
    status: enumByName(
      IncidentStatus.values,
      m['status'],
      IncidentStatus.submitted,
    ),
    priority: enumByName(
      IncidentPriority.values,
      m['priority'],
      IncidentPriority.medium,
    ),
    reporterId: m['reporterId'] as String? ?? '',
    reporterName: m['reporterName'] as String? ?? '',
    photoUrl: m['photoUrl'] as String?,
    resolutionNote: m['resolutionNote'] as String?,
    isAnonymous: m['isAnonymous'] as bool? ?? false,
    isHidden: m['isHidden'] as bool? ?? false,
    createdAt: _date(m['createdAt']),
    updatedAt: _date(m['updatedAt']),
  );

  static StatusChange _changeFrom(Map<String, dynamic> m) => StatusChange(
    from: m['from'] == null
        ? null
        : enumByName(
            IncidentStatus.values,
            m['from'],
            IncidentStatus.submitted,
          ),
    to: enumByName(IncidentStatus.values, m['to'], IncidentStatus.submitted),
    byName: m['byName'] as String? ?? '',
    note: m['note'] as String?,
    at: _date(m['at']),
  );

  static AppNotification _notificationFrom(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        incidentId: m['incidentId'] as String? ?? '',
        title: m['title'] as String? ?? '',
        message: m['message'] as String? ?? '',
        read: m['read'] as bool? ?? false,
        at: _date(m['at']),
      );
}
