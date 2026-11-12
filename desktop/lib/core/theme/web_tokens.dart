// Design tokens of the web practice exam room (mynine.uz), converted from
// Tailwind classes to exact values. Every token names its source:
//   index.tsx               = resources/js/pages/practice/index.tsx
//   header.tsx              = resources/js/components/practice/inspera-header.tsx
//   number-bar.tsx          = …/practice-number-bar.tsx
//   part.tsx                = …/practice-part.tsx (passage, highlighter, notes)
//   section.tsx / question.tsx / option.tsx / matching.tsx / essay
//   sound-check.tsx, finish-modal.tsx, countdown-timer.tsx, audio-equalizer.tsx
//   app.css                 = resources/css/app.css
// Tailwind spacing: 1 unit = 4 px; text-xs 12/16, text-sm 14/20, text-base
// 16/24, text-lg 18/28, text-xl 20/28, text-3xl 30/36.
import 'package:flutter/material.dart';

import 'tailwind_palette.dart';

export 'tailwind_palette.dart';

/// Font: app.css `--font-sans: 'Inter', …` loaded from fonts.bunny.net
/// (weights 400/500/600/700) in app.blade.php. Bundled under assets/fonts/inter.
const kFontFamily = 'Inter';

abstract final class WebTokens {
  // ---- Page ------------------------------------------------------------------
  /// index.tsx root `bg-[#e5e7eb]`.
  static const pageBackground = Color(0xFFE5E7EB);

  // ---- Header (header.tsx) ---------------------------------------------------
  /// `h-14`.
  static const headerHeight = 56.0;

  /// `px-4`.
  static const headerPaddingX = 16.0;

  /// `border-b border-gray-300`.
  static const headerBorder = TW.gray300;

  /// IELTS badge `bg-[#e11d48] text-white font-extrabold text-sm px-2.5 py-1 rounded-[2px]`.
  static const ieltsBadge = Color(0xFFE11D48);

  /// Candidate name `text-sm font-bold text-gray-800`.
  static const candidateText = TW.gray800;

  /// Separator `|` `text-gray-300 font-light text-base`.
  static const separator = TW.gray300;

  /// Hint `text-gray-500 text-sm` ("Read the text and answer questions.").
  static const hintText = TW.gray500;

  /// Header pill buttons `text-xs font-bold px-2.5 py-1 bg-gray-100
  /// hover:bg-gray-200 border border-gray-300 rounded-[2px] uppercase text-gray-800`.
  static const pillBg = TW.gray100;
  static const pillHover = TW.gray200;
  static const pillBorder = TW.gray300;
  static const pillText = TW.gray800;

  /// Timer box `bg-gray-50 px-2.5 py-1 rounded-[2px] border border-gray-300
  /// font-mono text-sm`; label `text-xs font-bold text-gray-500 uppercase`;
  /// value `font-bold text-red-600`; low time (≤ 3 min) `text-red-500 animate-pulse`;
  /// hidden `--:--:--` `text-gray-400`; eye icon `w-4 h-4 text-gray-400`.
  static const timerBg = TW.gray50;
  static const timerBorder = TW.gray300;
  static const timerLabel = TW.gray500;
  static const timerValue = TW.red600;
  static const timerLow = TW.red500;
  static const timerHidden = TW.gray400;
  static const lowTimeThreshold = Duration(minutes: 3);

  /// Finish `text-xs font-bold px-3 py-1 bg-rose-600 hover:bg-rose-700 text-white
  /// rounded-[2px] uppercase tracking-wider` + CheckCircle `w-3.5 h-3.5`.
  static const finishBg = TW.rose600;
  static const finishHover = TW.rose700;

  /// System icons `text-gray-600`, buttons `p-1.5 rounded`, icons `w-4 h-4`.
  static const systemIcon = TW.gray600;

