import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/providers/grocery_provider.dart';

import 'fake_grocery_repository.dart';

GroceryItem _item(
  String id,
  String name,
  Categories category, {
  int quantity = 1,
  bool isBought = false,
}) =>
    GroceryItem(
      id: id,
      name: name,
      quantity: quantity,
      category: category,
      isBought: isBought,
    );

Future<GroceryProvider> _loaded(List<GroceryItem> items) async {
  final provider = GroceryProvider(FakeGroceryRepository(items: items));
  await provider.load();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('counts what is left to buy and what is in the cart', () async {
    final provider = await _loaded([
      _item('1', 'Milk', Categories.dairy, quantity: 3),
      _item('2', 'Bread', Categories.carbs, quantity: 2, isBought: true),
      _item('3', 'Apples', Categories.fruit, quantity: 5),
    ]);

    expect(provider.totalCount, 3);
    expect(provider.boughtCount, 1);
    expect(provider.toBuyCount, 2);
    expect(provider.toBuyPieces, 8);
  });

  test('groups by category in enum order, bought items at the bottom', () async {
    final provider = await _loaded([
      _item('1', 'Milk', Categories.dairy),
      _item('2', 'Cucumber', Categories.vegetables, isBought: true),
      _item('3', 'Carrot', Categories.vegetables),
    ]);

    final groups = provider.groups;
    expect(groups.map((g) => g.category), [Categories.vegetables, Categories.dairy]);
    expect(groups.first.items.map((i) => i.name), ['Carrot', 'Cucumber']);
  });

  test('search ignores case and surrounding spaces', () async {
    final provider = await _loaded([
      _item('1', 'Milk', Categories.dairy),
      _item('2', 'Cucumber', Categories.vegetables),
    ]);

    provider.setSearchQuery('  MIL ');
    expect(provider.visibleItems.map((i) => i.name), ['Milk']);
    expect(provider.hasActiveFilters, isTrue);

    provider.clearFilters();
    expect(provider.visibleItems, hasLength(2));
    expect(provider.hasActiveFilters, isFalse);
  });

  test('category filter keeps only that category', () async {
    final provider = await _loaded([
      _item('1', 'Milk', Categories.dairy),
      _item('2', 'Cucumber', Categories.vegetables),
    ]);

    provider.setCategoryFilter(Categories.dairy);
    expect(provider.visibleItems.map((i) => i.name), ['Milk']);
    expect(provider.availableCategories, [Categories.vegetables, Categories.dairy]);
  });

  test('the category filter falls back to "All" when its last item is removed',
      () async {
    final milk = _item('1', 'Milk', Categories.dairy);
    final provider = await _loaded([milk, _item('2', 'Cucumber', Categories.vegetables)]);

    provider.setCategoryFilter(Categories.dairy);
    await provider.removeItem(milk);

    expect(provider.categoryFilter, isNull);
    expect(provider.visibleItems.map((i) => i.name), ['Cucumber']);
  });

  test('toggleBought flips the flag and stores it', () async {
    final repo = FakeGroceryRepository(items: [_item('1', 'Milk', Categories.dairy)]);
    final provider = GroceryProvider(repo);
    await provider.load();

    await provider.toggleBought(provider.items.first);

    expect(provider.items.first.isBought, isTrue);
    expect(repo.items.first.isBought, isTrue);
  });

  test('toggleBought is undone when the data source fails', () async {
    final repo = FakeGroceryRepository(items: [_item('1', 'Milk', Categories.dairy)])
      ..failUpdate = true;
    final provider = GroceryProvider(repo);
    await provider.load();

    await expectLater(
      provider.toggleBought(provider.items.first),
      throwsA(anything),
    );
    expect(provider.items.first.isBought, isFalse);
  });
}
