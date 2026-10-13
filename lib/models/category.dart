import 'package:flutter/material.dart';

/// The 10 predefined shopping categories required by the assignment.
/// The enum name (e.g. `vegetables`) is also what we send to the server.
enum Categories {
  vegetables,
  fruit,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  other,
}

/// How a [Categories] value looks in the UI: a readable title, a color
/// (used for the colored square next to each item) and an icon.
class Category {
  const Category(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;
}
