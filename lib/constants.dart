import 'package:flutter/material.dart';

// ─── Legacy (backward-compatible) ─────────────────────────────────────────────
class AppColor {
  final Color whiteColor = const Color(0xffFAF8F6);
  final Color blueColor  = AppTheme.primary;
}

class UrlConst {
  final String domain = "http://localhost:3000/api/";
}

// ─── Design System ────────────────────────────────────────────────────────────
class AppTheme {
  // Colors
  static const Color primary       = Color(0xFF5A00FF);
  static const Color primaryDark   = Color(0xFF3D00B8);
  static const Color primaryLight  = Color(0xFF8B5CE7);
  static const Color accent        = Color(0xFFFF6584);
  static const Color success       = Color(0xFF00C48C);
  static const Color warning       = Color(0xFFFFB020);
  static const Color error         = Color(0xFFFF4D6D);
  static const Color bgLight       = Color(0xFFF4F0FF);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color textDark      = Color(0xFF1A0047);
  static const Color textMid       = Color(0xFF7868A6);
  static const Color textLight     = Color(0xFFB0A8CC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5A00FF), Color(0xFF3D00B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFF5A00FF), Color(0xFF8B5CE7)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // Border radius
  static const double radiusSmall  = 10;
  static const double radiusMedium = 16;
  static const double radiusLarge  = 24;
  static const double radiusXL     = 32;

  // MaterialApp ThemeData
  static ThemeData get theme => ThemeData(
    useMaterial3: false,
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
    ),
  );
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

/// Gradient button — used in Login, Countdown, Home, etc.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final double? width;

  const GradientButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppTheme.primaryGradient
              : const LinearGradient(colors: [Color(0xFFAA88FF), Color(0xFF8866DD)]),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: onPressed != null ? AppTheme.buttonShadow : [],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }
}
