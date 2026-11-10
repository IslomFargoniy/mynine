import 'package:flutter/material.dart';

import '../core/theme/web_tokens.dart';
import 'providers.dart';

/// Short aliases used across screens (all from [WebTokens] / [TW]).
abstract final class AppColors {
  static const ieltsRed = WebTokens.ieltsBadge;
  static const blue = WebTokens.badgeBlue;
  static const ink = TW.gray900;
  static const grey = TW.gray500;
  static const border = TW.gray300;
  static const canvas = WebTokens.pageBackground;
  static const panel = TW.gray50;
  static const flag = TW.orange500;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: WebTokens.badgeBlue, brightness: Brightness.light)
      .copyWith(primary: WebTokens.badgeBlue, surface: Colors.white);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: kFontFamily);
  return base.copyWith(
    scaffoldBackgroundColor: WebTokens.pageBackground,
    textTheme: base.textTheme.apply(fontFamily: kFontFamily, bodyColor: TW.gray900, displayColor: TW.gray900),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color(0x663B82F6),
      cursorColor: TW.black,
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TW.black,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: WebTokens.r2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: inter(14, weight: FontWeight.w600, letterSpacing: 0.4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TW.gray700,
        side: const BorderSide(color: TW.gray300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: inter(12, weight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(textStyle: inter(12, color: Colors.white)),
  );
}

/// Colours of the exam content area for the three contrast schemes of the web
/// (index.tsx `.theme-yellow-black` / `.theme-blue-white`).
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
    required this.standard,
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

  /// True for the standard scheme (component colours apply unchanged).
  final bool standard;

  static ExamPalette of(ContrastSetting c) => switch (c) {
        ContrastSetting.standard => const ExamPalette(
            background: WebTokens.paneLeftBg,
            panel: WebTokens.paneRightBg,
            text: TW.black,
            muted: TW.gray500,
            highlight: WebTokens.highlight,
            note: WebTokens.highlight,
            inputFill: Colors.transparent,
            inputText: TW.black,
            accent: WebTokens.badgeBlue,
            standard: true,
          ),
        ContrastSetting.yellowBlack => const ExamPalette(
            background: WebTokens.yellowBlackBg,
            panel: WebTokens.yellowBlackBg,
            text: WebTokens.yellowBlackText,
            muted: WebTokens.yellowBlackText,
            highlight: WebTokens.yellowBlackMark,
            note: WebTokens.yellowBlackMark,
            inputFill: Colors.transparent,
            inputText: WebTokens.yellowBlackText,
            accent: WebTokens.yellowBlackText,
            standard: false,
          ),
        ContrastSetting.blueWhite => const ExamPalette(
            background: WebTokens.blueWhiteBg,
            panel: WebTokens.blueWhiteBg,
            text: WebTokens.blueWhiteText,
            muted: WebTokens.blueWhiteText,
            highlight: WebTokens.blueWhiteMark,
            note: WebTokens.blueWhiteMark,
            inputFill: Colors.transparent,
            inputText: WebTokens.blueWhiteText,
            accent: WebTokens.blueWhiteText,
            standard: false,
          ),
      };
}