  /// Sync status icon colours: online `text-emerald-600`, syncing
  /// `text-amber-500`, offline `text-red-500`.
  static const syncOnline = TW.emerald600;
  static const syncBusy = TW.amber500;
  static const syncOffline = TW.red500;

  // ---- Content panes (index.tsx) -----------------------------------------------
  /// Left pane `p-4 sm:p-6 border-r-2 border-gray-300` (white).
  static const paneLeftBg = TW.white;
  static const panePadding = 24.0;
  static const paneLeftBorder = TW.gray300;
  static const paneLeftBorderWidth = 2.0;

  /// Right pane `bg-gray-50 p-6`, content `max-w-3xl mx-auto` (768 px).
  static const paneRightBg = TW.gray50;
  static const questionsMaxWidth = 768.0;

  /// Divider `w-2.5 bg-gray-300 hover:bg-blue-600`, handle `w-5 h-8 bg-white
  /// border border-gray-400 rounded-[3px] shadow-sm` with "⟷" `text-[10px] font-mono text-gray-600`.
  static const dividerWidth = 10.0;
  static const dividerBg = TW.gray300;
  static const dividerHover = TW.blue600;
  static const dividerHandleBorder = TW.gray400;
  static const splitDefault = 0.5;
  static const splitMin = 0.25;
  static const splitMax = 0.75;

  // ---- Passage (part.tsx + app.css) ----------------------------------------------
  /// Part title `font-bold text-lg text-gray-900`, `mb-3`.
  static const partTitleSize = 18.0;
  static const partTitleColor = TW.gray900;

  /// Passage `prose text-[14px]` + app.css `.prose { line-height: 1.4 !important }`, `text-black`.
  static const passageFontSize = 14.0;
  static const proseLineHeight = 1.4;
  static const passageText = TW.black;

  /// app.css `mark.highlight { background-color: yellowgreen !important }`
  /// (overrides part.tsx rgba(253,224,71,.5)); notes add part.tsx
  /// `mark.note-highlight { border-bottom: 2px solid #2563eb }`.
  static const highlight = Color(0xFF9ACD32);
  static const noteUnderline = Color(0xFF2563EB);

  /// Tables (app.css `.ielts-passage table`): border `1px solid #555`,
  /// th `bg #f3f4f6, bold, padding 8px 12px`, td `padding 6px 12px`, font 1rem.
  static const tableBorder = Color(0xFF555555);
  static const tableHeaderBg = Color(0xFFF3F4F6);
  static const thPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const tdPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  /// Floating toolbar `bg-white border border-gray-300 shadow-xl rounded px-2 py-1
  /// gap-1.5`; buttons `p-1 min-w-[34px]` icon `w-3.5 h-3.5`, label
  /// `text-[9px] font-semibold uppercase`; Clear `text-red-600`; divider `w-[1px] h-6 bg-gray-200`.
  static const toolbarBorder = TW.gray300;
  static const toolbarText = TW.gray700;
  static const toolbarDivider = TW.gray200;
  static const toolbarClear = TW.red600;

  /// Notes button `bg-amber-50 hover:bg-amber-100 text-amber-900 border-amber-300
  /// text-xs font-semibold`, icon `text-amber-600`.
  static const notesBtnBg = TW.amber50;
  static const notesBtnBorder = TW.amber300;
  static const notesBtnText = TW.amber900;
  static const notesBtnIcon = TW.amber600;

  /// Notes drawer `fixed top-10 right-0 bottom-10 w-96 border-l border-gray-300
  /// shadow-2xl`; header `bg-[#0f172a] text-white px-4 py-3`, StickyNote `text-amber-400`;
  /// list `bg-slate-50 p-4 space-y-3`; card `bg-white border-gray-200 rounded-md p-3`;
  /// quote `text-xs italic text-gray-800 bg-amber-50 p-2 border-l-3 border-amber-400`.
  static const drawerWidth = 384.0;
  static const drawerInset = 40.0;
  static const drawerHeader = Color(0xFF0F172A);
  static const drawerListBg = TW.slate50;

