import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Holds the chosen color palette and light/dark mode, and remembers them
/// between launches with SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const _paletteKey = 'selected_palette';
  static const _modeKey = 'theme_mode';

  AppPalette _palette = AppPalette.fresh;
  ThemeMode _mode = ThemeMode.system;

  AppPalette get palette => _palette;
  ThemeMode get mode => _mode;
  Color get seedColor => palettes[_palette]!.seedColor;

  /// Reads the saved choices, if any. Called once when the app starts.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPalette = prefs.getString(_paletteKey);
    final savedMode = prefs.getString(_modeKey);
    _palette = AppPalette.values.firstWhere(
      (p) => p.name == savedPalette,
      orElse: () => AppPalette.fresh,
    );
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> selectPalette(AppPalette palette) async {
    if (palette == _palette) return;
    _palette = palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
  }

  Future<void> selectMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }
}
