import '../constants/app_constants.dart';

/// Form validators: return an error message, or null when valid.
abstract final class Validators {
  static final _emailRe = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$');

  static String? email(String? v) {
    final value = v?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(value)) return 'Enter a valid email address';
    final domain = value.split('@').last;
    if (!AppConstants.allowedEmailDomains.contains(domain)) {
      return 'Use your @${AppConstants.allowedEmailDomains.first} email';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < AppConstants.passwordMin) {
      return 'At least ${AppConstants.passwordMin} characters';
    }
    return null;
  }

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name is too short';
    return null;
  }

  static String? title(String? v) => _length(
      v, 'Title', AppConstants.titleMin, AppConstants.titleMax);

  static String? description(String? v) => _length(v, 'Description',
      AppConstants.descriptionMin, AppConstants.descriptionMax);

  static String? _length(String? v, String field, int min, int max) {
    final len = v?.trim().length ?? 0;
    if (len == 0) return '$field is required';
    if (len < min) return '$field needs at least $min characters';
    if (len > max) return '$field must be under $max characters';
    return null;
  }
}
