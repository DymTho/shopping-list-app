import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list/main.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/grocery_list_item.dart';
import 'package:shopping_list/widgets/grocery_skeleton.dart';

import 'fake_grocery_repository.dart';

const _milk = GroceryItem(
  id: 'm1',
  name: 'Milk',
  quantity: 3,
  category: Categories.dairy,
);
const _cucumber = GroceryItem(
  id: 'c1',
  name: 'Cucumber',
  quantity: 1,
  category: Categories.vegetables,
);
const _carrot = GroceryItem(
  id: 'c2',
  name: 'Carrot',
  quantity: 4,
  category: Categories.vegetables,
);

/// Pumps the app and waits for the first load. The extra second lets the
/// timers of the entrance animations run, so none is left pending.
Future<void> _openApp(WidgetTester tester, FakeGroceryRepository repo) async {
  await tester.pumpWidget(ShoppingListApp(repository: repo));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text('Add item'));
  await _settle(tester);
}

/// Finds [text] inside the list row of the item called [itemName].
Finder _inRow(String itemName, String text) => find.descendant(
      of: find.ancestor(
        of: find.text(itemName),
        matching: find.byType(GroceryListItem),
      ),
      matching: find.text(text),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a loading skeleton, then the list with all details',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk, _cucumber]);

    await tester.pumpWidget(ShoppingListApp(repository: repo));
    expect(find.byType(GrocerySkeleton), findsOneWidget);

    await _settle(tester);
    expect(find.byType(GrocerySkeleton), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
    expect(_inRow('Milk', '×3'), findsOneWidget);
    expect(_inRow('Milk', 'Dairy'), findsOneWidget);
    expect(find.text('Cucumber'), findsOneWidget);
    expect(_inRow('Cucumber', 'Vegetables'), findsOneWidget);
  });

  testWidgets('shows a message when the list is empty', (tester) async {
    await _openApp(tester, FakeGroceryRepository());
    expect(find.text('Your list is empty'), findsOneWidget);
  });

  testWidgets('shows an error with a working "Try again" button',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk])..failingFetches = 1;
    await _openApp(tester, repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Could not reach the server.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('groups the list under a header for each category',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk, _cucumber, _carrot]);
    await _openApp(tester, repo);

    final vegetables = find.byKey(const ValueKey('header-vegetables'));
    final dairy = find.byKey(const ValueKey('header-dairy'));
    expect(vegetables, findsOneWidget);
    expect(dairy, findsOneWidget);
    // Vegetables come before Dairy in the category order.
    expect(
      tester.getTopLeft(vegetables).dy < tester.getTopLeft(dairy).dy,
      isTrue,
    );
  });

  testWidgets('ticking an item stores it and moves it down its group',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_cucumber, _carrot]);
    await _openApp(tester, repo);

    await tester.tap(find.byKey(const ValueKey('bought-toggle-c1')));
    await _settle(tester);

    expect(repo.items.firstWhere((i) => i.id == 'c1').isBought, isTrue);
    // The ticked cucumber now sits below the carrot.
    expect(
      tester.getTopLeft(find.text('Cucumber')).dy >
          tester.getTopLeft(find.text('Carrot')).dy,
      isTrue,
    );
    expect(find.textContaining('1 of 2 in the cart'), findsOneWidget);
  });

  testWidgets('a tick is undone with a message if saving fails',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk])..failUpdate = true;
    await _openApp(tester, repo);

    await tester.tap(find.byKey(const ValueKey('bought-toggle-m1')));
    await _settle(tester);

    expect(find.textContaining('Could not update "Milk"'), findsOneWidget);
    expect(find.textContaining('0 of 1 in the cart'), findsOneWidget);
  });

  testWidgets('search hides non-matching items and can be cleared',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk, _cucumber]);
    await _openApp(tester, repo);

    await tester.enterText(find.byType(TextField), 'mil');
    await _settle(tester);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cucumber'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await _settle(tester);
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await _settle(tester);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cucumber'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });

  testWidgets('a category chip shows only that category', (tester) async {
    final repo = FakeGroceryRepository(items: [_milk, _cucumber]);
    await _openApp(tester, repo);

    await tester.tap(find.byKey(const ValueKey('chip-dairy')));
    await _settle(tester);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cucumber'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('chip-all')));
    await _settle(tester);
    expect(find.text('Cucumber'), findsOneWidget);
  });

  testWidgets('form shows validation messages for invalid input',
      (tester) async {
    await _openApp(tester, FakeGroceryRepository());
    await _openForm(tester);

    // Empty name.
    await tester.tap(find.text('Add Item'));
    await _settle(tester);
    expect(find.text('Must be between 1 and 50 characters.'), findsOneWidget);

    // Quantity that is not a positive number.
    final quantity = find.widgetWithText(TextFormField, 'Quantity');
    for (final bad in ['abc', '0', '-2']) {
      await tester.enterText(quantity, bad);
      await tester.tap(find.text('Add Item'));
      await _settle(tester);
      expect(find.text('Must be a valid, positive number.'), findsOneWidget);
    }
  });

  testWidgets('an error message goes away once the input is valid',
      (tester) async {
    await _openApp(tester, FakeGroceryRepository());
    await _openForm(tester);

    await tester.tap(find.text('Add Item'));
    await _settle(tester);
    expect(find.text('Must be between 1 and 50 characters.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Apples');
    await _settle(tester);
    expect(find.text('Must be between 1 and 50 characters.'), findsNothing);
  });

  testWidgets('a valid form stores the item and shows it in the list',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk]);
    await _openApp(tester, repo);
    await _openForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Apples');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '5');
    await tester.tap(find.text('Add Item'));
    await _settle(tester);

    expect(find.text('Add a new item'), findsNothing);
    expect(find.text('Apples'), findsOneWidget);
    expect(find.text('×5'), findsOneWidget);
    expect(repo.items.first.name, 'Apples');
  });

  testWidgets('tapping an item opens the form filled in, and saves changes',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk]);
    await _openApp(tester, repo);

    await tester.tap(find.text('Milk'));
    await _settle(tester);

    expect(find.text('Edit item'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Milk'), 'Oat milk');
    await tester.enterText(find.widgetWithText(TextFormField, '3'), '6');
    await tester.tap(find.text('Save changes'));
    await _settle(tester);

    expect(find.text('Edit item'), findsNothing);
    expect(find.text('Oat milk'), findsOneWidget);
    expect(find.text('×6'), findsOneWidget);
    expect(repo.items.single.name, 'Oat milk');
    expect(repo.items.single.quantity, 6);
  });

  testWidgets('pulling the list down reloads it from the data source',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk]);
    await _openApp(tester, repo);
    expect(repo.fetchCount, 1);

    repo.items.add(_cucumber);
    await tester.fling(find.text('Milk'), const Offset(0, 400), 1000);
    await _settle(tester);

    expect(repo.fetchCount, 2);
    expect(find.text('Cucumber'), findsOneWidget);
  });

  testWidgets('swiping an item to the right removes it', (tester) async {
    final repo = FakeGroceryRepository(items: [_milk, _cucumber]);
    await _openApp(tester, repo);

    await tester.drag(find.text('Milk'), const Offset(600, 0));
    await _settle(tester);

    expect(find.text('Milk'), findsNothing);
    expect(find.text('Cucumber'), findsOneWidget);
    expect(repo.deletedIds, ['m1']);
  });

  testWidgets('removing the last item shows the empty message', (tester) async {
    final repo = FakeGroceryRepository(items: [_milk]);
    await _openApp(tester, repo);

    await tester.drag(find.text('Milk'), const Offset(600, 0));
    await _settle(tester);

    expect(find.text('Milk'), findsNothing);
    expect(find.text('Your list is empty'), findsOneWidget);
  });

  testWidgets('an item comes back with a message if removing fails',
      (tester) async {
    final repo = FakeGroceryRepository(items: [_milk])..failDelete = true;
    await _openApp(tester, repo);

    await tester.drag(find.text('Milk'), const Offset(600, 0));
    await _settle(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('Could not remove "Milk"'), findsOneWidget);
  });

  testWidgets('the appearance sheet changes and remembers palette and mode',
      (tester) async {
    await _openApp(tester, FakeGroceryRepository(items: [_milk]));

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await _settle(tester);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('palette-ocean')));
    await _settle(tester);
    await tester.tap(find.text('Dark'));
    await _settle(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_palette'), 'ocean');
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
