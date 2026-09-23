import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../data/items_provider.dart';
import '../coin_flip/coin_flip_screen.dart';
import '../insights/insights_screen.dart';
import '../item_entry/item_entry_screen.dart';
import '../settings/settings_screen.dart';
import 'item_detail_screen.dart';
import 'widgets/home_loading_skeleton.dart';
import 'widgets/home_motto.dart';
import 'widgets/item_grid_card.dart';
import 'widgets/summary_cards.dart';

class HomeScreen extends StatefulWidget {
  /// Injectable for tests; only used to recover a photo lost to process
  /// death (see [_recoverLostPhoto]).
  final ImagePicker? imagePicker;

  const HomeScreen({super.key, this.imagePicker});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ItemsProvider>();
      await provider.load();
      await provider.purgeExpiredTrash();
      await _recoverLostPhoto();
    });
  }

  /// Android can kill the app while the camera/gallery is in front; the
  /// picked photo then comes back on the next cold start instead of to the
  /// entry form. Reopen the form with that photo attached so it isn't lost.
  /// Runs after the purges so the recovered copy can't be swept as orphaned.
  Future<void> _recoverLostPhoto() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final LostDataResponse response;
    try {
      response = await (widget.imagePicker ?? ImagePicker()).retrieveLostData();
    } catch (_) {
      return;
    }
    final file = response.file;
    if (response.isEmpty || file == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ItemEntryScreen(recoveredImage: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final itemsProvider = context.watch<ItemsProvider>();
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      appBar: SkipAppBar(
        toolbarHeight: 72,
        title: Image.asset(
          skipTheme.logoAsset,
          height: skipTheme.isY2K ? 60 : 52,
          fit: BoxFit.contain,
          semanticLabel: skipTheme.logoText,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CoinFlipScreen()));
            },
            icon: const Icon(Icons.monetization_on_outlined),
            tooltip: strings.coinFlipTooltip,
          ),
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
      // Horizontal insets only: keeps cards clear of a landscape camera
      // cutout while the grid still scrolls under the system bars.
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => itemsProvider.load(),
          child: itemsProvider.isLoading && itemsProvider.items.isEmpty
              ? const HomeLoadingSkeleton()
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
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
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      sliver: SliverToBoxAdapter(child: HomeMotto()),
                    ),
                    if (itemsProvider.items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: EmptyState(
                            icon: skipTheme.isY2K
                                ? Icons.auto_awesome_rounded
                                : Icons.savings_outlined,
                            message: strings.emptyHomeMessage,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childCount: itemsProvider.items.length,
                          itemBuilder: (context, index) {
                            final item = itemsProvider.items[index];
                            return EntranceFade(
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
        child: Icon(Icons.add_a_photo, semanticLabel: strings.logAnItem),
      ),
    );
  }
}
