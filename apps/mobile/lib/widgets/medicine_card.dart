import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'package:intl/intl.dart';

/// Karta pojedynczego leku
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getBorderColor(medicine.expiryStatus, colorScheme),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek: nazwa + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.nazwa ?? 'Nieznany lek',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _ExpiryBadge(status: medicine.expiryStatus),
                ],
              ),

              const SizedBox(height: 8),

              // Opis
              Text(
                medicine.opis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tagi
              if (medicine.tagi.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: medicine.tagi
                      .take(4)
                      .map((tag) => _TagChip(tag: tag))
                      .toList(),
                ),

              // Termin ważności
              if (medicine.terminWaznosci != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: _getExpiryColor(
                        medicine.expiryStatus,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(medicine.terminWaznosci!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getExpiryColor(
                          medicine.expiryStatus,
                          colorScheme,
                        ),
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
    );
  }

  Color _getBorderColor(ExpiryStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ExpiryStatus.expired:
        return Colors.red.shade300;
      case ExpiryStatus.expiringSoon:
        return Colors.orange.shade300;
      case ExpiryStatus.valid:
        return Colors.green.shade300;
      case ExpiryStatus.unknown:
        return colorScheme.outline;
    }
  }

  Color _getExpiryColor(ExpiryStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ExpiryStatus.expired:
        return Colors.red.shade700;
      case ExpiryStatus.expiringSoon:
        return Colors.orange.shade700;
      case ExpiryStatus.valid:
        return Colors.green.shade700;
      case ExpiryStatus.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }
}

/// Badge statusu ważności
class _ExpiryBadge extends StatelessWidget {
  final ExpiryStatus status;

  const _ExpiryBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ExpiryStatus.unknown) return const SizedBox.shrink();

    final (icon, color, label) = switch (status) {
      ExpiryStatus.expired => (Icons.error, Colors.red, 'Przeterminowany'),
      ExpiryStatus.expiringSoon => (Icons.warning, Colors.orange, 'Kończy się'),
      ExpiryStatus.valid => (Icons.check_circle, Colors.green, 'Ważny'),
      ExpiryStatus.unknown => (Icons.help, Colors.grey, ''),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip dla tagu
class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
