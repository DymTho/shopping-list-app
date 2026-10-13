import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../data/grocery_repository.dart';
import '../models/category.dart';
import '../models/grocery_group.dart';
import '../models/grocery_item.dart';

/// What the list screen is currently showing: the loading skeleton, the
/// list itself (or its empty message), or an error with a retry button.
enum LoadStatus { loading, loaded, error }

/// Holds the shopping list in memory and keeps it in sync with the data
/// source. Screens listen to it with `context.watch<GroceryProvider>()`.
class GroceryProvider extends ChangeNotifier {
  GroceryProvider(this._repository);

  final GroceryRepository _repository;

  LoadStatus _status = LoadStatus.loading;
  String _errorMessage = '';
  List<GroceryItem> _items = [];

  String _searchQuery = '';
  Categories? _categoryFilter;

  LoadStatus get status => _status;
  String get errorMessage => _errorMessage;

  /// Every stored item, ignoring search and filter.
  List<GroceryItem> get items => List.unmodifiable(_items);

  // ---- Totals for the summary card (always about the whole list) ----

  int get totalCount => _items.length;
  int get boughtCount => _items.where((item) => item.isBought).length;
  int get toBuyCount => totalCount - boughtCount;

  /// Pieces still to buy (sum of the quantities of items not yet bought).
  int get toBuyPieces => _items
      .where((item) => !item.isBought)
      .fold(0, (sum, item) => sum + item.quantity);

  // ---- Search, filter and grouping ----

  String get searchQuery => _searchQuery;

  /// Categories that currently have at least one item (used for filter chips).
  List<Categories> get availableCategories => [
        for (final category in Categories.values)
          if (_items.any((item) => item.category == category)) category,
      ];

  /// The selected category chip, or null for "All". If the last item of the
  /// selected category is gone, the filter quietly falls back to "All".
  Categories? get categoryFilter =>
      availableCategories.contains(_categoryFilter) ? _categoryFilter : null;

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || categoryFilter != null;

  /// The items that match the search text and the selected category.
  List<GroceryItem> get visibleItems {
    final query = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      final matchesName = item.name.toLowerCase().contains(query);
      final matchesCategory =
          categoryFilter == null || item.category == categoryFilter;
      return matchesName && matchesCategory;
    }).toList();
  }

  /// [visibleItems] split into one group per category (in the order of the
  /// [Categories] enum). Inside a group, bought items sink to the bottom.
  List<GroceryGroup> get groups {
    final visible = visibleItems;
    return [
      for (final category in Categories.values)
        if (visible.any((item) => item.category == category))
          GroceryGroup(category, [
            ...visible.where((i) => i.category == category && !i.isBought),
            ...visible.where((i) => i.category == category && i.isBought),
          ]),
    ];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(Categories? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    notifyListeners();
  }

  // ---- Talking to the data source ----

  /// Loads the stored items. Called on app start and by "Try again".
  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _items = await _repository.fetchItems();
      _status = LoadStatus.loaded;
    } on GroceryRepositoryException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Pull-to-refresh: reloads the items but keeps showing the current list
  /// meanwhile (no skeleton). Throws [GroceryRepositoryException] on failure,
  /// leaving the list as it was.
  Future<void> refresh() async {
    _items = await _repository.fetchItems();
    _status = LoadStatus.loaded;
    notifyListeners();
  }

  /// Stores a new item first, then shows it at the top of the list.
  /// Throws [GroceryRepositoryException] if storing fails, so the form can
  /// stay open and show a message.
  Future<void> addItem({
    required String name,
    required int quantity,
    required Categories category,
  }) async {
    final item = await _repository.addItem(
      name: name,
      quantity: quantity,
      category: category,
    );
    _items.insert(0, item);
    notifyListeners();
  }

  /// Saves the edited fields of an existing item. Like [addItem], it waits for
  /// the data source before changing the list and throws if that fails.
  Future<void> updateItem({
    required GroceryItem original,
    required String name,
    required int quantity,
    required Categories category,
  }) async {
    final index = _items.indexWhere((item) => item.id == original.id);
    if (index == -1) return;

    final updated = _items[index].copyWith(
      name: name,
      quantity: quantity,
      category: category,
    );
    await _repository.updateItem(updated);

    final newIndex = _items.indexWhere((item) => item.id == original.id);
    if (newIndex == -1) return;
    _items[newIndex] = updated;
    notifyListeners();
  }

  /// Ticks an item as bought (or un-ticks it). The change shows instantly and
  /// is sent to the data source afterwards; if that fails, it is undone and
  /// the exception is rethrown so the UI can show a message.
  Future<void> toggleBought(GroceryItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final before = _items[index];
    final after = before.copyWith(isBought: !before.isBought);
    _items[index] = after;
    notifyListeners();
    try {
      await _repository.updateItem(after);
    } on GroceryRepositoryException {
      final current = _items.indexWhere((i) => i.id == item.id);
      if (current != -1) {
        _items[current] = before;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Removes an item right away (so the swipe feels instant) and then tells
  /// the data source. If that fails, the item is put back where it was and
  /// the exception is rethrown so the UI can show a message.
  Future<void> removeItem(GroceryItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final removed = _items.removeAt(index);
    notifyListeners();
    try {
      await _repository.deleteItem(item.id);
    } on GroceryRepositoryException {
      // Wait until the frame that removed the row has been drawn. A very fast
      // failure (e.g. no internet) would otherwise put the row back before the
      // list ever lost it, which a swiped-away Dismissible does not allow.
      await SchedulerBinding.instance.endOfFrame;
      _items.insert(min(index, _items.length), removed);
      notifyListeners();
      rethrow;
    }
  }
}
