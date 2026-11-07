import 'package:intl/intl.dart';

String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return _plural(diff.inMinutes, 'min');
  if (diff.inDays < 1) return _plural(diff.inHours, 'hour');
  if (diff.inDays < 7) return _plural(diff.inDays, 'day');
  return DateFormat('MMM d, y').format(date);
}

String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';

String fullDate(DateTime date) =>
    DateFormat("MMM d, y 'at' h:mm a").format(date);

String shortDate(DateTime date) => DateFormat('MMM d, h:mm a').format(date);

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

String firstName(String name) => name.trim().split(' ').first;
