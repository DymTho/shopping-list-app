import '../models/category.dart';
import '../models/grocery_item.dart';

/// Thrown when the data source can't be reached or answers with an error.
/// The message is safe to show to the user.
class GroceryRepositoryException implements Exception {
  const GroceryRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything the app needs from a data source. The UI and the provider only
/// know this interface, so the mock and the real HTTP backend can be swapped
/// without touching any screen.
abstract class GroceryRepository {
  /// Loads all stored items, newest first.
  Future<List<GroceryItem>> fetchItems();

  /// Stores a new item and returns it together with its new id.
  Future<GroceryItem> addItem({
    required String name,
    required int quantity,
    required Categories category,
  });

  /// Overwrites the stored item that has the same id (an HTTP PATCH).
  /// Used for editing an item and for ticking it as bought.
  Future<void> updateItem(GroceryItem item);

  Future<void> deleteItem(String id);
}
