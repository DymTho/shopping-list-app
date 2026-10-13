import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/grocery_provider.dart';

/// Search field plus a row of category chips above the list. Both only change
/// what is *shown*; the stored list is untouched.
class SearchAndFilters extends StatefulWidget {
  const SearchAndFilters({super.key});

  @override
  State<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<SearchAndFilters> {
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Clear filters" can be pressed elsewhere, so keep the text field in sync
    // with the provider (typing already keeps them equal, so no loop).
    final query = Provider.of<GroceryProvider>(context).searchQuery;
    if (_controller.text != query) _controller.text = query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    final provider = context.read<GroceryProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            onChanged: provider.setSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search your list',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: grocery.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear search',
                      onPressed: () => provider.setSearchQuery(''),
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // A scrollable Row (not a fixed-height ListView) lets every chip take
        // exactly the width and height its content needs.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                key: const ValueKey('chip-all'),
                label: const Text('All'),
                selected: grocery.categoryFilter == null,
                onSelected: (_) => provider.setCategoryFilter(null),
              ),
              for (final category in grocery.availableCategories)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    key: ValueKey('chip-${category.name}'),
                    avatar: Icon(
                      categories[category]!.icon,
                      size: 18,
                      color: categories[category]!.color,
                    ),
                    label: Text(categories[category]!.title),
                    selected: grocery.categoryFilter == category,
                    onSelected: (_) => provider.setCategoryFilter(category),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
