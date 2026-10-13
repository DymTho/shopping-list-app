import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'data/backend_config.dart';
import 'data/grocery_repository.dart';
import 'providers/grocery_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/grocery_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _preloadFonts();
  runApp(ShoppingListApp(repository: createGroceryRepository()));
}

/// Google Fonts are downloaded the first time they are used. If the first
/// frame is drawn before that finishes, text is measured with a fallback font
/// and widgets sized to their text (like the filter chips) come out too narrow.
/// So we wait for the fonts first, but never longer than a few seconds, so the
/// app still starts when the phone is offline.
Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.sora(fontWeight: FontWeight.w700),
    ]).timeout(const Duration(seconds: 4));
  } catch (_) {
    // Offline or slow: carry on with the fallback font.
  }
}

/// Root widget. Creates the two providers once (each starts loading its data
/// right away) so every screen below can read them.
class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({super.key, required this.repository});

  /// Where the list is stored. Passed in so tests can use a fake one.
  final GroceryRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroceryProvider(repository)..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      // Only the MaterialApp rebuilds when the palette or mode changes.
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Shopping List',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(theme.seedColor, Brightness.light),
          darkTheme: buildAppTheme(theme.seedColor, Brightness.dark),
          themeMode: theme.mode,
          home: const GroceryListScreen(),
        ),
      ),
    );
  }
}
