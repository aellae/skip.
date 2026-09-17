// Dev-only entry point — never shipped in the app bundle.
//
// Seeds the local database with sample "temptation" items so a fresh
// simulator install has realistic content to screenshot for the App Store /
// Play listing, then launches the real app. Every run wipes whatever items
// are currently in the database (and their image files) and reinserts
// exactly _demoItems fresh — simplest way to keep the dataset reproducible
// while it's still being tuned, and safe because this only ever targets a
// disposable screenshot simulator, never a real user's data.
//
// Source images must be staged at /tmp/skip_demo_images/ first (copy them
// from tool/demo_images/) — NOT read directly from the repo, because the
// repo lives under ~/Desktop and the source images sit there too; on this
// Mac, files dropped under ~/Desktop get silently renamed by a local
// automation shortly after they appear, so a hardcoded filename pointing
// into the repo can go stale between when this file is written and when it
// runs. /tmp is unaffected and stable for the duration of a shell session.
//
// Usage:
//   cp tool/demo_images/*.jpg /tmp/skip_demo_images/
//   flutter run -t tool/seed_demo_data.dart -d <device> \
//     --dart-define=SKIP_DEMO_THEME=minimal \    # or y2k
//     --dart-define=SKIP_DEMO_SCREEN=home \      # or insights
//     --dart-define=SKIP_DEMO_LOCALE=en          # or it
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:skip/core/localization/app_currency.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/currency_provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/models/item_model.dart';
import 'package:skip/features/insights/insights_screen.dart';
import 'package:skip/main.dart';

const _themeArg = String.fromEnvironment(
  'SKIP_DEMO_THEME',
  defaultValue: 'minimal',
);

// When set to 'insights', auto-navigates to InsightsScreen shortly after
// launch — there's no tap-driven UI automation available for this
// simulator, so this is the only way to screenshot a screen other than Home.
const _screenArg = String.fromEnvironment('SKIP_DEMO_SCREEN', defaultValue: 'home');

// Currency follows locale here the same way main.dart defaults it on a
// fresh install (EUR for Italian, USD for English) so the seeded amounts
// read naturally in either screenshot set.
const _localeArg = String.fromEnvironment('SKIP_DEMO_LOCALE', defaultValue: 'en');

final _navigatorKey = GlobalKey<NavigatorState>();

const _stagedImagesDir = '/tmp/skip_demo_images';

class _DemoItem {
  final String fileName;
  final String title;
  final double price;
  final String category;
  final bool isSaved;
  final int daysAgo;

  const _DemoItem({
    required this.fileName,
    required this.title,
    required this.price,
    required this.category,
    required this.isSaved,
    required this.daysAgo,
  });
}

