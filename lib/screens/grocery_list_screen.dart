import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../data/grocery_repository.dart';
import '../models/grocery_group.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../widgets/category_header.dart';
import '../widgets/grocery_list_item.dart';
import '../widgets/grocery_skeleton.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/state_views.dart';
import '../widgets/summary_card.dart';
import '../widgets/theme_sheet.dart';
import 'new_item_screen.dart';

/// Home screen: shows the shopping list and switches between the loading
/// skeleton, an error message, the empty message and the list itself
/// depending on [GroceryProvider.status] (conditional rendering).
class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({super.key});

  /// Opens the add form (or the edit form, if an [item] is given) with a
  /// slide-up + fade transition.
  void _openForm(BuildContext context, {GroceryItem? item}) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            NewItemScreen(editedItem: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Runs a data-source action and, if it fails, tells the user. The provider
  /// has already undone the change by then.
  Future<void> _runWithMessage(
    BuildContext context,
    Future<void> Function() action,
    String failureText,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on GroceryRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$failureText ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    final provider = context.read<GroceryProvider>();

    Future<void> refresh() => _runWithMessage(
          context,
          provider.refresh,
          'Could not refresh the list.',
        );

    final Widget body = switch (grocery.status) {
      LoadStatus.loading => const GrocerySkeleton(key: ValueKey('loading')),
      LoadStatus.error => ErrorState(
          key: const ValueKey('error'),
          message: grocery.errorMessage,
          onRetry: provider.load,
        ),
      // "Empty" and "list" share one key on purpose: AnimatedSwitcher would
      // otherwise keep the old list on screen for a moment when the last item
      // is removed, and a swiped-away Dismissible must leave the tree at once.
      LoadStatus.loaded => KeyedSubtree(
          key: const ValueKey('loaded'),
          child: grocery.items.isEmpty
              ? RefreshIndicator(
                  onRefresh: refresh,
                  child: const _ScrollableCenter(child: EmptyState()),
                )
              : Column(
                  children: [
                    const SearchAndFilters(),
                    const SizedBox(height: 4),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: refresh,
                        child: grocery.groups.isEmpty
                            ? _ScrollableCenter(
                                child: NoMatchesState(
                                  onClear: provider.clearFilters,
                                ),
                              )
                            : _GroceryList(
                                groups: grocery.groups,
                                toBuyCount: grocery.toBuyCount,
                                toBuyPieces: grocery.toBuyPieces,
                                boughtCount: grocery.boughtCount,
                                totalCount: grocery.totalCount,
                                onToggleBought: (item) => _runWithMessage(
                                  context,
                                  () => provider.toggleBought(item),
                                  'Could not update "${item.name}".',
                                ),
                                onEdit: (item) => _openForm(context, item: item),
                                onRemove: (item) => _runWithMessage(
                                  context,
                                  () => provider.removeItem(item),
                                  'Could not remove "${item.name}".',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Appearance',
            onPressed: () => showThemeSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: body,
      ),
      // Hidden while loading so nothing can be added during the first fetch.
      floatingActionButton: grocery.status == LoadStatus.loaded
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add item'),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8))
          : null,
    );
  }
}

/// Centers a message but keeps it scrollable, because pull-to-refresh only
/// works on something that can scroll.
class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }
}

class _GroceryList extends StatelessWidget {
  const _GroceryList({
    required this.groups,
    required this.toBuyCount,
    required this.toBuyPieces,
    required this.boughtCount,
    required this.totalCount,
    required this.onToggleBought,
    required this.onEdit,
    required this.onRemove,
  });

  final List<GroceryGroup> groups;
  final int toBuyCount;
  final int toBuyPieces;
  final int boughtCount;
  final int totalCount;
  final void Function(GroceryItem item) onToggleBought;
  final void Function(GroceryItem item) onEdit;
  final void Function(GroceryItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Flatten the groups into one list of rows: a GroceryGroup stands for its
    // header, a GroceryItem for an item.
    final rows = <Object>[
      for (final group in groups) ...[group, ...group.items],
    ];

    return ListView.builder(
      // Lets the pull-to-refresh gesture work even when the list is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      // +1 for the summary card shown above the first row.
      itemCount: rows.length + 1,
      // Tells the list which row moved where after a change, so the other
      // rows keep their state instead of replaying their entrance animation.
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        if (key.value == 'summary') return 0;
        final index = rows.indexWhere(
          (row) => switch (row) {
            GroceryGroup() => 'header-${row.category.name}' == key.value,
            GroceryItem() => row.id == key.value,
            _ => false,
          },
        );
        return index == -1 ? null : index + 1;
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return SummaryCard(
            key: const ValueKey('summary'),
            toBuyCount: toBuyCount,
            toBuyPieces: toBuyPieces,
            boughtCount: boughtCount,
            totalCount: totalCount,
          );
        }

        final row = rows[index - 1];
        if (row is GroceryGroup) {
          return KeyedSubtree(
            key: ValueKey('header-${row.category.name}'),
            child: CategoryHeader(group: row)
                .animate()
                .fadeIn(duration: 300.ms),
          );
        }

        final item = row as GroceryItem;
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(top: 12),
          child: Dismissible(
            // The id is unique and stable, so Flutter tracks the right row.
            key: ValueKey(item.id),
            // Swipe to the right to remove (assignment requirement 5).
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_rounded, color: colorScheme.onError),
                  const SizedBox(width: 8),
                  Text(
                    'Remove',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (_) => onRemove(item),
            child: GroceryListItem(
              item: item,
              onToggleBought: () => onToggleBought(item),
              onTap: () => onEdit(item),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: (index.clamp(0, 8) * 40).ms)
                .slideX(begin: 0.08, curve: Curves.easeOut),
          ),
        );
      },
    );
  }
}
