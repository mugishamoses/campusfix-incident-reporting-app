import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/incident.dart';
import 'incident_widgets.dart';

/// Purple "See an issue on campus?" banner from the home mockup.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadow.lifted,
      ),
      child: Stack(
        children: [
          const Positioned(right: -10, top: 6, child: _CampusIllustration()),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xl - 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 190,
                  child: Text(
                    'See an issue on campus?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                SizedBox(
                  width: 180,
                  child: Text(
                    'Report it and help improve our learning environment.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13,
                        height: 1.4),
                  ),
                ),
                const SizedBox(height: AppSpace.l + 2),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: InkWell(
                    onTap: onReport,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.m, vertical: AppSpace.m),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: AppSpace.m),
                          const Expanded(
                            child: Text('Report an Issue',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple flat building + trees drawn with shapes (no image assets).
class _CampusIllustration extends StatelessWidget {
  const _CampusIllustration();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 160, height: 110, child: CustomPaint(painter: _CampusPainter()));
}

class _CampusPainter extends CustomPainter {
  const _CampusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withValues(alpha: .18);
    final whiteStrong = Paint()..color = Colors.white.withValues(alpha: .32);
    final window = Paint()..color = Colors.white.withValues(alpha: .55);
    final tree = Paint()..color = const Color(0xFF7FE0A8).withValues(alpha: .55);

    // clouds
    canvas.drawCircle(const Offset(40, 18), 10, white);
    canvas.drawCircle(const Offset(54, 14), 13, white);
    canvas.drawCircle(const Offset(68, 19), 9, white);

    // building body + roof
    final body = RRect.fromLTRBR(50, 48, 140, 110, const Radius.circular(4));
    canvas.drawRRect(body, whiteStrong);
    final roof = Path()
      ..moveTo(44, 50)
      ..lineTo(95, 26)
      ..lineTo(146, 50)
      ..close();
    canvas.drawPath(roof, whiteStrong);
    // windows
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawRRect(
            RRect.fromLTRBR(60.0 + col * 20, 58.0 + row * 18, 72.0 + col * 20,
                70.0 + row * 18, const Radius.circular(2)),
            window);
      }
    }
    canvas.drawRRect(
        RRect.fromLTRBR(88, 92, 102, 110, const Radius.circular(3)), window);

    // trees
    for (final x in [30.0, 152.0]) {
      canvas.drawCircle(Offset(x, 86), 15, tree);
      canvas.drawRect(Rect.fromLTWH(x - 2, 96, 4, 14), white);
    }
    canvas.drawArc(Rect.fromCircle(center: const Offset(150, 30), radius: 8), 0,
        math.pi * 2, false, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dashed "Tap to add photos" box; shows the picked photo with remove button.
class PhotoPickerBox extends StatelessWidget {
  const PhotoPickerBox({
    super.key,
    required this.preview,
    required this.onPick,
    required this.onRemove,
  });

  /// Incident-like preview holder; null when no photo is picked.
  final Incident? preview;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (preview != null) {
      return Stack(
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: IncidentImage(incident: preview!, radius: AppRadius.card),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white),
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: 'Add a photo',
      child: GestureDetector(
        onTap: onPick,
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: SizedBox(
            height: 108,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary, size: 28),
                const SizedBox(height: 6),
                Text('Tap to add a photo',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9C5DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(AppRadius.card));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