  // ---- Questions (section.tsx / question.tsx / option.tsx) -------------------------
  /// Section `p-1 mb-6`, prose `text-[16px]` (line-height 1.4 from app.css);
  /// non-gap section html `text-base/8` (16 px / 32 px).
  static const sectionFontSize = 16.0;
  static const sectionInstructionLineHeight = 2.0;
  static const sectionGap = 24.0;

  /// Question number badge `min-w-[24px] h-6 px-1.5 border border-[#2563eb]
  /// bg-white text-[#2563eb] font-bold text-xs rounded-[2px]`; flagged
  /// `border-orange-500 bg-orange-50 text-orange-600` + star dot `w-3 h-3 bg-orange-500`.
  static const badgeBlue = Color(0xFF2563EB);
  static const flagBorder = TW.orange500;
  static const flagBg = TW.orange50;
  static const flagText = TW.orange600;

  /// Question text `text-sm leading-relaxed text-black` (14 / 1.625).
  static const questionFontSize = 14.0;
  static const questionLineHeight = 1.625;

  /// Option `px-3 py-1.5 rounded-[2px]`; checked `bg-[#e5e7eb] text-black font-semibold`;
  /// hover `bg-gray-100/70`; input `w-4 h-4 accent-black`; text `text-sm uppercase tracking-tight`.
  static const optionChecked = Color(0xFFE5E7EB);
  static const optionHover = Color(0xB3F3F4F6);

  /// Gap input (app.css `.ielts-gap-input`): width 10em, no box, `border-bottom: 2px solid #000`,
  /// focus `#2563eb`, padding 2px 4px, margin 0 4px.
  static const gapBorder = TW.black;
  static const gapFocus = Color(0xFF2563EB);
  static const gapWidthEm = 10.0;

  /// complete_section number `text-blue-600 font-semibold mr-1`.
  static const gapNumber = TW.black;

  /// drag chips `rounded-md border-[2px] border-blue-500 bg-white px-3 py-1 text-sm shadow-sm`;
  /// drop `min-w-[120px] rounded-md border border-dashed border-gray-400 px-2 py-1 mx-1`,
  /// over `bg-blue-100 border-blue-400`; remove `text-red-500`.
  static const chipBorder = TW.blue500;
  static const dropBorder = TW.gray400;
  static const dropOverBg = TW.blue100;
  static const dropOverBorder = TW.blue400;

  /// matching.tsx: list `p-4 bg-gray-50 border-2 border-gray-300 rounded-lg`;
  /// heading chip `px-3.5 py-2 rounded-md font-medium text-sm border`; selected
  /// `bg-blue-600 text-white border-blue-700 ring-2 ring-blue-400`; used
  /// `bg-gray-200 text-gray-400 border-gray-300 line-through opacity-60`;
  /// slot row `p-3.5 border border-gray-200 bg-white rounded-md`; drop slot
  /// `min-h-[44px] w-[380px] p-2 border-2 border-dashed rounded-md`.
  static const matchingSlotWidth = 380.0;

  // ---- Essay (question.tsx essay branch) ------------------------------------------
  /// textarea `min-h-[420px] rounded-lg border-2 border-gray-300 focus:border-indigo-600
  /// p-4 text-[16px] leading-[1.65]`.
  static const essayMinHeight = 420.0;
  static const essayBorder = TW.gray300;
  static const essayFocus = TW.indigo600;

  // ---- Footer (index.tsx + number-bar.tsx) ----------------------------------------
  /// Footer `height: 52px bg-white border-t border-gray-200`.
  static const footerHeight = 52.0;
  static const footerBorder = TW.gray200;

  /// Active part `border-t-3 border-t-blue-600 border-r border-gray-300 px-3 gap-2`,
  /// name `text-sm font-extrabold text-blue-600 uppercase tracking-tight`.
  static const activePartAccent = TW.blue600;

