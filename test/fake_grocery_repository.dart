import 'package:shopping_list/data/grocery_repository.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

/// An in-memory repository for tests: no delay, and it can be told to fail so
/// the error handling can be tested.
class FakeGroceryRepository implements GroceryRepository {
  FakeGroceryRepository({List<GroceryItem>? items})
      : items = items ?? <GroceryItem>[];

  final List<GroceryItem> items;
  final List<String> deletedIds = [];

  int fetchCount = 0;

  /// Number of upcoming fetches that should fail before one succeeds.
  int failingFetches = 0;
  bool failDelete = false;
  bool failAdd = false;
  bool failUpdate = false;

  GroceryRepositoryException get _error =>
      const GroceryRepositoryException('Could not reach the server.');

  @override
  Future<List<GroceryItem>> fetchItems() async {
    fetchCount++;
    if (failingFetches > 0) {
      failingFetches--;
      throw _error;
    }
    return List.of(items);
  }

  @override
  Future<GroceryItem> addItem({
    required String name,
    required int quantity,
    required Categories category,
  }) async {
    if (failAdd) throw _error;
    final item = GroceryItem(
      id: 'new-${items.length}',
      name: name,
      quantity: quantity,
      category: category,
    );
    items.insert(0, item);
    return item;
  }

  @override
  Future<void> updateItem(GroceryItem item) async {
    if (failUpdate) throw _error;
    final index = items.indexWhere((stored) => stored.id == item.id);
    if (index != -1) items[index] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    if (failDelete) throw _error;
    deletedIds.add(id);
    items.removeWhere((item) => item.id == id);
  }
}
