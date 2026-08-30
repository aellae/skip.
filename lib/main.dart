import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';
import 'data/items_provider.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // SKIP is 100% offline. google_fonts fetches fonts over HTTP by default on
  // first use; disabling runtime fetching forces it to resolve fonts from
  // the bundled assets declared in pubspec.yaml instead, so there is never
  // a network call, even on the very first run.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const SkipApp());
}

class SkipApp extends StatelessWidget {
  /// Overridable only by tests, so a widget test can supply a ThemeProvider
  /// / ItemsProvider backed by fakes instead of the real platform channels.
  final ThemeProvider? themeProviderOverride;
  final ItemsProvider? itemsProviderOverride;

  const SkipApp({
    super.key,
    this.themeProviderOverride,
    this.itemsProviderOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => themeProviderOverride ?? ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => itemsProviderOverride ?? ItemsProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SKIP',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