const _demoItems = [
  _DemoItem(
    fileName: 'car.jpg',
    title: 'Ferrari Experience Day',
    price: 249.00,
    category: 'Experiences',
    isSaved: true,
    daysAgo: 2,
  ),
  _DemoItem(
    fileName: 'straberry.jpg',
    title: 'Chocolate Strawberry Cups',
    price: 12.99,
    category: 'Treats',
    isSaved: false,
    daysAgo: 4,
  ),
  _DemoItem(
    fileName: 'cat.jpg',
    title: 'Should I Adopt Her?',
    price: 150.0,
    category: 'Pets',
    isSaved: true,
    daysAgo: 6,
  ),
  _DemoItem(
    fileName: 'orchid.jpg',
    title: 'LEGO Orchid Set',
    price: 59.99,
    category: 'Home Decor',
    isSaved: false,
    daysAgo: 9,
  ),
  _DemoItem(
    fileName: 'socks.jpg',
    title: 'Fuzzy Fruit Socks 4-Pack',
    price: 18.00,
    category: 'Clothing',
    isSaved: true,
    daysAgo: 12,
  ),
  _DemoItem(
    fileName: 'camera.jpg',
    title: 'Vintage Pink Cybershot',
    price: 85.00,
    category: 'Tech',
    isSaved: false,
    daysAgo: 15,
  ),
  _DemoItem(
    fileName: 'annaffiatoio.jpg',
    title: 'Cute Watering Can',
    price: 24.00,
    category: 'Home',
    isSaved: true,
    daysAgo: 20,
  ),
  _DemoItem(
    fileName: 'toothbrush.jpg',
    title: 'Miffy Electric Toothbrush',
    price: 45.00,
    category: 'Self Care',
    isSaved: false,
    daysAgo: 25,
  ),
  _DemoItem(
    fileName: 'jumpsuit.jpg',
    title: 'Lululemon Define Jacket',
    price: 138.00,
    category: 'Clothing',
    isSaved: true,
    daysAgo: 30,
  ),
  _DemoItem(
    fileName: 'needoh.jpg',
    title: 'NeeDoh Squish Cubes',
    price: 9.99,
    category: 'Fidget Toys',
    isSaved: false,
    daysAgo: 34,
  ),
  // Older items, reusing the same 10 photos, so the Insights 6-month chart
  // has activity in every month instead of just the last two. Amounts are
  // kept in the same rough order of magnitude as each other (roughly
  // $10-$250, gently rising toward the present) rather than wildly uneven,
  // so the monthly bar chart reads as a coherent trend instead of one huge
  // bar dwarfing five empty-looking ones.
  _DemoItem(
    fileName: 'toothbrush.jpg',
    title: 'Electric Toothbrush Upgrade',
    price: 32.00,
    category: 'Self Care',
    isSaved: false,
    daysAgo: 65,
  ),
  _DemoItem(
    fileName: 'orchid.jpg',
    title: 'Plant Shop Temptation',
    price: 38.00,
    category: 'Home Decor',
    isSaved: true,
    daysAgo: 60,
  ),
  _DemoItem(
    fileName: 'straberry.jpg',
    title: 'Farmers Market Treat',
    price: 9.00,
    category: 'Treats',
    isSaved: false,
    daysAgo: 92,
  ),
  _DemoItem(
    fileName: 'jumpsuit.jpg',
    title: 'Another Lululemon Piece',
    price: 95.00,
    category: 'Clothing',
    isSaved: true,
    daysAgo: 105,
  ),
  _DemoItem(
    fileName: 'needoh.jpg',
    title: 'Stress Ball Restock',
    price: 12.00,
    category: 'Fidget Toys',
    isSaved: false,
    daysAgo: 122,
  ),
  _DemoItem(
    fileName: 'annaffiatoio.jpg',
    title: 'Garden Center Run',
    price: 30.00,
    category: 'Home',
    isSaved: true,
    daysAgo: 135,
  ),
  _DemoItem(
    fileName: 'socks.jpg',
    title: 'More Cozy Socks',
    price: 16.00,
    category: 'Clothing',
    isSaved: false,
    daysAgo: 150,
  ),
  _DemoItem(
    fileName: 'camera.jpg',
    title: 'Camera Shop Browsing',
    price: 42.00,
    category: 'Tech',
    isSaved: true,
    daysAgo: 160,
  ),
];

Future<void> _reseed() async {
  final db = DatabaseHelper.instance;
  final fileHelper = FileHelper();

  final everything = [...await db.getAllItems(), ...await db.getTrashedItems()];
  final rawDb = await db.database;
  await rawDb.delete(DatabaseHelper.tableItems);
  for (final item in everything) {
    if (item.imagePath != null) {
      await fileHelper.deleteImage(item.imagePath!);
    }
  }

  final now = DateTime.now();
  for (final demo in _demoItems) {
    final source = File(p.join(_stagedImagesDir, demo.fileName));
    if (!source.existsSync()) continue;
    final relativePath = await fileHelper.saveImage(source);
    await db.insertItem(
      ItemModel(
        title: demo.title,
        price: demo.price,
        imagePath: relativePath,
        isSaved: demo.isSaved,
        category: demo.category,
        createdAt: now.subtract(Duration(days: demo.daysAgo)),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _reseed();

  final locale = _localeArg == 'it' ? AppLocale.it : AppLocale.en;
  runApp(
    SkipApp(
      themeProviderOverride: ThemeProvider(
        initial: _themeArg == 'y2k'
            ? SkipAesthetic.y2k
            : SkipAesthetic.minimal,
      ),
      localeProviderOverride: LocaleProvider(initial: locale),
      currencyProviderOverride: CurrencyProvider(
        initial: locale == AppLocale.it ? AppCurrency.eur : AppCurrency.usd,
      ),
      navigatorKeyOverride: _navigatorKey,
    ),
  );

  if (_screenArg == 'insights') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const InsightsScreen()),
      );
    });
  }
}
