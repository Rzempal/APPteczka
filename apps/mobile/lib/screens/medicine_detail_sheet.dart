import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../widgets/label_selector.dart';
import '../theme/app_theme.dart';

/// Bottom sheet ze szczegółami leku
class MedicineDetailSheet extends StatefulWidget {
  final Medicine medicine;
  final StorageService storageService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onTagTap;

  const MedicineDetailSheet({
    super.key,
    required this.medicine,
    required this.storageService,
    required this.onEdit,
    required this.onDelete,
    required this.onTagTap,
  });

  @override
  State<MedicineDetailSheet> createState() => _MedicineDetailSheetState();
}

class _MedicineDetailSheetState extends State<MedicineDetailSheet> {
  late Medicine _medicine;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
  }

  @override
  Widget build(BuildContext context) {
    final status = _medicine.expiryStatus;
    final statusColor = _getStatusColor(status);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek z przyciskami akcji
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _medicine.nazwa ?? 'Nieznany lek',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: AppColors.primary,
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.expired,
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Opis
                    Text(
                      _medicine.opis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    // Ulotka PDF
                    if (_medicine.leafletUrl != null &&
                        _medicine.leafletUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        title: 'Ulotka PDF',
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openPdf(context),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Pokaż ulotkę PDF'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Etykiety - tylko LabelSelector (usuwa duplikację)
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Etykiety',
                      child: LabelSelector(
                        storageService: widget.storageService,
                        selectedLabelIds: _medicine.labels,
                        onChanged: (newLabelIds) async {
                          final updatedMedicine = _medicine.copyWith(
                            labels: newLabelIds,
                          );
                          await widget.storageService.saveMedicine(
                            updatedMedicine,
                          );
                          setState(() {
                            _medicine = updatedMedicine;
                          });
                        },
                      ),
                    ),

                    // Wskazania
                    if (_medicine.wskazania.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        title: 'Wskazania',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _medicine.wskazania
                              .map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    // Tagi - fixed for dark mode
                    if (_medicine.tagi.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        title: '#tags',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _medicine.tagi.map((tag) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return ActionChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              onPressed: () => widget.onTagTap(tag),
                              backgroundColor: isDark
                                  ? AppColors.primary.withAlpha(30)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.primary.withAlpha(80)
                                    : Theme.of(context).dividerColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // Notatka - editable with dark mode support
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Notatka',
                      child: _buildNoteSection(context),
                    ),

                    // Termin ważności
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Termin ważności',
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _medicine.terminWaznosci != null
                                ? _formatDate(_medicine.terminWaznosci!)
                                : 'Nie ustawiono',
                            style: TextStyle(
                              fontSize: 16,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_medicine.terminWaznosci != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Data dodania
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Dodano',
                      child: Text(
                        _formatDate(_medicine.dataDodania),
                        style: const TextStyle(color: Color(0xFF6b7280)),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6b7280),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNote = _medicine.notatka?.isNotEmpty == true;

    return GestureDetector(
      onTap: () => _showEditNoteDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.transparent
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Theme.of(context).dividerColor.withAlpha(80)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasNote ? _medicine.notatka! : 'Kliknij, aby dodać notatkę',
                style: TextStyle(
                  color: hasNote
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNoteDialog(BuildContext context) async {
    final controller = TextEditingController(text: _medicine.notatka ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj notatkę'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Wpisz notatkę...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedMedicine = _medicine.copyWith(notatka: result);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  Future<void> _openPdf(BuildContext context) async {
    if (_medicine.leafletUrl == null) return;

    final uri = Uri.parse(_medicine.leafletUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie można otworzyć linku PDF')),
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

  String _getStatusLabel(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'Przeterminowany';
      case ExpiryStatus.expiringSoon:
        return 'Kończy się';
      case ExpiryStatus.valid:
        return 'Ważny';
      case ExpiryStatus.unknown:
        return 'Brak daty';
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
