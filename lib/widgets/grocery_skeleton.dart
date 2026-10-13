import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading indicator (assignment requirement 7a): grey placeholder rows with
/// a moving shine, shaped like the real list so the layout doesn't jump when
/// the data arrives.
class GrocerySkeleton extends StatelessWidget {
  const GrocerySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.black12,
      highlightColor: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.04),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: index == 0 ? 96 : 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
