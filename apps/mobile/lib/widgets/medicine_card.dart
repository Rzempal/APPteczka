import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../theme/app_theme.dart';

/// Karta leku - styl zbliżony do wersji webowej z obsługą Light/Dark mode
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final List<UserLabel> labels;
  final VoidCallback? onTap;
  final bool isCompact;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.labels = const [],
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = medicine.expiryStatus;
    final gradient = _getGradient(status, isDark);
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final statusIcon = _getStatusIcon(status);

    // Pobierz etykiety dla tego leku
    final medicineLabels = labels
        .where((l) => medicine.labels.contains(l.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: NeuDecoration.statusCard(
            isDark: isDark,
            gradient: gradient,
            radius: 20,
            borderColor: statusColor,
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nagłówek: Nazwa + Status (align right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nazwa leku (flexible)
                    Expanded(
                      child: Text(
                        medicine.nazwa ?? 'Nieznany lek',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: isCompact ? 15 : null,
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge (align right)
                    if (statusLabel != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 10,
                          vertical: isCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: isCompact ? 12 : 14,
                              color: Colors.white,
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),

                // Etykiety (wrap na nową linię jeśli nie mieszczą się)
                if (medicineLabels.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...medicineLabels
                          .take(3)
                          .map((label) => _buildBadge(label, isDark)),
                      if (medicineLabels.length > 3)
                        _buildBadgeCount(medicineLabels.length - 3, isDark),
                    ],
                  ),
                ],

                // Compact: tylko data
                if (isCompact) ...[
                  if (medicine.terminWaznosci != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(medicine.terminWaznosci!),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ] else ...[
                  // Full view
                  const SizedBox(height: 8),

                  // Opis
                  Text(
                    medicine.opis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // #tags - uproszczony styl
                  if (medicine.tagi.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: medicine.tagi.take(4).map((tag) {
                        return _buildTag(tag, isDark, theme);
                      }).toList(),
                    ),

                  // Notatka jeśli istnieje
                  if (medicine.notatka != null &&
                      medicine.notatka!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.transparent
                            : theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(128),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? theme.dividerColor.withAlpha(50)
                              : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.stickyNote,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              medicine.notatka!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Data ważności
                  if (medicine.terminWaznosci != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ważny do: ${_formatDate(medicine.terminWaznosci!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge etykiety - kolorowe tło z białym tekstem
  Widget _buildBadge(UserLabel label, bool isDark) {
    final colorInfo = labelColors[label.color]!;
    final bgColor = Color(colorInfo.hexValue);

    // Określ kolor tekstu na podstawie jasności tła
    final textColor = _getContrastColor(bgColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Badge count indicator when more than 2 labels
  Widget _buildBadgeCount(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFe5e7eb),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF374151),
        ),
      ),
    );
  }

  /// Tag - uproszczony styl (light: szary border, dark: ciemne tło)
  Widget _buildTag(String tag, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1e293b) // ciemny slate
            : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155) // slate-700
              : const Color(0xFFe2e8f0), // slate-200
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }

  /// Zwraca kontrastowy kolor tekstu dla danego tła
  Color _getContrastColor(Color background) {
    // Oblicz jasność tła
    final luminance = background.computeLuminance();
    // Dla jasnych kolorów (yellow, orange) użyj ciemnego tekstu
    return luminance > 0.5 ? const Color(0xFF1e293b) : Colors.white;
  }

  LinearGradient _getGradient(ExpiryStatus status, bool isDark) {
    switch (status) {
      case ExpiryStatus.expired:
        return isDark
            ? AppColors.darkGradientExpired
            : AppColors.lightGradientExpired;
      case ExpiryStatus.expiringSoon:
        return isDark
            ? AppColors.darkGradientExpiringSoon
            : AppColors.lightGradientExpiringSoon;
      case ExpiryStatus.valid:
        return isDark
            ? AppColors.darkGradientValid
            : AppColors.lightGradientValid;
      case ExpiryStatus.unknown:
        // Neutral gradient - light gray
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1e293b), const Color(0xFF334155)]
              : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
        );
    }
  }

  Color _getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return AppColors.expired;
      case ExpiryStatus.expiringSoon:
        return AppColors.expiringSoon;
      case ExpiryStatus.valid:
        return AppColors.valid;
      case ExpiryStatus.unknown:
        return const Color(0xFF6b7280);
    }
  }

  String? _getStatusLabel(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'Przeterminowany';
      case ExpiryStatus.expiringSoon:
        return 'Kończy się';
      case ExpiryStatus.valid:
        return 'Ważny';
      case ExpiryStatus.unknown:
        return null;
    }
  }

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return LucideIcons.circleX;
      case ExpiryStatus.expiringSoon:
        return LucideIcons.triangleAlert;
      case ExpiryStatus.valid:
        return LucideIcons.circleCheck;
      case ExpiryStatus.unknown:
        return LucideIcons.circleHelp;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
