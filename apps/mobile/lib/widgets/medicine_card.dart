import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../theme/app_theme.dart';

/// Karta leku - styl zbliżony do wersji webowej z obsługą Light/Dark mode
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final List<UserLabel> labels;
  final VoidCallback? onTap;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.labels = const [],
    this.onTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nagłówek: Nazwa + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nazwa leku
                    Expanded(
                      child: Text(
                        medicine.nazwa ?? 'Nieznany lek',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    if (statusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: Colors.white),
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
                        ),
                      ),
                  ],
                ),

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

                // Etykiety użytkownika
                if (medicineLabels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: medicineLabels.map((label) {
                      final colorInfo = labelColors[label.color]!;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            colorInfo.hexValue,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(
                              colorInfo.hexValue,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(colorInfo.hexValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(colorInfo.hexValue),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Tagi
                if (medicine.tagi.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: medicine.tagi.take(4).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // Termin ważności
                if (medicine.terminWaznosci != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(medicine.terminWaznosci!),
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient(ExpiryStatus status, bool isDark) {
    if (isDark) {
      switch (status) {
        case ExpiryStatus.expired:
          return AppColors.darkGradientExpired;
        case ExpiryStatus.expiringSoon:
          return AppColors.darkGradientExpiringSoon;
        case ExpiryStatus.valid:
          return AppColors.darkGradientValid;
        case ExpiryStatus.unknown:
          return LinearGradient(
            colors: [AppColors.darkSurface, AppColors.darkSurfaceLight],
          );
      }
    } else {
      switch (status) {
        case ExpiryStatus.expired:
          return AppColors.lightGradientExpired;
        case ExpiryStatus.expiringSoon:
          return AppColors.lightGradientExpiringSoon;
        case ExpiryStatus.valid:
          return AppColors.lightGradientValid;
        case ExpiryStatus.unknown:
          return const LinearGradient(
            colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
          );
      }
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
        return LucideIcons.xCircle;
      case ExpiryStatus.expiringSoon:
        return LucideIcons.alertTriangle;
      case ExpiryStatus.valid:
        return LucideIcons.checkCircle;
      case ExpiryStatus.unknown:
        return LucideIcons.helpCircle;
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
