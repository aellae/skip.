import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';

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
  const SkipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SKIP',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const _Phase1PreviewScreen(),
          );
        },
      ),
    );
  }
}

/// Temporary Phase 1 verification screen.
///
/// Exists only to prove the theme engine, typography, and font bundling
/// work end-to-end (including live theme switching) before Phase 2 replaces
/// this with the real home dashboard.
class _Phase1PreviewScreen extends StatelessWidget {
  const _Phase1PreviewScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.watch<ThemeProvider>().isY2K ? 'SKIP!' : 'skip.',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Phase 1 architecture preview',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.read<ThemeProvider>().toggle(),
                child: const Text('Switch aesthetic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
