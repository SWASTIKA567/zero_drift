import 'package:flutter/material.dart';

class AppColors {
  // Primary brand blues
  static const Color primary = Color(0xFF1E6BFF); // Electric modern blue
  static const Color primaryHover = Color(0xFF1955CC);
  static const Color primaryDark = Color(0xFF1540A8);
  static const Color primaryLight = Color(0xFFEBF2FE);
  static const Color primaryGlow = Color(0x331E6BFF);

  // Backgrounds
  static const Color background = Color(0xFFF4F7FC); // Soft ice-blue / grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8FAFD);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);
  static const Color borderFocus = Color(0xFF1E6BFF);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Deep slate
  static const Color textSecondary = Color(0xFF64748B); // Slate grey
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status & Telemetry
  static const Color success = Color(0xFF10B981); // Emerald / GNSS green
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color accentOrange = Color(0xFFF97316); // Route orange

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E6BFF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF0052FF), Color(0xFF3B82F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
