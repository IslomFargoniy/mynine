import 'package:flutter/material.dart';

import 'providers.dart';

abstract final class AppColors {
  static const ieltsRed = Color(0xFFE11D48);
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF111827);
  static const grey = Color(0xFF6B7280);
  static const border = Color(0xFFD1D5DB);
  static const canvas = Color(0xFFE5E7EB);
  static const panel = Color(0xFFF9FAFB);
  static const flag = Color(0xFFF97316);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
  ).copyWith(primary: AppColors.blue, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// Colours of the question/passage area for the contrast settings
/// (mirrors the web's standard / yellow-on-black / white-on-blue).
class ExamPalette {
  const ExamPalette({
    required this.background,
    required this.panel,
    required this.text,
    required this.muted,
    required this.highlight,
    required this.note,
    required this.inputFill,
    required this.inputText,
    required this.accent,
  });

  final Color background;
  final Color panel;
  final Color text;
  final Color muted;
  final Color highlight;
  final Color note;
  final Color inputFill;
  final Color inputText;
  final Color accent;

  static ExamPalette of(ContrastSetting c) => switch (c) {
        ContrastSetting.standard => const ExamPalette(
            background: Colors.white,
            panel: AppColors.panel,
            text: AppColors.ink,
            muted: AppColors.grey,
            highlight: Color(0x80FDE047),
            note: Color(0x8093C5FD),
            inputFill: Colors.white,
            inputText: AppColors.ink,
            accent: AppColors.blue,
          ),
        ContrastSetting.yellowBlack => const ExamPalette(
            background: Colors.black,
            panel: Colors.black,
            text: Color(0xFFFDE047),
            muted: Color(0xFFFACC15),
            highlight: Color(0xFF84CC16),
            note: Color(0xFF22D3EE),
            inputFill: Colors.black,
            inputText: Color(0xFFFDE047),
            accent: Color(0xFFFDE047),
          ),
        ContrastSetting.blueWhite => const ExamPalette(
            background: Color(0xFF002B49),
            panel: Color(0xFF002B49),
            text: Colors.white,
            muted: Color(0xFFCBD5E1),
            highlight: Color(0xFFFDE047),
            note: Color(0xFF93C5FD),
            inputFill: Color(0xFF00406B),
            inputText: Colors.white,
            accent: Color(0xFF93C5FD),
          ),
      };
}
