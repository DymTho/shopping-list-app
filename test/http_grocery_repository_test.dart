import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopping_list/data/grocery_repository.dart';
import 'package:shopping_list/data/http_grocery_repository.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

const _baseUrl = 'https://example-default-rtdb.firebaseio.com';

HttpGroceryRepository _repo(MockClientHandler handler) =>
    HttpGroceryRepository(baseUrl: _baseUrl, client: MockClient(handler));

void main() {
  group('fetchItems', () {
    test('parses the Firebase map and returns newest first', () async {
      late http.Request seen;
      final repo = _repo((request) async {
        seen = request;
        return http.Response(
          json.encode({
            '-Oa': {'name': 'Milk', 'quantity': 3, 'category': 'dairy'},
            '-Ob': {'name': 'Bananas', 'quantity': 6, 'category': 'fruit'},
          }),
          200,
        );
      });

      final items = await repo.fetchItems();

      expect(seen.method, 'GET');
      expect(seen.url.toString(), '$_baseUrl/shopping-list.json');
      expect(items.map((i) => i.name), ['Bananas', 'Milk']);
      expect(items.first.id, '-Ob');
      expect(items.first.quantity, 6);
      expect(items.first.category, Categories.fruit);
    });

    test('reads isBought, and treats a missing value as not bought', () async {
      final repo = _repo((_) async => http.Response(
            json.encode({
              '-Oa': {
                'name': 'Milk',
                'quantity': 3,
                'category': 'dairy',
                'isBought': true,
              },
              '-Ob': {'name': 'Old item', 'quantity': 1, 'category': 'other'},
            }),
            200,
          ));

      final items = await repo.fetchItems();

      expect(items.firstWhere((i) => i.name == 'Milk').isBought, isTrue);
      expect(items.firstWhere((i) => i.name == 'Old item').isBought, isFalse);
    });

    test('returns an empty list when Firebase answers "null"', () async {
      final repo = _repo((_) async => http.Response('null', 200));
      expect(await repo.fetchItems(), isEmpty);
    });

    test('turns an error status into a readable exception', () async {
      final repo = _repo((_) async => http.Response('nope', 500));
      expect(
        repo.fetchItems(),
        throwsA(
          isA<GroceryRepositoryException>()
              .having((e) => e.message, 'message', contains('500')),
        ),
      );
    });

    test('turns a network failure into a readable exception', () async {
      final repo = _repo((_) async => throw Exception('no internet'));
      expect(repo.fetchItems(), throwsA(isA<GroceryRepositoryException>()));
    });

    test('turns text that is not JSON into a readable exception', () async {
      final repo = _repo((_) async => http.Response('<html>oops</html>', 200));
      expect(repo.fetchItems(), throwsA(isA<GroceryRepositoryException>()));
    });
  });

  group('fetchItems with imperfect data on the server', () {
    Future<List<GroceryItem>> fetch(Object body) =>
        _repo((_) async => http.Response(json.encode(body), 200)).fetchItems();

    test('reads categories written as titles, in any letter case', () async {
      final items = await fetch({
        '-Oa': {'name': 'Milk', 'quantity': 1, 'category': 'Dairy'},
        '-Ob': {'name': 'Kale', 'quantity': 1, 'category': 'VEGETABLES'},
      });
      expect(items.map((i) => i.category), [Categories.vegetables, Categories.dairy]);
    });

    test('a missing or unknown category becomes "Other"', () async {
      final items = await fetch({
        '-Oa': {'name': 'Mystery', 'quantity': 1},
        '-Ob': {'name': 'Cheese', 'quantity': 1, 'category': 'Deli'},
      });
      expect(items.map((i) => i.category), [Categories.other, Categories.other]);
    });

    test('quantity may be a decimal or text; bad values become 1', () async {
      final items = await fetch({
        '-Oa': {'name': 'A', 'quantity': 2.0, 'category': 'Dairy'},
        '-Ob': {'name': 'B', 'quantity': '5', 'category': 'Dairy'},
        '-Oc': {'name': 'C', 'quantity': 'many', 'category': 'Dairy'},
        '-Od': {'name': 'D', 'quantity': -3, 'category': 'Dairy'},
        '-Oe': {'name': 'E', 'category': 'Dairy'},
      });
      expect(items.reversed.map((i) => i.quantity), [2, 5, 1, 1, 1]);
    });

    test('an item without a name still shows up, as "Unnamed item"', () async {
      final items = await fetch({
        '-Oa': {'quantity': 1, 'category': 'Dairy'},
      });
      expect(items.single.name, 'Unnamed item');
    });

    test('entries that are not objects are skipped, the rest still load',
        () async {
      final items = await fetch({
        '-Oa': 5,
        '-Ob': {'name': 'Milk', 'quantity': 1, 'category': 'Dairy'},
        '-Oc': null,
      });
      expect(items.map((i) => i.name), ['Milk']);
    });

    test('accepts a JSON list (Firebase does that for keys 0, 1, 2...)',
        () async {
      final items = await fetch([
        {'name': 'Milk', 'quantity': 1, 'category': 'Dairy'},
        null,
        {'name': 'Pasta', 'quantity': 2, 'category': 'Carbs'},
      ]);
      expect(items.map((i) => i.name), ['Pasta', 'Milk']);
    });
  });

  test('addItem POSTs the item as JSON and returns it with the new id', () async {
    late http.Request seen;
    final repo = _repo((request) async {
      seen = request;
      return http.Response(json.encode({'name': '-Oxyz'}), 200);
    });

    final item = await repo.addItem(
      name: 'Pasta',
      quantity: 2,
      category: Categories.carbs,
    );

    expect(seen.method, 'POST');
    expect(seen.url.toString(), '$_baseUrl/shopping-list.json');
    expect(json.decode(seen.body), {
      'name': 'Pasta',
      'quantity': 2,
      'category': 'Carbs',
      'isBought': false,
    });
    expect(item.id, '-Oxyz');
    expect(item.name, 'Pasta');
  });

  test('updateItem PATCHes the changed fields to the item url', () async {
    late http.Request seen;
    final repo = _repo((request) async {
      seen = request;
      return http.Response('{}', 200);
    });

    await repo.updateItem(const GroceryItem(
      id: '-Oxyz',
      name: 'Pasta',
      quantity: 4,
      category: Categories.carbs,
      isBought: true,
    ));

    expect(seen.method, 'PATCH');
    expect(seen.url.toString(), '$_baseUrl/shopping-list/-Oxyz.json');
    expect(json.decode(seen.body), {
      'name': 'Pasta',
      'quantity': 4,
      'category': 'Carbs',
      'isBought': true,
    });
  });

  test('updateItem reports a failed request', () async {
    final repo = _repo((_) async => http.Response('nope', 404));
    expect(
      repo.updateItem(const GroceryItem(
        id: 'x',
        name: 'Pasta',
        quantity: 1,
        category: Categories.carbs,
      )),
      throwsA(isA<GroceryRepositoryException>()),
    );
  });

  test('deleteItem sends DELETE to the item url', () async {
    late http.Request seen;
    final repo = _repo((request) async {
      seen = request;
      return http.Response('null', 200);
    });

    await repo.deleteItem('-Oxyz');

    expect(seen.method, 'DELETE');
    expect(seen.url.toString(), '$_baseUrl/shopping-list/-Oxyz.json');
  });
}
