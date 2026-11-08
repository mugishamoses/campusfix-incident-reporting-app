import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/incident.dart';
import '../../../logic/auth_providers.dart';
import '../../../logic/incident_actions.dart';
import '../../../logic/incident_providers.dart';
import '../../widgets/basics.dart';
import '../../widgets/feature_widgets.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/incident_widgets.dart';
import '../../widgets/state_views.dart';

/// New report, or edit of an own report while it is still "Submitted".
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.editId});
  final String? editId;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  Incident? _editing;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    // Reset shared form state once the first frame is built.
    Future.microtask(() => ref.read(reportFormProvider.notifier).reset());
  }

  void _loadForEdit(Incident incident) {
    _editing = incident;
    _title.text = incident.title;
    _description.text = incident.description;
    ref.read(reportFormProvider.notifier).loadFrom(incident);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Downscale on pick: keeps uploads small and fast on campus Wi-Fi.
      final file = await ImagePicker().pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 75);
      if (file != null) ref.read(reportFormProvider.notifier).setPhoto(file.path);
    } on PlatformException catch (e) {
      if (mounted) showSnack(context, 'Could not open ${source.name}: ${e.message}', error: true);
    }
  }

  Future<void> _submit() async {
    setState(() => _triedSubmit = true);
    final state = ref.read(reportFormProvider);
    final fieldsOk = _form.currentState!.validate();
    if (!fieldsOk || state.category == null || state.location == null) {
      showSnack(context, 'Please complete the highlighted fields.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      final id = await ref.read(reportFormProvider.notifier).submit(
            title: _title.text,
            description: _description.text,
            editing: _editing,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (_editing != null) {
        showSnack(context, 'Report updated.');
        context.pop();
      } else {
        await _showSuccess(id);
      }
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _showSuccess(String id) async {
    final view = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .4, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFDDF6EA),
                  child: Icon(Icons.check_rounded, size: 44, color: AppColors.success),
                ),
              ),
              const SizedBox(height: AppSpace.l),
              Text('Report submitted', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpace.xs),
              Text(
                "Thanks for helping. Campus staff will review it soon — you'll get a notification at every step.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.xl),
              PrimaryButton(label: 'Track my report', onPressed: () => Navigator.pop(context, true)),
              const SizedBox(height: AppSpace.s),
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    context.pop();
    if (view ?? false) context.push(Routes.incident(id));
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the report to load, or saving would create a duplicate.
    final editId = widget.editId;
    if (editId != null && _editing == null) {
      final loaded = ref.watch(incidentProvider(editId));
      final incident = loaded.value;
      if (incident != null && incident.isEditable) {
        Future.microtask(() => setState(() => _loadForEdit(incident)));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Report')),
        body: loaded.isLoading || (incident?.isEditable ?? false)
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.lock_outline_rounded,
                title: "Can't edit this report",
                message: 'Only reports still marked Submitted can be edited.'),
      );
    }
    final state = ref.watch(reportFormProvider);
    final controller = ref.read(reportFormProvider.notifier);
    final text = Theme.of(context).textTheme;
    const gap = SizedBox(height: AppSpace.xl - 4);
    final photoPreview = state.photoPath == null
        ? null
        : Incident(
            id: 'preview',
            title: '',
            description: '',
            category: state.category ?? IncidentCategory.facilities,
            location: '',
            status: IncidentStatus.submitted,
            priority: IncidentPriority.medium,
            reporterId: '',
            reporterName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            photoUrl: state.photoPath,
          );
    final progress = state.progress;

    return PopScope(
      canPop: !state.submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(_editing == null ? 'Report an Incident' : 'Edit Report')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.s, AppSpace.l, AppSpace.xxl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const FieldLabel('Select a category'),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.s + 2,
                crossAxisSpacing: AppSpace.s + 2,
                childAspectRatio: 1.35,
                children: [
                  for (final c in IncidentCategory.values)
                    CategoryTile(
                      category: c,
                      selected: state.category == c,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setCategory(c);
                      },
                    ),
                ],
              ),
              // Fixed slot: inserting a child shifts ListView indices and wipes field errors.
              _triedSubmit && state.category == null
                  ? const _InlineError('Choose a category')
                  : const SizedBox.shrink(),
              gap,
              AppTextField(
                label: 'Title',
                controller: _title,
                hint: 'Briefly describe the issue…',
                maxLength: AppConstants.titleMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.title,
              ),
              gap,
              AppTextField(
                label: 'Description',
                controller: _description,
                hint: 'Provide more details about the issue…\ne.g. what happened, when, impact, etc.',
                maxLines: 5,
                maxLength: AppConstants.descriptionMax,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.description,
              ),
              gap,
              const FieldLabel('Location'),
              DropdownButtonFormField<String>(
                key: ValueKey(_editing?.id), // re-init once the edited report loads
                initialValue: state.location,
                isExpanded: true,
                hint: const Text('Where is it?'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(AppRadius.input),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
                ),
                items: [
                  for (final l in AppConstants.campusLocations)
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                validator: (v) => v == null ? 'Choose a location' : null,
                onChanged: (v) => v == null ? null : controller.setLocation(v),
              ),
              gap,
              const FieldLabel('Add a photo', optional: true),
              PhotoPickerBox(
                preview: photoPreview,
                onPick: _pickPhoto,
                onRemove: () => controller.setPhoto(null),
              ),
              const SizedBox(height: AppSpace.l),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xs),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.isAnonymous,
                  onChanged: controller.setAnonymous,
                  title: Text('Report anonymously', style: text.titleSmall),
                  subtitle: Text('Your name won\'t be saved on this report.',
                      style: text.bodySmall),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.primarySoft,
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                Text('Uploading photo… ${(progress * 100).round()}%',
                    textAlign: TextAlign.center, style: text.bodySmall),
                const SizedBox(height: AppSpace.m),
              ],
              PrimaryButton(
                label: _editing == null ? 'Submit Report' : 'Save changes',
                loading: state.submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpace.s, left: AppSpace.xs),
        child: Text(message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger)),
      );
}
