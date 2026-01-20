import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stałe dla bottomSheet - spójny design w całej aplikacji
class BottomSheetConstants {
  static const double radius = 24.0;
  static const double innerRadius = 20.0;
  static const double dragHandleWidth = 48.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleTopPadding = 12.0;
  static const double contentPadding = 24.0;
  static const double framePadding = 12.0; // padding ramki zewnętrznej
}

/// Reużywalny drag handle dla bottomSheet
/// Znajduje się w zewnętrznej ramce, nad wewnętrznym kontenerem
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
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkTextMuted.withAlpha(150)
              : AppColors.lightTextMuted.withAlpha(100),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Wewnętrzny kontener z efektem neumorficznym (inset)
/// Tworzy efekt "wgłębienia" dla treści
class _InnerContentContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _InnerContentContainer({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Kolory dla efektu dwutonowego tła
    final innerBgColor = isDark
        ? const Color(0xFF3f4d62) // jaśniejszy od ramki (0xFF334155)
        : const Color(0xFFf2faf6); // wyraźnie jasnozielony, jaśniejszy od ramki (0xFFedf3ef)

    final innerShadowDark = isDark
        ? Colors.black.withAlpha(40)
        : AppColors.lightShadowDark.withAlpha(60);

    final innerShadowLight = isDark
        ? AppColors.darkShadowLight.withAlpha(30)
        : Colors.white.withAlpha(200);

    return Container(
      margin: const EdgeInsets.only(
        left: BottomSheetConstants.framePadding,
        right: BottomSheetConstants.framePadding,
        bottom: BottomSheetConstants.framePadding,
      ),
      decoration: BoxDecoration(
        color: innerBgColor,
        borderRadius: AppTheme.organicRadiusBottomSheetInner,
        // Efekt inset shadow - neumorficzne "wgłębienie"
        boxShadow: [
          // Cień wewnętrzny górny-lewy (ciemny)
          BoxShadow(
            color: innerShadowDark,
            offset: const Offset(2, 2),
            blurRadius: 6,
            spreadRadius: -2,
          ),
          // Cień wewnętrzny dolny-prawy (jasny) - highlight
          BoxShadow(
            color: innerShadowLight,
            offset: const Offset(-1, -1),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Helper do wyświetlania ustandaryzowanych bottomSheet
/// Dwuwarstwowa struktura: zewnętrzna ramka + wewnętrzny kontener treści
class AppBottomSheet {
  /// Wyświetla bottomSheet z dwuwarstwowym tłem neumorficznym
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

        // Kolor zewnętrznej ramki (frame)
        final frameColor = isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;

        return Container(
          // Zewnętrzna ramka z organic shape (Soft UI 2026)
          decoration: BoxDecoration(
            color: frameColor,
            borderRadius: AppTheme.organicRadiusBottomSheet,
            // Subtelny cień dla całego bottomSheet
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(80)
                    : AppColors.lightShadowDark.withAlpha(60),
                offset: const Offset(0, -4),
                blurRadius: 20,
              ),
            ],
          ),
          child: useScrollController
              ? DraggableScrollableSheet(
                  initialChildSize: initialChildSize,
                  minChildSize: minChildSize,
                  maxChildSize: maxChildSize,
                  expand: false,
                  builder: (context, scrollController) => Column(
                    children: [
                      // Drag handle w zewnętrznej ramce
                      const BottomSheetDragHandle(),
                      // Wewnętrzny kontener z treścią
                      Expanded(
                        child: _InnerContentContainer(
                          isDark: isDark,
                          child: builder(context, scrollController),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BottomSheetDragHandle(),
                    _InnerContentContainer(
                      isDark: isDark,
                      child: builder(context, ScrollController()),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Wyświetla bottomSheet z prostą listą opcji
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
            horizontal: BottomSheetConstants.contentPadding - BottomSheetConstants.framePadding,
            vertical: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opcjonalny nagłówek
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
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
                ),
                const SizedBox(height: 16),
              ],
              // Lista opcji - bez pełnych separatorów
              ...options.asMap().entries.map((entry) {
                final option = entry.value;
                return _OptionTile<T>(option: option);
              }),
              const SizedBox(height: 8),
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

/// Widget dla pojedynczej opcji - bez pełnych linii separatorów
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