  /// Inactive part `bg-[#f3f4f6] hover:bg-gray-200/80`, name `text-sm font-bold text-gray-500`,
  /// count `text-xs font-semibold text-gray-400 bg-gray-200/80 px-1.5 py-0.5 rounded-[2px]`.
  static const inactivePartBg = Color(0xFFF3F4F6);
  static const inactivePartName = TW.gray500;
  static const inactivePartCount = TW.gray400;
  static const inactivePartCountBg = Color(0xCCE5E7EB);

  /// Number button `px-1.5 py-0.5 text-xs rounded-[2px]`: current `border border-[#2563eb]
  /// text-[#2563eb] font-bold bg-blue-50/50`; answered `font-bold underline text-black`;
  /// unanswered `text-gray-700`; flagged `★ text-orange-500 text-[9px]` at -top-1 -right-1.
  static const numberCurrent = Color(0xFF2563EB);
  static const numberCurrentBg = Color(0x80EFF6FF);
  static const numberUnanswered = TW.gray700;
  static const numberFlag = TW.orange500;

  /// Arrows `w-11 h-[52px]`: prev `bg-gray-600 border-r border-gray-700`, next `bg-black`,
  /// glyphs ◄ ► `text-base font-bold text-white`, disabled `opacity-40`.
  static const arrowWidth = 44.0;
  static const arrowPrev = TW.gray600;
  static const arrowNext = TW.black;

  // ---- Modals --------------------------------------------------------------------
  /// finish-modal.tsx overlay `bg-black/60`; card `rounded-xl max-w-md border-gray-200 shadow-2xl`;
  /// header `px-5 py-4 border-b border-gray-100 bg-gray-50/50`; footer `px-5 py-3.5 bg-gray-50/80`.
  static const modalOverlay = Color(0x99000000);
  static const modalMaxWidth = 448.0;

  /// sound-check.tsx overlay `bg-black/70`, card `rounded-2xl`, header
  /// `bg-gradient-to-r from-blue-600 to-indigo-600 p-6`.
  static const soundOverlay = Color(0xB3000000);
  static const gradientFrom = TW.blue600;
  static const gradientTo = TW.indigo600;

  // ---- Contrast schemes (index.tsx theme-yellow-black / theme-blue-white) ------------
  static const yellowBlackBg = Color(0xFF000000);
  static const yellowBlackText = Color(0xFFFDE047);
  static const yellowBlackMark = Color(0xFF84CC16);
  static const blueWhiteBg = Color(0xFF002B49);
  static const blueWhiteText = Color(0xFFFFFFFF);
  static const blueWhiteMark = Color(0xFFFDE047);

  /// index.tsx `.text-size-large` 1.15rem / 1.6, `.text-size-xlarge` 1.3rem / 1.7.
  static const textScaleLarge = 1.15;
  static const textScaleXLarge = 1.3;

  /// audio-equalizer.tsx: 20 bars `w-[3px] bg-green-500 rounded-t`, `gap-[1px] h-3`.
  static const eqBars = 20;
  static const eqColor = TW.green500;

  /// Small radius `rounded-[2px]`.
  static const r2 = BorderRadius.all(Radius.circular(2));
}

/// Inter text style helper.
TextStyle inter(double size,
        {FontWeight weight = FontWeight.w400,
        Color? color,
        double? height,
        double? letterSpacing,
        FontStyle? style,
        TextDecoration? decoration}) =>
    TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
      decoration: decoration,
    );

/// Tailwind `font-mono` stack (ui-monospace, SFMono, Menlo, Consolas…).
const kMonoFallback = ['Consolas', 'Menlo', 'monospace'];

TextStyle mono(double size, {FontWeight weight = FontWeight.w700, Color? color}) => TextStyle(
      fontFamily: 'Consolas',
      fontFamilyFallback: kMonoFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
