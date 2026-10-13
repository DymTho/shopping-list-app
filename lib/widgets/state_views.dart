import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shown when the shopping list is empty (assignment requirement 7c).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.shopping_basket_outlined,
      title: 'Your list is empty',
      message: 'Tap "Add item" to write down what you need to buy.',
    );
  }
}

/// Shown when the search or category filter hides every item.
class NoMatchesState extends StatelessWidget {
  const NoMatchesState({super.key, required this.onClear});

  final void Function() onClear;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.search_off_rounded,
      title: 'No matches',
      message: 'Nothing in your list fits this search.',
      action: FilledButton.tonalIcon(
        onPressed: onClear,
        icon: const Icon(Icons.filter_alt_off_rounded),
        label: const Text('Clear filters'),
      ),
    );
  }
}

/// Shown when loading fails (assignment requirement 7b), with a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message,
      isError: true,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = isError ? colorScheme.error : colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 56, color: tint),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!.animate().fadeIn(delay: 350.ms),
            ],
          ],
        ),
      ),
    );
  }
}
