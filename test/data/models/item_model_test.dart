import 'package:flutter_test/flutter_test.dart';
import 'package:skip/data/models/item_model.dart';

void main() {
  group('ItemModel', () {
    final createdAt = DateTime.utc(2026, 1, 15, 12, 30);

    test('toMap/fromMap round trip preserves all fields', () {
      final item = ItemModel(
        id: 7,
        title: 'Vintage Jacket',
        price: 129.99,
        imagePath: 'skip_images/123.jpg',
        isSaved: true,
        category: 'Clothing',
        createdAt: createdAt,
      );

      final restored = ItemModel.fromMap(item.toMap());

      expect(restored, item);
    });

    test('toMap encodes isSaved as 1/0', () {
      final saved = ItemModel(
        price: 10,
        imagePath: 'x.jpg',
        isSaved: true,
        createdAt: createdAt,
      );
      final spent = saved.copyWith(isSaved: false);

      expect(saved.toMap()['is_saved'], 1);
      expect(spent.toMap()['is_saved'], 0);
    });

    test('toMap omits id when null (for insert)', () {
      final item = ItemModel(
        price: 10,
        imagePath: 'x.jpg',
        isSaved: false,
        createdAt: createdAt,
      );

      expect(item.toMap().containsKey('id'), isFalse);
    });

    test('fromMap handles nullable title and category', () {
      final map = {
        'id': 1,
        'title': null,
        'price': 5.5,
        'image_path': 'a.jpg',
        'is_saved': 0,
        'category': null,
        'created_at': createdAt.toIso8601String(),
      };

      final item = ItemModel.fromMap(map);

      expect(item.title, isNull);
      expect(item.category, isNull);
      expect(item.isSaved, isFalse);
    });

    test('fromMap coerces integer price to double', () {
      final map = {
        'id': 1,
        'title': 'Item',
        'price': 10,
        'image_path': 'a.jpg',
        'is_saved': 1,
        'category': null,
        'created_at': createdAt.toIso8601String(),
      };

      final item = ItemModel.fromMap(map);

      expect(item.price, 10.0);
      expect(item.price, isA<double>());
    });

    test('copyWith overrides only the given fields', () {
      final item = ItemModel(
        id: 1,
        title: 'Original',
        price: 10,
        imagePath: 'a.jpg',
        isSaved: true,
        createdAt: createdAt,
      );

      final updated = item.copyWith(price: 20, isSaved: false);

      expect(updated.price, 20);
      expect(updated.isSaved, isFalse);
      expect(updated.title, 'Original');
      expect(updated.id, 1);
    });
  });
}
