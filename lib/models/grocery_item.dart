import 'category.dart';

/// One entry in the shopping list. [id] is assigned by the data source
/// (the server or the mock), so a brand-new item only gets one after it
/// has been stored.
class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.isBought = false,
  });

  final String id;
  final String name;
  final int quantity;
  final Categories category;

  /// True once the item was put in the cart (crossed out, moved down).
  final bool isBought;

  /// Items are immutable, so "changing" one means making a changed copy.
  GroceryItem copyWith({
    String? name,
    int? quantity,
    Categories? category,
    bool? isBought,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isBought: isBought ?? this.isBought,
    );
  }
}
