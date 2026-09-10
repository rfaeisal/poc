import 'package:flutter/material.dart';

class HyteraTheme {
  HyteraTheme._();

  // ── Design tokens ──
  static const background = Color(0xFF0B0F1A);
  static const panel = Color(0xFF0F1420);
  static const panel2 = Color(0xFF131A2A);
  static const line = Color(0xFF212B3D);
  static const lineSoft = Color(0xFF1A2233);
  static const text = Color(0xFFDBE4F0);
  static const textDim = Color(0xFF8B9BB4);
  static const textFaint = Color(0xFF516079);
  static const rxGreen = Color(0xFF4ADE80);
  static const txRed = Color(0xFFEF4444);
  static const activeBlue = Color(0xFF4A9EFF);
  static const warning = Color(0xFFFBBF24);
  static const appBarBg = Color(0xFF060910);
  static const dividerColor = Color(0xFF0F1E2E);

  static const _mono = 'monospace';

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: activeBlue,
          secondary: rxGreen,
          error: txRed,
          surface: panel,
          onSurface: text,
          onPrimary: Color(0xFF04101F),
          onSecondary: Color(0xFF04101F),
          onError: Colors.white,
          tertiary: warning,
        ),
        fontFamily: _mono,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: _mono, fontSize: 20, fontWeight: FontWeight.w700, color: text),
          displayMedium: TextStyle(fontFamily: _mono, fontSize: 18, fontWeight: FontWeight.w700, color: text),
          headlineLarge: TextStyle(fontFamily: _mono, fontSize: 17, fontWeight: FontWeight.w700, color: text),
          headlineMedium: TextStyle(fontFamily: _mono, fontSize: 16, fontWeight: FontWeight.w700, color: text),
          headlineSmall: TextStyle(fontFamily: _mono, fontSize: 15, fontWeight: FontWeight.w600, color: text),
          titleLarge: TextStyle(fontFamily: _mono, fontSize: 14, fontWeight: FontWeight.w600, color: text),
          titleMedium: TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: FontWeight.w600, color: text),
          titleSmall: TextStyle(fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w600, color: text),
          bodyLarge: TextStyle(fontFamily: _mono, fontSize: 12, color: textDim),
          bodyMedium: TextStyle(fontFamily: _mono, fontSize: 11, color: textDim),
          bodySmall: TextStyle(fontFamily: _mono, fontSize: 10, color: textFaint),
          labelLarge: TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w700, color: text, letterSpacing: 0.5),
          labelMedium: TextStyle(fontFamily: _mono, fontSize: 9, fontWeight: FontWeight.w600, color: textDim, letterSpacing: 0.5),
          labelSmall: TextStyle(fontFamily: _mono, fontSize: 8, fontWeight: FontWeight.w500, color: textFaint, letterSpacing: 0.5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarBg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: _mono,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: activeBlue,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: activeBlue, size: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: activeBlue, width: 1.5),
          ),
          labelStyle: const TextStyle(fontFamily: _mono, fontSize: 8, color: textFaint, letterSpacing: 0.5),
          hintStyle: const TextStyle(fontFamily: _mono, fontSize: 9, color: textFaint),
          isDense: true,
        ),
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: line),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: dividerColor,
          thickness: 1,
          space: 0,
        ),
        iconTheme: const IconThemeData(color: textDim, size: 14),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E4A8A),
            foregroundColor: text,
            textStyle: const TextStyle(fontFamily: _mono, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            minimumSize: const Size(double.infinity, 32),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: activeBlue,
            textStyle: const TextStyle(fontFamily: _mono, fontSize: 8, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? rxGreen : textFaint),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? const Color(0xFF0F6E56)
                  : const Color(0xFF0F2040)),
          trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF1E3A5F)),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: activeBlue,
          inactiveTrackColor: Color(0xFF0F2040),
          thumbColor: activeBlue,
          overlayColor: Color(0x224A9EFF),
          trackHeight: 2,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: panel2,
          contentTextStyle: TextStyle(fontFamily: _mono, fontSize: 10, color: text),
        ),
      );
}
