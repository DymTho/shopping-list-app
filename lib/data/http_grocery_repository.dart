import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/grocery_item.dart';
import 'categories.dart';
import 'grocery_repository.dart';

/// Talks to a Firebase Realtime Database over plain HTTP (REST), the same
/// way as in the Udemy course:
///   GET    `{baseUrl}/shopping-list.json`       all items (a map of id to item)
///   POST   `{baseUrl}/shopping-list.json`       store an item, answers `{"name": "new id"}`
///   PATCH  `{baseUrl}/shopping-list/{id}.json`  change fields of one item
///   DELETE `{baseUrl}/shopping-list/{id}.json`  remove one item
class HttpGroceryRepository implements GroceryRepository {
  HttpGroceryRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri get _listUri => Uri.parse('$baseUrl/shopping-list.json');
  Uri _itemUri(String id) => Uri.parse('$baseUrl/shopping-list/$id.json');

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  /// The fields stored on the server (the id is the key, so it isn't here).
  /// The category is stored as its title, e.g. "Vegetables", like in the
  /// Udemy course, so other tools using the same database understand it.
  String _encode(GroceryItem item) => json.encode({
        'name': item.name,
        'quantity': item.quantity,
        'category': categories[item.category]!.title,
        'isBought': item.isBought,
      });

  /// Reads a stored category: its title ("Vegetables") or the enum name
  /// ("vegetables"), in any letter case. A missing or unknown value becomes
  /// "Other", so one odd item can never stop the whole list from loading.
  Categories _parseCategory(Object? stored) {
    final text = '$stored'.trim().toLowerCase();
    for (final entry in categories.entries) {
      if (entry.key.name == text || entry.value.title.toLowerCase() == text) {
        return entry.key;
      }
    }
    return Categories.other;
  }

  /// Accepts 3, 3.0 or "3"; anything that is not a positive number becomes 1.
  int _parseQuantity(Object? stored) {
    final number = stored is num ? stored.toInt() : int.tryParse('$stored');
    return (number == null || number < 1) ? 1 : number;
  }

  /// Turns one stored entry into an item, or null if it isn't an object.
  GroceryItem? _parseItem(String id, Object? data) {
    if (data is! Map) return null;
    final name = '${data['name'] ?? ''}'.trim();
    return GroceryItem(
      id: id,
      name: name.isEmpty ? 'Unnamed item' : name,
      quantity: _parseQuantity(data['quantity']),
      category: _parseCategory(data['category']),
      // Items stored before this field existed count as "not bought".
      isBought: data['isBought'] == true,
    );
  }

  @override
  Future<List<GroceryItem>> fetchItems() async {
    final response = await _send(() => _client.get(_listUri));

    // Firebase answers the literal text "null" when nothing is stored yet.
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Object? data;
    try {
      data = json.decode(response.body);
    } catch (_) {
      throw const GroceryRepositoryException(
        'The server sent data in an unexpected format.',
      );
    }

    // Firebase answers an object {id: item}, or a list if the keys were 0, 1, 2...
    final Iterable<MapEntry<String, Object?>> entries;
    if (data is Map) {
      entries = data.entries.map((e) => MapEntry('${e.key}', e.value));
    } else if (data is List) {
      entries = [
        for (var i = 0; i < data.length; i++) MapEntry('$i', data[i]),
      ];
    } else {
      throw const GroceryRepositoryException(
        'The server sent data in an unexpected format.',
      );
    }

    final items = [
      for (final entry in entries) ?_parseItem(entry.key, entry.value),
    ];
    // Firebase ids are chronological, so reversing gives newest first.
    return items.reversed.toList();
  }

  @override
  Future<GroceryItem> addItem({
    required String name,
    required int quantity,
    required Categories category,
  }) async {
    // The server decides the id, so the item sent has an empty one for now.
    final toStore = GroceryItem(
      id: '',
      name: name,
      quantity: quantity,
      category: category,
    );
    final response = await _send(
      () => _client.post(_listUri, headers: _jsonHeaders, body: _encode(toStore)),
    );
    final id = json.decode(response.body)['name'] as String;
    return GroceryItem(
      id: id,
      name: name,
      quantity: quantity,
      category: category,
    );
  }

  @override
  Future<void> updateItem(GroceryItem item) async {
    await _send(
      () => _client.patch(
        _itemUri(item.id),
        headers: _jsonHeaders,
        body: _encode(item),
      ),
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await _send(() => _client.delete(_itemUri(id)));
  }

  /// Runs a request and turns every failure (no internet, timeout, HTTP error
  /// status, unexpected JSON) into one [GroceryRepositoryException].
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) {
        throw GroceryRepositoryException(
          'The server answered with an error (${response.statusCode}).',
        );
      }
      return response;
    } on GroceryRepositoryException {
      rethrow;
    } catch (_) {
      throw const GroceryRepositoryException(
        'Could not reach the server. Check your internet connection.',
      );
    }
  }
}
