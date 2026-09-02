import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';
import 'data/items_provider.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            builder: (context, child) => AnimatedTheme(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              data: themeProvider.themeData,
              child: child!,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
