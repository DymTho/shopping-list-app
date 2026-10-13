import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../data/grocery_repository.dart';
import '../models/category.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';

/// "Add a new item" form (assignment requirements 2-4). When an
/// [editedItem] is given, the same form edits that item instead.
///
/// Uses a [Form] with a [GlobalKey]: the key lets us call `validate()` to
/// check every field, `save()` to copy the typed values into variables, and
/// `reset()` to clear the form (or restore the item's original values).
class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key, this.editedItem});

  final GroceryItem? editedItem;

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.editedItem != null;

  /// What "Reset" goes back to: the item's own category, or Vegetables.
  Categories get _initialCategory =>
      widget.editedItem?.category ?? Categories.vegetables;

  // Filled in by each field's onSaved when `save()` is called.
  String _enteredName = '';
  int _enteredQuantity = 1;
  late Categories _selectedCategory = _initialCategory;

  bool _isSaving = false;

  /// Validates the form; if everything is fine, stores the item through the
  /// provider and closes the screen. If storing fails, the form stays open
  /// and a message is shown.
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final provider = context.read<GroceryProvider>();
      if (_isEditing) {
        await provider.updateItem(
          original: widget.editedItem!,
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        );
      } else {
        await provider.addItem(
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        );
      }
      navigator.pop();
    } on GroceryRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Could not save the item. ${e.message}')));
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() => _selectedCategory = _initialCategory);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit item' : 'Add a new item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          // After the user touches a field, re-check it on every change, so an
          // error message disappears as soon as the input becomes valid.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Change anything' : 'What do you need?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update the name, quantity or category.'
                    : 'Give it a name, how many, and a category.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: widget.editedItem?.name,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) => _enteredName = value!.trim(),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '${widget.editedItem?.quantity ?? 1}',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.numbers_rounded),
                        // The field is narrow, so let the message wrap
                        // instead of being cut off with "...".
                        errorMaxLines: 2,
                      ),
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        if (quantity == null || quantity <= 0) {
                          return 'Must be a valid, positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) => _enteredQuantity = int.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Categories>(
                      initialValue: _initialCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final entry in categories.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: entry.value.color,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    entry.value.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedCategory = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : _resetForm,
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveItem,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Add Item'),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
        ),
      ),
    );
  }
}
