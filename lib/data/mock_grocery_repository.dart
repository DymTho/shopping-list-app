import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/grocery_item.dart';
import 'grocery_repository.dart';

/// A fake "remote" data source used until a real backend URL is available.
/// It behaves like a server (async calls with a small delay) but stores the
/// list on the device with SharedPreferences, so data survives app restarts.
class MockGroceryRepository implements GroceryRepository {
  MockGroceryRepository({this.latency = const Duration(milliseconds: 900)});

  static const _storageKey = 'mock_remote_grocery_items';

  /// Simulated network delay, so the loading skeleton is visible.
  final Duration latency;

  /// Shown on the very first launch, before anything was stored.
  static const _seedItems = [
    {'id': 's1', 'name': 'Milk', 'quantity': 3, 'category': 'dairy'},
    {'id': 's2', 'name': 'Cucumber', 'quantity': 1, 'category': 'vegetables'},
    {'id': 's3', 'name': 'Bananas', 'quantity': 6, 'category': 'fruit'},
    {'id': 's4', 'name': 'Pasta', 'quantity': 2, 'category': 'carbs'},
    {'id': 's5', 'name': 'Chicken breast', 'quantity': 2, 'category': 'meat'},
    {'id': 's6', 'name': 'Toothpaste', 'quantity': 1, 'category': 'hygiene'},
  ];

  @override
  Future<List<GroceryItem>> fetchItems() async {
    await Future<void>.delayed(latency);
    return (await _readRaw()).map(_fromMap).toList();
  }

  @override
  Future<GroceryItem> addItem({
    required String name,
    required int quantity,
    required Categories category,
  }) async {
    await Future<void>.delayed(latency ~/ 2);
    final raw = await _readRaw();
    final item = GroceryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      category: category,
    );
    await _writeRaw([_toMap(item), ...raw]);
    return item;
  }

  @override
  Future<void> updateItem(GroceryItem item) async {
    await Future<void>.delayed(latency ~/ 2);
    final raw = await _readRaw();
    await _writeRaw([
      for (final stored in raw) stored['id'] == item.id ? _toMap(item) : stored,
    ]);
  }

  @override
  Future<void> deleteItem(String id) async {
    await Future<void>.delayed(latency ~/ 2);
    final raw = await _readRaw();
    await _writeRaw(raw.where((item) => item['id'] != id).toList());
  }

  Future<List<Map<String, dynamic>>> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) {
      await _writeRaw(_seedItems);
      return _seedItems.map((item) => Map<String, dynamic>.of(item)).toList();
    }
    return (jsonDecode(saved) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _writeRaw(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(items));
  }

  Map<String, dynamic> _toMap(GroceryItem item) => {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category.name,
        'isBought': item.isBought,
      };

  GroceryItem _fromMap(Map<String, dynamic> map) => GroceryItem(
        id: map['id'] as String,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        category: Categories.values.byName(map['category'] as String),
        // Items stored before this field existed count as "not bought".
        isBought: map['isBought'] as bool? ?? false,
      );
}
