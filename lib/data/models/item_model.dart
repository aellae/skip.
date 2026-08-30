/// A single logged item: something the user either resisted buying
/// (saved) or bought (spent).
class ItemModel {
  final int? id;
  final String? title;
  final double price;
  final String imagePath;
  final bool isSaved;
  final String? category;
  final DateTime createdAt;

  const ItemModel({
    this.id,
    this.title,
    required this.price,
    required this.imagePath,
    required this.isSaved,
    this.category,
    required this.createdAt,
  });

  ItemModel copyWith({
    int? id,
    String? title,
    double? price,
    String? imagePath,
    bool? isSaved,
    String? category,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      isSaved: isSaved ?? this.isSaved,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'image_path': imagePath,
      'is_saved': isSaved ? 1 : 0,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      id: map['id'] as int?,
      title: map['title'] as String?,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String,
      isSaved: (map['is_saved'] as int) == 1,
      category: map['category'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemModel &&
        other.id == id &&
        other.title == title &&
        other.price == price &&
        other.imagePath == imagePath &&
        other.isSaved == isSaved &&
        other.category == category &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, price, imagePath, isSaved, category, createdAt);

  @override
  String toString() =>
      'ItemModel(id: $id, title: $title, price: $price, isSaved: $isSaved, category: $category)';
}
