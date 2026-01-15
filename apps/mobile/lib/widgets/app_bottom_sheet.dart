import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stałe dla bottomSheet - spójny design w całej aplikacji
class BottomSheetConstants {
  static const double radius = 20.0;
  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleTopPadding = 12.0;
  static const double contentPadding = 24.0;
}

/// Reużywalny drag handle dla bottomSheet
/// Automatycznie dostosowuje kolor do motywu
class BottomSheetDragHandle extends StatelessWidget {
  const BottomSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: BottomSheetConstants.dragHandleWidth,
        height: BottomSheetConstants.dragHandleHeight,
        margin: const EdgeInsets.only(
          top: BottomSheetConstants.dragHandleTopPadding,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceLight // #334155
              : AppColors.lightShadowDark, // #a3b5ad
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Helper do wyświetlania ustandaryzowanych bottomSheet
/// Zapewnia spójny wygląd: zaokrąglone rogi, odpowiednie tło, obsługa klawiatury
class AppBottomSheet {
  /// Wyświetla prosty bottomSheet z automatycznym stylem
  ///
  /// [builder] - funkcja budująca zawartość (otrzymuje scrollController dla DraggableScrollableSheet)
  /// [initialChildSize] - początkowa wysokość (0.0-1.0), domyślnie 0.5
  /// [minChildSize] - minimalna wysokość przy przeciąganiu
  /// [maxChildSize] - maksymalna wysokość przy przeciąganiu
  /// [isDismissible] - czy można zamknąć przez tap poza sheetem
  /// [enableDrag] - czy można przeciągać sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, ScrollController scrollController) builder,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useScrollController = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BottomSheetConstants.radius),
            ),
          ),
          child: useScrollController
              ? DraggableScrollableSheet(
                  initialChildSize: initialChildSize,
                  minChildSize: minChildSize,
                  maxChildSize: maxChildSize,
                  expand: false,
                  builder: (context, scrollController) => Column(
                    children: [
                      const BottomSheetDragHandle(),
                      Expanded(
                        child: builder(context, scrollController),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BottomSheetDragHandle(),
                    builder(context, ScrollController()),
                  ],
                ),
        );
      },
    );
  }

  /// Wyświetla bottomSheet z prostą listą opcji (jak na screenshotach)
  /// Idealny do menu kontekstowych, sortowania, itp.
  static Future<T?> showOptions<T>({
    required BuildContext context,
    required List<BottomSheetOption<T>> options,
    String? title,
    IconData? titleIcon,
  }) {
    return show<T>(
      context: context,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        final theme = Theme.of(context);

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: BottomSheetConstants.contentPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opcjonalny nagłówek
              if (title != null) ...[
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Lista opcji
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isLast = index == options.length - 1;

                return Column(
                  children: [
                    _OptionTile<T>(option: option),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withAlpha(80),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// Pojedyncza opcja w bottomSheet
class BottomSheetOption<T> {
  final IconData icon;
  final String label;
  final String? subtitle;
  final T? value;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isSelected;

  const BottomSheetOption({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.onTap,
    this.isDestructive = false,
    this.isSelected = false,
  });
}

/// Widget dla pojedynczej opcji
class _OptionTile<T> extends StatelessWidget {
  final BottomSheetOption<T> option;

  const _OptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = option.isDestructive
        ? AppColors.expired
        : option.isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () {
        if (option.onTap != null) {
          option.onTap!();
        } else if (option.value != null) {
          Navigator.pop(context, option.value);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Icon(option.icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight:
                          option.isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (option.subtitle != null)
                    Text(
                      option.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (option.isSelected)
              Icon(
                Icons.check,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
