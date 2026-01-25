import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/selection_controller.dart';
import '../theme/app_theme.dart';

/// Pasek trybu zaznaczania - styl analogiczny do SearchBar
/// Rozciąga się na pełną szerokość (opcja B)
class SelectionBar extends StatelessWidget {
  final SelectionController controller;
  final int totalCount; // Łączna liczba elementów (do toggle)
  final VoidCallback? onDelete;
  final VoidCallback? onLabels;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  const SelectionBar({
    super.key,
    required this.controller,
    required this.totalCount,
    this.onDelete,
    this.onLabels,
    this.onSelectAll,
    this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Czy wszystkie są zaznaczone?
    final allSelected =
        controller.selectedCount >= totalCount && totalCount > 0;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        // Glassmorphism effect - identyczny jak SearchBar
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.5)
            : AppColors.lightSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikona trybu zaznaczania + licznik
          Icon(
            LucideIcons.squareMousePointer,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${controller.selectedCount}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),

          // Zaznacz/Odznacz wszystkie - toggle w zależności od stanu
          _buildTextButton(
            icon: allSelected ? LucideIcons.squareX : LucideIcons.checkCheck,
            label: allSelected ? 'Odznacz wszystkie' : 'Zaznacz wszystkie',
            onTap: allSelected ? onDeselectAll : onSelectAll,
            theme: theme,
          ),

          const Spacer(),

          // Usuń
          _buildIconButton(
            icon: LucideIcons.trash2,
            tooltip: 'Usuń zaznaczone',
            onTap: onDelete,
            theme: theme,
            isDestructive: true,
          ),
          const SizedBox(width: 4),

          // Etykiety
          _buildIconButton(
            icon: LucideIcons.tags,
            tooltip: 'Dodaj etykiety',
            onTap: onLabels,
            theme: theme,
          ),

          const SizedBox(width: 8),

          // Przycisk zamknięcia
          _buildIconButton(
            icon: LucideIcons.x,
            tooltip: 'Zakończ zaznaczanie',
            onTap: () {
              HapticFeedback.lightImpact();
              controller.exitMode();
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// Przycisk z ikoną i tekstem
  Widget _buildTextButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? AppColors.expired
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
