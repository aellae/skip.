import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../data/items_provider.dart';
import '../item_entry/item_entry_screen.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(skipTheme.logoText)),
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
                            'Nothing logged yet.\nTap + to snap something you\'re tempted to buy.',
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
                          return ItemGridCard(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => ItemDetailScreen(item: item),
                                ),
                              );
                            },
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
