import 'package:flutter/material.dart';

/// Design tokens sampled from the mockups (docs/mockups).
abstract final class AppColors {
  static const primary = Color(0xFF8B10F2);
  static const primaryDark = Color(0xFF6407B8);
  static const primarySoft = Color(0xFFF3E8FF);
  static const background = Color(0xFFF7F6FB);
  static const surface = Colors.white;
  static const text = Color(0xFF16142B);
  static const textMuted = Color(0xFF6E6B85);
  static const border = Color(0xFFECEAF3);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF1E9E63);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B2CF8), Color(0xFF6A0BD8)],
  );
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = EdgeInsets.symmetric(horizontal: l);
}

abstract final class AppRadius {
  static const input = 12.0;
  static const card = 16.0;
  static const hero = 24.0;
}

abstract final class AppShadow {
  static const soft = [
    BoxShadow(color: Color(0x0F2A1259), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const lifted = [
    BoxShadow(color: Color(0x408B10F2), blurRadius: 18, offset: Offset(0, 8)),
  ];
}
