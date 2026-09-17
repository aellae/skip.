/// A single logged item: something the user resisted buying (saved),
/// bought (spent), or hasn't decided on yet (pondering — [isSaved] is
/// `null`).
class ItemModel {
  final int? id;
  final String? title;
  final double price;
  final String imagePath;
  final bool? isSaved;
  final String? category;
  final DateTime createdAt;
  final String? purchaseUrl;
  final DateTime? deletedAt;

  const ItemModel({
    this.id,
    this.title,
    required this.price,
    required this.imagePath,
    required this.isSaved,
    this.category,
    required this.createdAt,
    this.purchaseUrl,
    this.deletedAt,
  });

  /// Whether this item is still undecided (neither Resisted nor Bought).
  bool get isPondering => isSaved == null;

  ItemModel copyWith({
    int? id,
    String? title,
    double? price,
    String? imagePath,
    bool? isSaved,
    bool clearIsSaved = false,
    String? category,
    DateTime? createdAt,
    String? purchaseUrl,
    DateTime? deletedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      isSaved: clearIsSaved ? null : (isSaved ?? this.isSaved),
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      purchaseUrl: purchaseUrl ?? this.purchaseUrl,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'image_path': imagePath,
      'is_saved': isSaved == null ? null : (isSaved! ? 1 : 0),
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'purchase_url': purchaseUrl,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      id: map['id'] as int?,
      title: map['title'] as String?,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String,
      isSaved: map['is_saved'] == null ? null : (map['is_saved'] as int) == 1,
      category: map['category'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      purchaseUrl: map['purchase_url'] as String?,
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
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
        other.createdAt == createdAt &&
        other.purchaseUrl == purchaseUrl &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    price,
    imagePath,
    isSaved,
    category,
    createdAt,
    purchaseUrl,
    deletedAt,
  );

  @override
  String toString() =>
      'ItemModel(id: $id, title: $title, price: $price, isSaved: $isSaved, category: $category)';
}
