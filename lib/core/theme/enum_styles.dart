import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

/// Visual meaning of domain enums — kept out of the data layer.
extension IncidentStatusStyle on IncidentStatus {
  Color get color => switch (this) {
        IncidentStatus.submitted => const Color(0xFFB7791F),
        IncidentStatus.inReview => const Color(0xFF2F6FDB),
        IncidentStatus.inProgress => const Color(0xFF8B10F2),
        IncidentStatus.resolved => const Color(0xFF1E9E63),
      };

  Color get background => switch (this) {
        IncidentStatus.submitted => const Color(0xFFFFF1CC),
        IncidentStatus.inReview => const Color(0xFFE3EEFF),
        IncidentStatus.inProgress => const Color(0xFFF1E4FF),
        IncidentStatus.resolved => const Color(0xFFDDF6EA),
      };

  IconData get icon => switch (this) {
        IncidentStatus.submitted => Icons.send_rounded,
        IncidentStatus.inReview => Icons.visibility_rounded,
        IncidentStatus.inProgress => Icons.build_rounded,
        IncidentStatus.resolved => Icons.check_rounded,
      };
}

extension IncidentCategoryStyle on IncidentCategory {
  IconData get icon => switch (this) {
        IncidentCategory.facilities => Icons.apartment_rounded,
        IncidentCategory.water => Icons.water_drop_outlined,
        IncidentCategory.electricity => Icons.bolt_rounded,
        IncidentCategory.safety => Icons.shield_outlined,
        IncidentCategory.sanitation => Icons.delete_outline_rounded,
        IncidentCategory.furniture => Icons.chair_outlined,
      };

  Color get color => switch (this) {
        IncidentCategory.facilities => const Color(0xFF8B10F2),
        IncidentCategory.water => const Color(0xFF2F8FDB),
        IncidentCategory.electricity => const Color(0xFFE0A100),
        IncidentCategory.safety => const Color(0xFFE5484D),
        IncidentCategory.sanitation => const Color(0xFF1E9E63),
        IncidentCategory.furniture => const Color(0xFFB0662B),
      };
}

extension IncidentPriorityStyle on IncidentPriority {
  Color get color => switch (this) {
        IncidentPriority.low => const Color(0xFF6E6B85),
        IncidentPriority.medium => const Color(0xFFB7791F),
        IncidentPriority.high => const Color(0xFFE5484D),
      };
}
