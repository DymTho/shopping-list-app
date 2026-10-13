import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/grocery_item.dart';

/// One row of the shopping list: a "bought" checkbox, a colored category
/// icon, the item name, its category and the quantity (assignment 1b).
/// Tapping the checkbox ticks the item; tapping the rest opens the editor.
class GroceryListItem extends StatelessWidget {
  const GroceryListItem({
    super.key,
    required this.item,
    required this.onToggleBought,
    required this.onTap,
  });

  final GroceryItem item;
  final void Function() onToggleBought;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = categories[item.category]!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
            child: Row(
              children: [
                _BoughtToggle(
                  key: ValueKey('bought-toggle-${item.id}'),
                  isBought: item.isBought,
                  onTap: onToggleBought,
                ),
                Expanded(
                  // Dimmed when bought, so the row clearly looks "done".
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: item.isBought ? 0.5 : 1,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                category.color,
                                category.color.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                          child: Icon(category.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: item.isBought
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: category.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '×${item.quantity}',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round checkbox that fills with a check mark when the item is bought.
class _BoughtToggle extends StatelessWidget {
  const _BoughtToggle({super.key, required this.isBought, required this.onTap});

  final bool isBought;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        // Makes the tap area about 48x48 although the circle itself is smaller.
        padding: const EdgeInsets.all(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBought ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: isBought ? colorScheme.primary : colorScheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            scale: isBought ? 1 : 0,
            child: Icon(Icons.check_rounded, size: 18, color: colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
