import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/grocery_group.dart';

/// The colored title above each group of items: "DAIRY  2".
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.group});

  final GroceryGroup group;

  @override
  Widget build(BuildContext context) {
    final category = categories[group.category]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '${group.items.length}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: category.color,
                ),
          ),
        ],
      ),
    );
  }
}
