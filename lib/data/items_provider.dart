import 'package:flutter/foundation.dart';

import 'database_helper.dart';
import 'models/item_model.dart';

/// Single reactive source of truth for items, shared across the home
/// dashboard, item entry, and item detail screens via [Provider].
///
/// Wraps [DatabaseHelper] and keeps an in-memory copy of the item list plus
/// the running saved/spent totals, so every screen reads consistent data
/// and only re-fetches from SQLite when something actually changed.
class ItemsProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  ItemsProvider({DatabaseHelper? databaseHelper})
    : _db = databaseHelper ?? DatabaseHelper.instance;

  List<ItemModel> _items = [];
  double _totalSaved = 0;
  double _totalSpent = 0;
  bool _isLoading = false;

  List<ItemModel> get items => List.unmodifiable(_items);
  double get totalSaved => _totalSaved;
  double get totalSpent => _totalSpent;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _items = await _db.getAllItems();
    _totalSaved = await _db.getTotalSaved();
    _totalSpent = await _db.getTotalSpent();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem({
    String? title,
    required double price,
    required String imagePath,
    required bool isSaved,
    String? category,
  }) async {
    await _db.insertItem(
      ItemModel(
        title: title,
        price: price,
        imagePath: imagePath,
        isSaved: isSaved,
        category: category,
        createdAt: DateTime.now(),
      ),
    );
    await load();
  }

  Future<void> setSavedStatus(int id, bool isSaved) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    await _db.updateItem(_items[index].copyWith(isSaved: isSaved));
    await load();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await load();
  }
}
