/// Any failure whose [message] is safe to show to the user.
class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Firestore / Storage error codes → user-facing text.
String messageForCode(String code) => switch (code) {
      'permission-denied' || 'unauthorized' => "You don't have permission to do that.",
      'unavailable' || 'network-request-failed' || 'retry-limit-exceeded' =>
        'You appear to be offline. Check your connection and try again.',
      'not-found' || 'object-not-found' => 'This report no longer exists.',
      'quota-exceeded' => 'The service is busy. Try again in a moment.',
      'canceled' => 'The upload was cancelled.',
      _ => 'Something went wrong ($code). Please try again.',
    };
