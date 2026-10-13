import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The selectable color palettes. Each one is just a seed color: Material 3
/// derives every other color (buttons, containers, text) from it.
enum AppPalette { fresh, ocean, berry, sunset }

class PalettePreset {
  const PalettePreset(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}

const Map<AppPalette, PalettePreset> palettes = {
  AppPalette.fresh: PalettePreset('Fresh', Color(0xFF1FA67A)),
  AppPalette.ocean: PalettePreset('Ocean', Color(0xFF1E88E5)),
  AppPalette.berry: PalettePreset('Berry', Color(0xFFC2185B)),
  AppPalette.sunset: PalettePreset('Sunset', Color(0xFFF57C00)),
};

/// Builds the whole Material 3 theme from one seed color so every screen
/// (buttons, inputs, cards, app bar) stays consistent. Two Google Fonts: Sora
/// for titles, Plus Jakarta Sans for everything else.
ThemeData buildAppTheme(Color seedColor, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
  final bodyText = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  final textTheme = bodyText.copyWith(
    headlineSmall: GoogleFonts.sora(
      textStyle: bodyText.headlineSmall,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.sora(
      textStyle: bodyText.titleLarge,
      fontWeight: FontWeight.w700,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: colorScheme.outlineVariant),
      showCheckmark: false,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
