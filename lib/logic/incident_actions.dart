import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_failure.dart';
import '../data/models/enums.dart';
import '../data/models/incident.dart';
import 'auth_providers.dart';
import 'incident_providers.dart';

/// Anonymous reports never store the real name, so it can't leak via reads.
String reporterNameFor(String name, bool anonymous) =>
    anonymous ? 'Anonymous student' : name;


/// Report form state: everything that isn't a text controller.
class ReportFormState {
  const ReportFormState({
    this.category,
    this.location,
    this.photoPath,
    this.isAnonymous = false,
    this.progress,
    this.submitting = false,
  });

  final IncidentCategory? category;
  final String? location;
  final String? photoPath;
  final bool isAnonymous;
  final double? progress;
  final bool submitting;

  ReportFormState copyWith({
    IncidentCategory? category,
    String? location,
    String? Function()? photoPath,
    bool? isAnonymous,
    double? Function()? progress,
    bool? submitting,
  }) =>
      ReportFormState(
        category: category ?? this.category,
        location: location ?? this.location,
        photoPath: photoPath != null ? photoPath() : this.photoPath,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        progress: progress != null ? progress() : this.progress,
        submitting: submitting ?? this.submitting,
      );
}

class ReportFormController extends Notifier<ReportFormState> {
  @override
  ReportFormState build() => const ReportFormState();

  void loadFrom(Incident i) => state = ReportFormState(
      category: i.category,
      location: i.location,
      photoPath: i.photoUrl,
      isAnonymous: i.isAnonymous);

  void reset() => state = const ReportFormState();
  void setCategory(IncidentCategory c) => state = state.copyWith(category: c);
  void setLocation(String l) => state = state.copyWith(location: l);
  void setPhoto(String? path) => state = state.copyWith(photoPath: () => path);
  void setAnonymous(bool v) => state = state.copyWith(isAnonymous: v);

  /// Creates (or, with [editing], updates) a report. Returns the incident id.
  Future<String> submit({
    required String title,
    required String description,
    Incident? editing,
  }) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(incidentRepositoryProvider);
    if (user == null) throw const AppFailure('You are signed out.');
    final category = state.category;
    final location = state.location;
    if (category == null) throw const AppFailure('Pick a category.');
    if (location == null) throw const AppFailure('Pick a location.');

    if (editing == null) {
      final open = ref.read(myIncidentsProvider).value?.where((i) => i.status.isOpen).length ?? 0;
      if (open >= AppConstants.maxOpenReportsPerStudent) {
        throw const AppFailure(
            'You have ${AppConstants.maxOpenReportsPerStudent} open reports. '
            'Wait for one to be resolved before adding another.');
      }
    }

    state = state.copyWith(submitting: true, progress: () => null);
    try {
      if (editing != null) {
        final photoChanged = state.photoPath != editing.photoUrl;
        await repo.update(
          editing.copyWith(
            title: title.trim(),
            description: description.trim(),
            category: category,
            location: location,
            reporterName: reporterNameFor(user.name, state.isAnonymous),
            isAnonymous: state.isAnonymous,
          ),
          newPhotoPath: photoChanged ? state.photoPath : null,
          removePhoto: photoChanged && state.photoPath == null,
        );
        return editing.id;
      }
      final now = DateTime.now();
      return await repo.create(
        draft: Incident(
          id: '',
          title: title.trim(),
          description: description.trim(),
          category: category,
          location: location,
          status: IncidentStatus.submitted,
          priority: IncidentPriority.medium,
          reporterId: user.uid,
          reporterName: reporterNameFor(user.name, state.isAnonymous),
          isAnonymous: state.isAnonymous,
          createdAt: now,
          updatedAt: now,
        ),
        photoPath: state.photoPath,
        onProgress: (p) => state = state.copyWith(progress: () => p),
      );
    } finally {
      state = state.copyWith(submitting: false, progress: () => null);
    }
  }
}

final reportFormProvider =
    NotifierProvider<ReportFormController, ReportFormState>(
        ReportFormController.new);

/// Staff + owner actions on a single incident.
class IncidentActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> changeStatus(Incident i, IncidentStatus to, String? note) =>
      _run(() async {
        final user = ref.read(currentUserProvider);
        if (user == null || !user.isStaff) {
          throw const AppFailure('Only staff can change status.');
        }
        await ref.read(incidentRepositoryProvider)
            .changeStatus(incident: i, to: to, by: user, note: note);
      });

  Future<bool> setPriority(Incident i, IncidentPriority p) =>
      _run(() => ref.read(incidentRepositoryProvider).setPriority(i.id, p));

  Future<bool> setHidden(Incident i, bool hidden) =>
      _run(() => ref.read(incidentRepositoryProvider).setHidden(i.id, hidden));

  Future<bool> delete(Incident i) =>
      _run(() => ref.read(incidentRepositoryProvider).delete(i.id));

  Future<void> markRead(String notificationId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(incidentRepositoryProvider).markNotificationRead(uid, notificationId);
  }
}

final incidentActionsProvider =
    NotifierProvider<IncidentActions, AsyncValue<void>>(IncidentActions.new);
