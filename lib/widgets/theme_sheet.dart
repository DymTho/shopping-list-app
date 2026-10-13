import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Opens the "Appearance" bottom sheet: pick a color palette and choose
/// light, dark or the system mode.
void showThemeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _ThemeSheet(),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.read<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final entry in palettes.entries)
                  _PaletteDot(
                    key: ValueKey('palette-${entry.key.name}'),
                    label: entry.value.label,
                    color: entry.value.seedColor,
                    selected: theme.palette == entry.key,
                    onTap: () => provider.selectPalette(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Mode', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.primaryContainer,
                ),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System'),
                  ),
                ],
                selected: {theme.mode},
                onSelectionChanged: (selection) =>
                    provider.selectMode(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
