import 'package:flutter/material.dart';

import '../models/category.dart';

/// Predefined categories (data layer). Looked up by the [Categories] enum.
const Map<Categories, Category> categories = {
  Categories.vegetables: Category('Vegetables', Color(0xFF2ECC71), Icons.eco),
  Categories.fruit: Category('Fruit', Color(0xFF9BCB3C), Icons.apple),
  Categories.meat: Category('Meat', Color(0xFFE5533D), Icons.kebab_dining),
  Categories.dairy: Category('Dairy', Color(0xFF29B6F6), Icons.local_drink),
  Categories.carbs: Category('Carbs', Color(0xFF5C6BC0), Icons.bakery_dining),
  Categories.sweets: Category('Sweets', Color(0xFFFF8FB1), Icons.cookie),
  Categories.spices: Category('Spices', Color(0xFFFFB300), Icons.grain),
  Categories.convenience:
      Category('Convenience', Color(0xFFAB47BC), Icons.microwave),
  Categories.hygiene: Category('Hygiene', Color(0xFF26C6DA), Icons.clean_hands),
  Categories.other: Category('Other', Color(0xFF8D9AA6), Icons.shopping_basket),
};
