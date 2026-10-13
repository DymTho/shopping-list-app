import 'category.dart';
import 'grocery_item.dart';

/// The items of one category, as shown under one colored section header.
class GroceryGroup {
  const GroceryGroup(this.category, this.items);

  final Categories category;
  final List<GroceryItem> items;
}
