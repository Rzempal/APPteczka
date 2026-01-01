import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/pdf_cache_service.dart';
import '../widgets/label_selector.dart';
import '../widgets/leaflet_search_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

/// Bottom sheet ze szczegółami leku
class MedicineDetailSheet extends StatefulWidget {
  final Medicine medicine;
  final StorageService storageService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onTagTap;
  final Function(String) onLabelTap;

  const MedicineDetailSheet({
    super.key,
    required this.medicine,
    required this.storageService,
    required this.onEdit,
    required this.onDelete,
    required this.onTagTap,
    required this.onLabelTap,
  });

  @override
  State<MedicineDetailSheet> createState() => _MedicineDetailSheetState();
}

class _MedicineDetailSheetState extends State<MedicineDetailSheet> {
  late Medicine _medicine;
  bool _isLabelsOpen = false;

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
                    const SizedBox(height: 20),
                    _buildLeafletSection(context),

                    // Etykiety - tytuł i ikona edycji w jednej linii
                    const SizedBox(height: 20),
                    _buildLabelSection(context),

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

  /// Sekcja etykiet z tytułem i ikoną edycji w jednej linii
  Widget _buildLabelSection(BuildContext context) {
    final selectedLabels = widget.storageService.getLabelsByIds(
      _medicine.labels,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Etykiety',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6b7280),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLabelsOpen ? Icons.expand_less : Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLabelsOpen
                        ? 'Zamknij'
                        : (selectedLabels.isEmpty ? 'Dodaj' : 'Edytuj'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabelSelector(
          storageService: widget.storageService,
          selectedLabelIds: _medicine.labels,
          isOpen: _isLabelsOpen,
          onToggle: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
          onLabelTap: (labelId) => widget.onLabelTap(labelId),
          onChanged: (newLabelIds) async {
            final updatedMedicine = _medicine.copyWith(labels: newLabelIds);
            await widget.storageService.saveMedicine(updatedMedicine);
            setState(() {
              _medicine = updatedMedicine;
            });
          },
        ),
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

  /// Sekcja ulotki PDF z wyszukiwarką lub przyciskami akcji
  Widget _buildLeafletSection(BuildContext context) {
    final hasLeaflet =
        _medicine.leafletUrl != null && _medicine.leafletUrl!.isNotEmpty;

    return _buildSection(
      context,
      title: 'Ulotka PDF:',
      child: hasLeaflet
          ? _buildLeafletActions(context)
          : _buildLeafletSearchButton(context),
    );
  }

  /// Przyciski gdy ulotka jest przypisana
  Widget _buildLeafletActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        NeuButton(
          onPressed: () => _showPdfViewer(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.fileText, size: 16, color: AppColors.valid),
              const SizedBox(width: 8),
              Text(
                'Pokaż ulotkę PDF',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        NeuButton(
          onPressed: () => _detachLeaflet(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.pinOff, size: 16, color: AppColors.expired),
              const SizedBox(width: 8),
              Text(
                'Odepnij',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Przycisk gdy brak ulotki
  Widget _buildLeafletSearchButton(BuildContext context) {
    return NeuButton(
      onPressed: () => _showLeafletSearch(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.fileSearch,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            'Znajdź i podepnij ulotkę',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Pokazuje bottom sheet z wyszukiwarką ulotek
  void _showLeafletSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => LeafletSearchSheet(
            initialQuery: _medicine.nazwa ?? '',
            onLeafletSelected: (url) => _attachLeaflet(url),
          ),
        ),
      ),
    );
  }

  /// Przypisuje ulotkę do leku
  Future<void> _attachLeaflet(String url) async {
    final updatedMedicine = _medicine.copyWith(leafletUrl: url);
    await widget.storageService.saveMedicine(updatedMedicine);
    setState(() {
      _medicine = updatedMedicine;
    });

    // Pobierz PDF do cache w tle
    final cacheService = PdfCacheService();
    cacheService.getPdfFile(url, _medicine.id);
  }

  /// Odłącza ulotkę od leku
  Future<void> _detachLeaflet() async {
    // Wyczyść cache
    final cacheService = PdfCacheService();
    await cacheService.clearCache(_medicine.id);

    // Aktualizuj lek (używamy pustego stringa bo copyWith nie obsługuje null)
    final updatedMedicine = Medicine(
      id: _medicine.id,
      nazwa: _medicine.nazwa,
      opis: _medicine.opis,
      wskazania: _medicine.wskazania,
      tagi: _medicine.tagi,
      labels: _medicine.labels,
      notatka: _medicine.notatka,
      terminWaznosci: _medicine.terminWaznosci,
      leafletUrl: null,
      dataDodania: _medicine.dataDodania,
    );
    await widget.storageService.saveMedicine(updatedMedicine);
    setState(() {
      _medicine = updatedMedicine;
    });
  }

  /// Otwiera pełnoekranowy viewer PDF
  void _showPdfViewer(BuildContext context) {
    if (_medicine.leafletUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          url: _medicine.leafletUrl!,
          title: _medicine.nazwa ?? 'Ulotka leku',
          medicineId: _medicine.id,
        ),
      ),
    );
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
