import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Gradient card on top of the list: how much is left to buy, with a progress
/// bar that fills as items are ticked off.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.toBuyCount,
    required this.toBuyPieces,
    required this.boughtCount,
    required this.totalCount,
  });

  final int toBuyCount;
  final int toBuyPieces;
  final int boughtCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalCount == 0 ? 0.0 : boughtCount / totalCount;
    final allDone = totalCount > 0 && toBuyCount == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone
                    ? Icons.check_circle_rounded
                    : Icons.shopping_cart_rounded,
                size: 36,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone
                          ? 'Everything is bought'
                          : '$toBuyCount ${toBuyCount == 1 ? 'item' : 'items'} to buy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                    ),
                    Text(
                      '$toBuyPieces pieces left  ·  $boughtCount of $totalCount in the cart',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animates smoothly from the old progress to the new one.
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.25),
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOut);
  }
}
