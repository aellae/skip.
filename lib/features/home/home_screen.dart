import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../data/items_provider.dart';
import '../insights/insights_screen.dart';
import '../item_entry/item_entry_screen.dart';
import '../settings/settings_screen.dart';
import 'item_detail_screen.dart';
import 'widgets/item_grid_card.dart';
import 'widgets/summary_cards.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final itemsProvider = context.watch<ItemsProvider>();
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      appBar: SkipAppBar(
        title: Text(skipTheme.logoText),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const InsightsScreen()));
            },
            icon: const Icon(Icons.insights_outlined),
            tooltip: strings.insightsTooltip,
          ),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: strings.settingsTooltip,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => itemsProvider.load(),
        child: itemsProvider.isLoading && itemsProvider.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: SummaryCards(
                        totalSaved: itemsProvider.totalSaved,
                        totalSpent: itemsProvider.totalSpent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InsightsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (itemsProvider.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            strings.emptyHomeMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: itemsProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = itemsProvider.items[index];
                          return _GridEntranceFade(
                            key: ValueKey(item.id ?? item.imagePath),
                            child: ItemGridCard(
                              item: item,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const ItemEntryScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

/// Fades and scales a freshly-mounted grid card in, once, on first build.
///
/// Relies on the caller giving each card a stable [Key] (the item's id/image
/// path) — without one, Flutter would reuse Elements by list position and
/// this animation could replay on an unrelated reorder, or skip a genuine
/// insert.
class _GridEntranceFade extends StatefulWidget {
  final Widget child;

  const _GridEntranceFade({super.key, required this.child});

  @override
  State<_GridEntranceFade> createState() => _GridEntranceFadeState();
}

class _GridEntranceFadeState extends State<_GridEntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
