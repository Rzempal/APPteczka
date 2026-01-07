import 'package:flutter/material.dart';
import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/pdf_cache_service.dart';
import '../services/date_ocr_service.dart';
import '../widgets/label_selector.dart';
import '../widgets/leaflet_search_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../widgets/filters_sheet.dart' show tagCategories;
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
  bool _isEditingNote = false;
  late TextEditingController _noteController;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
    _noteController = TextEditingController(text: _medicine.notatka ?? '');
    _noteFocusNode = FocusNode();
    _noteFocusNode.addListener(_onNoteFocusChange);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.removeListener(_onNoteFocusChange);
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onNoteFocusChange() {
    if (!_noteFocusNode.hasFocus && _isEditingNote) {
      _saveNote();
    }
  }

  Future<void> _saveNote() async {
    final newNote = _noteController.text.trim();
    if (newNote != (_medicine.notatka ?? '')) {
      final updatedMedicine = _medicine.copyWith(
        notatka: newNote.isEmpty ? null : newNote,
      );
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
    setState(() {
      _isEditingNote = false;
    });
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
                    // Nagłówek z nazwą leku
                    SelectableText(
                      _medicine.nazwa ?? 'Nieznany lek',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // Opis - editable (ikona przy treści)
                    _buildSectionWithContentEdit(
                      context,
                      title: 'Opis',
                      onEdit: () => _showEditDescriptionDialog(context),
                      child: SelectableText(
                        _medicine.opis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),

                    // Wskazania - editable (ikona przy treści)
                    const SizedBox(height: 20),
                    _buildSectionWithContentEdit(
                      context,
                      title: 'Wskazania',
                      onEdit: () => _showEditWskazaniaDialog(context),
                      child: _medicine.wskazania.isEmpty
                          ? Text(
                              'Brak wskazań - kliknij aby dodać',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Column(
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
                                            child: SelectableText(
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

                    // Ulotka PDF
                    const SizedBox(height: 20),
                    _buildLeafletSection(context),

                    // Notatka - inline editable
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Notatka',
                      child: _buildNoteSection(context),
                    ),

                    // Etykiety - tytuł i ikona edycji przy treści
                    const SizedBox(height: 20),
                    _buildLabelSection(context),

                    // Tagi - editable for custom tags only (ikona przy treści)
                    const SizedBox(height: 20),
                    _buildSectionWithContentEdit(
                      context,
                      title: '#Tags',
                      onEdit: () => _showEditCustomTagsDialog(context),
                      child: _medicine.tagi.isEmpty
                          ? Text(
                              'Brak tagów - kliknij aby dodać',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _medicine.tagi.map((tag) {
                                final isDark =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                return ActionChip(
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
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

                    // Termin ważności - sekcja wielu opakowań
                    const SizedBox(height: 20),
                    _buildPackagesSection(context, statusColor),

                    // Kalkulator zużycia leku
                    const SizedBox(height: 20),
                    _buildSupplyCalculatorSection(context),

                    // Data dodania
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      title: 'Dodano',
                      child: SelectableText(
                        _formatDate(_medicine.dataDodania),
                        style: const TextStyle(color: Color(0xFF6b7280)),
                      ),
                    ),

                    // Usuń lek - nowa sekcja na dole
                    const SizedBox(height: 20),
                    _buildDeleteSection(context),

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

  /// Sekcja zarządzania wieloma opakowaniami z różnymi datami ważności
  Widget _buildPackagesSection(BuildContext context, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packages = _medicine.sortedPackages;
    final packageCount = _medicine.packageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Termin ważności - Ilość opakowań X + package-plus icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Termin ważności',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6b7280),
                    ),
                  ),
                  if (packageCount > 0) ...[
                    TextSpan(
                      text: ' - Ilość opakowań ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6b7280),
                      ),
                    ),
                    TextSpan(
                      text: '$packageCount',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Ikona pomocy
            if (packageCount > 0)
              GestureDetector(
                onTap: () => _showIconsHelpDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.lightbulb,
                    size: 24,
                    color: AppColors.expiringSoon,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista opakowań
        if (packages.isEmpty)
          _buildEmptyPackageState(context, isDark)
        else
          ...packages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            final isFirst = index == 0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < packages.length - 1 ? 8 : 0,
              ),
              child: _buildPackageRow(context, package, isFirst, isDark),
            );
          }),

        // Przycisk "Dodaj opakowanie"
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showAddPackageDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.packagePlus,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dodaj opakowanie',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sekcja kalkulatora "Do kiedy wystarczy?"
  Widget _buildSupplyCalculatorSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPieces = _medicine.totalPieceCount;
    final supplyEndDate = _medicine.calculateSupplyEndDate();

    // Sprawdź czy można obliczyć
    final canCalculate = totalPieces > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header z ikoną calendar-heart
        Row(
          children: [
            Icon(LucideIcons.calendarHeart, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Do kiedy wystarczy?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6b7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!canCalculate)
          // Komunikat: brak danych o ilości sztuk
          _buildSupplyMissingDataMessage(context)
        else if (supplyEndDate == null)
          // Przycisk: ustaw dzienne zużycie
          _buildSetDailyIntakeButton(context, isDark)
        else
          // Wynik: data + liczba dni
          _buildSupplyResult(context, supplyEndDate, isDark),
        const SizedBox(height: 8),
        Text(
          'Kalkulacja szacunkowa na podstawie Twoich danych. Nie zastępuje zaleceń lekarza.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Komunikat gdy brakuje pieceCount w opakowaniach
  Widget _buildSupplyMissingDataMessage(BuildContext context) {
    return Text(
      'Uzupełnij ilość sztuk w opakowaniach',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        fontSize: 13,
      ),
    );
  }

  /// Przycisk do ustawienia dziennego zużycia
  Widget _buildSetDailyIntakeButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showSetDailyIntakeDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.pillBottle,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Ustaw dzienne zużycie',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wyświetla wynik kalkulacji: "Zabraknie od: DD.MM.YYYY (za X dni)"
  Widget _buildSupplyResult(
    BuildContext context,
    DateTime endDate,
    bool isDark,
  ) {
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;
    final formattedDate =
        '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wiersz z datą i przyciskiem edycji
        GestureDetector(
          onTap: () => _showSetDailyIntakeDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendarOff,
                  size: 16,
                  color: daysRemaining <= 7
                      ? AppColors.expired
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Zabraknie od: ',
                        style: TextStyle(fontSize: 13),
                      ),
                      TextSpan(
                        text: formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: daysRemaining <= 7
                              ? AppColors.expired
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' (za $daysRemaining dni)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.squarePen,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Przycisk "Dodaj do kalendarza"
        GestureDetector(
          onTap: () => _addToCalendar(endDate),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendarPlus,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dodaj do kalendarza',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Dodaje przypomnienie o końcu zapasu leku do kalendarza systemowego
  void _addToCalendar(DateTime endDate) {
    final medicineName = _medicine.nazwa ?? 'Lek';
    final event = Event(
      title: '$medicineName - koniec',
      description: 'Przypomnienie: koniec zapasu leku "$medicineName".',
      startDate: endDate,
      endDate: endDate.add(const Duration(hours: 1)),
      allDay: true,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  /// Dialog ustawienia dziennego zużycia tabletek
  Future<void> _showSetDailyIntakeDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _medicine.dailyIntake?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dzienne zużycie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Łączna ilość sztuk: ${_medicine.totalPieceCount}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ile tabletek dziennie?',
                hintText: 'np. 2',
                suffixText: 'szt./dzień',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      // Zapisz do Medicine i storage
      final updated = _medicine.copyWith(dailyIntake: result);
      await widget.storageService.saveMedicine(updated);
      setState(() => _medicine = updated);
    }
  }

  /// Stan pusty - brak opakowań
  Widget _buildEmptyPackageState(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddPackageDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarPlus,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Ustaw termin ważności',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pojedynczy wiersz opakowania
  Widget _buildPackageRow(
    BuildContext context,
    MedicinePackage package,
    bool isFirst,
    bool isDark,
  ) {
    final status = _getPackageStatus(package);
    final packageStatusColor = _getStatusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Badge z datą
            GestureDetector(
              onTap: () => _showEditPackageDateDialog(context, package),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: packageStatusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      package.displayDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Przycisk OCR
            GestureDetector(
              onTap: () => _takeDatePhotoForPackage(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.camera,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Przycisk edycji daty
            GestureDetector(
              onTap: () => _showEditPackageDateDialog(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.calendarCog,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Przycisk określenia ilości
            GestureDetector(
              onTap: () => _showEditRemainingDialog(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.blocks,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Spacer(),
            // Przycisk usunięcia (tylko jeśli więcej niż 1 opakowanie)
            if (_medicine.packages.length > 1)
              GestureDetector(
                onTap: () => _deletePackage(package),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 20,
                    color: AppColors.expired,
                  ),
                ),
              ),
          ],
        ),
        // Status opakowania (dla wszystkich opakowań)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: GestureDetector(
            onTap: () => _showEditRemainingDialog(context, package),
            child: Text(
              '└─ ${package.remainingDescription}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ExpiryStatus _getPackageStatus(MedicinePackage package) {
    final expiry = package.dateTime;
    if (expiry == null) return ExpiryStatus.unknown;

    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;

    if (daysUntilExpiry < 0) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.valid;
  }

  /// Sekcja etykiet z tytułem i ikoną edycji przy treści
  Widget _buildLabelSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek bez ikony edycji
        Text(
          'Etykiety',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6b7280),
          ),
        ),
        const SizedBox(height: 8),
        // Treść z ikoną edycji po prawej
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabelSelector(
                storageService: widget.storageService,
                selectedLabelIds: _medicine.labels,
                isOpen: _isLabelsOpen,
                onToggle: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
                onLabelTap: (labelId) => widget.onLabelTap(labelId),
                onChanged: (newLabelIds) async {
                  final updatedMedicine = _medicine.copyWith(
                    labels: newLabelIds,
                  );
                  await widget.storageService.saveMedicine(updatedMedicine);
                  setState(() {
                    _medicine = updatedMedicine;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  _isLabelsOpen ? LucideIcons.chevronUp : LucideIcons.squarePen,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sekcja notatki - inline editing z zielonym outline i przyciskiem check wewnątrz
  Widget _buildNoteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNote = _medicine.notatka?.isNotEmpty == true;

    return GestureDetector(
      onTap: () {
        if (!_isEditingNote) {
          setState(() {
            _isEditingNote = true;
            _noteController.text = _medicine.notatka ?? '';
          });
          // Schedule focus after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _noteFocusNode.requestFocus();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.transparent
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: _isEditingNote
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: _isEditingNote
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pole tekstowe - bez wewnętrznego outline
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      maxLines: null,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Wpisz notatkę...',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onSubmitted: (_) => _saveNote(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Przycisk check wewnątrz pola, wyrównany do prawej
                  GestureDetector(
                    onTap: _saveNote,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: NeuDecoration.flatSmall(
                        isDark: isDark,
                        radius: 16,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                hasNote ? _medicine.notatka! : 'Kliknij, aby dodać notatkę',
                style: TextStyle(
                  color: hasNote
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                ),
              ),
      ),
    );
  }

  /// Sekcja z nagłówkiem i ikoną edycji przy treści (squarePen 40px, wyrównana do prawej)
  Widget _buildSectionWithContentEdit(
    BuildContext context, {
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek bez ikony edycji
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6b7280),
          ),
        ),
        const SizedBox(height: 8),
        // Treść z ikoną edycji po prawej
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            if (onEdit != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.squarePen,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Dialog edycji opisu
  Future<void> _showEditDescriptionDialog(BuildContext context) async {
    final controller = TextEditingController(text: _medicine.opis);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj opis'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Opis działania leku...',
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

    if (result != null && result.isNotEmpty) {
      final updatedMedicine = _medicine.copyWith(opis: result);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Dialog edycji wskazań
  Future<void> _showEditWskazaniaDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _medicine.wskazania.join(', '),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj wskazania'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Wskazania oddzielone przecinkami...',
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
      final wskazania = result
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final updatedMedicine = _medicine.copyWith(wskazania: wskazania);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Dialog edycji custom tagów (tylko tagi spoza kontrolowanej listy)
  Future<void> _showEditCustomTagsDialog(BuildContext context) async {
    // Rozdzielenie tagów na systemowe i custom
    final categorizedTags = tagCategories.values.expand((e) => e).toSet();
    final customTags = _medicine.tagi
        .where((t) => !categorizedTags.contains(t))
        .toList();

    final controller = TextEditingController(text: customTags.join(', '));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj własne tagi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tagi spoza listy kontrolowanej. Oddziel przecinkami.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'np. domowe, mama, dziecko...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      // Zachowaj tagi systemowe i dodaj nowe custom tagi
      final systemTags = _medicine.tagi
          .where((t) => categorizedTags.contains(t))
          .toList();
      final newCustomTags = result
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedMedicine = _medicine.copyWith(
        tagi: [...systemTags, ...newCustomTags],
      );
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Dialog dodawania nowego opakowania
  Future<void> _showAddPackageDialog(BuildContext context) async {
    final currentYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    int selectedYear = currentYear + 1;
    bool useSameDate = false;
    bool useSameQuantity = false;

    // Sprawdź czy pierwsze opakowanie ma ustawioną ilość
    final firstPackage = _medicine.packages.isNotEmpty
        ? _medicine.sortedPackages.first
        : null;
    final hasQuantity = firstPackage?.remainingDescription != null;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj opakowanie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Przycisk "Taka sama data" (tylko jeśli są inne opakowania)
              if (_medicine.packages.isNotEmpty) ...[
                CheckboxListTile(
                  title: Text(
                    'Taka sama data (${_medicine.sortedPackages.first.displayDate})',
                  ),
                  value: useSameDate,
                  onChanged: (v) =>
                      setDialogState(() => useSameDate = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                // Przycisk "Taka sama ilość" (tylko jeśli pierwsze ma ilość)
                if (hasQuantity)
                  CheckboxListTile(
                    title: Text(
                      'Taka sama ilość (${firstPackage!.remainingDescription})',
                    ),
                    value: useSameQuantity,
                    onChanged: (v) =>
                        setDialogState(() => useSameQuantity = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 12),
              ],
              // Picker miesiąca/roku (ukryty jeśli "taka sama")
              if (!useSameDate)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Miesiąc',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Rok',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(15, (i) => currentYear + i)
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedYear = v!),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                DateTime date;
                if (useSameDate && _medicine.packages.isNotEmpty) {
                  date =
                      _medicine.sortedPackages.first.dateTime ??
                      DateTime(selectedYear, selectedMonth + 1, 0);
                } else {
                  date = DateTime(selectedYear, selectedMonth + 1, 0);
                }
                Navigator.pop(context, {
                  'date': date,
                  'useSameQuantity': useSameQuantity,
                });
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final date = result['date'] as DateTime;
      final copyQuantity = result['useSameQuantity'] as bool;

      MedicinePackage newPackage;
      if (copyQuantity && firstPackage != null) {
        newPackage = MedicinePackage(
          expiryDate: date.toIso8601String().split('T')[0],
          pieceCount: firstPackage.pieceCount,
          percentRemaining: firstPackage.percentRemaining,
        );
      } else {
        newPackage = MedicinePackage(
          expiryDate: date.toIso8601String().split('T')[0],
        );
      }

      final updatedPackages = [..._medicine.packages, newPackage];
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Dialog edycji daty konkretnego opakowania
  Future<void> _showEditPackageDateDialog(
    BuildContext context,
    MedicinePackage package,
  ) async {
    DateTime currentDate =
        package.dateTime ?? DateTime.now().add(const Duration(days: 365));
    int selectedMonth = currentDate.month;
    int selectedYear = currentDate.year;
    final currentYear = DateTime.now().year;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edytuj termin ważności'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Miesiąc',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.toString().padLeft(2, '0')),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedMonth = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Rok',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(15, (i) => currentYear + i)
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedYear = v!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final lastDay = DateTime(selectedYear, selectedMonth + 1, 0);
                Navigator.pop(context, lastDay);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedPackage = package.copyWith(
        expiryDate: result.toIso8601String().split('T')[0],
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Dialog określenia statusu i ilości w opakowaniu
  Future<void> _showEditRemainingDialog(
    BuildContext context,
    MedicinePackage package,
  ) async {
    // Status: false = zamknięte, true = otwarte
    bool isOpen = package.isOpen;
    // Wartość: 0 = brak, 1 = sztuki, 2 = procent
    int valueMode = package.pieceCount != null
        ? 1
        : package.percentRemaining != null
        ? 2
        : 0;
    final pieceController = TextEditingController(
      text: package.pieceCount?.toString() ?? '',
    );
    final percentController = TextEditingController(
      text: package.percentRemaining?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Określ pozostałą ilość w opakowaniu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status opakowania
              Text(
                'Status opakowania',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Zamknięte'),
                    selected: !isOpen,
                    onSelected: (_) => setDialogState(() {
                      isOpen = false;
                      // Reset procent przy zamknięciu
                      if (valueMode == 2) valueMode = 0;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Otwarte'),
                    selected: isOpen,
                    onSelected: (_) => setDialogState(() => isOpen = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Ilość w opakowaniu
              Text(
                'Ilość w opakowaniu (opcjonalne)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Brak'),
                    selected: valueMode == 0,
                    onSelected: (_) => setDialogState(() => valueMode = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Sztuki'),
                    selected: valueMode == 1,
                    onSelected: (_) => setDialogState(() => valueMode = 1),
                  ),
                  // Procent tylko dla otwartych
                  if (isOpen)
                    ChoiceChip(
                      label: const Text('Procent'),
                      selected: valueMode == 2,
                      onSelected: (_) => setDialogState(() => valueMode = 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Input dla wybranego trybu
              if (valueMode == 1)
                TextField(
                  controller: pieceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isOpen
                        ? 'Pozostało sztuk'
                        : 'Ilość sztuk w opakowaniu',
                    hintText: 'np. 30',
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (valueMode == 2)
                TextField(
                  controller: percentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pozostało procent',
                    hintText: 'np. 50',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'isOpen': isOpen,
                  'pieceCount': valueMode == 1
                      ? int.tryParse(pieceController.text)
                      : null,
                  'percentRemaining': valueMode == 2
                      ? int.tryParse(percentController.text)
                      : null,
                });
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedPackage = MedicinePackage(
        id: package.id,
        expiryDate: package.expiryDate,
        isOpen: result['isOpen'] as bool,
        pieceCount: result['pieceCount'] as int?,
        percentRemaining: result['percentRemaining'] as int?,
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// Usuwa opakowanie
  Future<void> _deletePackage(MedicinePackage package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń opakowanie?'),
        content: Text(
          'Czy na pewno chcesz usunąć opakowanie z datą ${package.displayDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedPackages = _medicine.packages
          .where((p) => p.id != package.id)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
    }
  }

  /// OCR daty dla konkretnego opakowania
  Future<void> _takeDatePhotoForPackage(
    BuildContext context,
    MedicinePackage package,
  ) async {
    final imagePicker = ImagePicker();
    final dateOcrService = DateOcrService();

    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rozpoznaję datę...'),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await dateOcrService.recognizeDate(File(pickedFile.path));

      if (mounted) Navigator.of(context).pop();

      if (result.terminWaznosci == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się rozpoznać daty. Spróbuj ponownie.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Aktualizuj konkretne opakowanie
      final updatedPackage = package.copyWith(
        expiryDate: result.terminWaznosci,
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService.saveMedicine(updatedMedicine);

      setState(() {
        _medicine = updatedMedicine;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data ważności ustawiona: ${_formatDate(result.terminWaznosci!)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DateOcrException catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Sekcja ulotki PDF z wyszukiwarką lub przyciskami akcji
  Widget _buildLeafletSection(BuildContext context) {
    final hasLeaflet =
        _medicine.leafletUrl != null && _medicine.leafletUrl!.isNotEmpty;

    return _buildSection(
      context,
      title: 'Ulotka',
      child: hasLeaflet
          ? _buildLeafletActions(context)
          : _buildLeafletSearchButton(context),
    );
  }

  /// Przyciski gdy ulotka jest przypisana
  Widget _buildLeafletActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const Spacer(),
        GestureDetector(
          onTap: () => _detachLeaflet(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Icon(LucideIcons.pinOff, size: 20, color: AppColors.expired),
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

  /// Dialog z wyjaśnieniem ikon w sekcji Termin ważności
  void _showIconsHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.lightbulb, color: AppColors.expiringSoon),
            const SizedBox(width: 8),
            const Text('Objaśnienie ikon'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconExplanation(
              context,
              LucideIcons.camera,
              'Rozpoznaj datę ze zdjęcia (OCR)',
            ),
            const SizedBox(height: 12),
            _buildIconExplanation(
              context,
              LucideIcons.calendarCog,
              'Edytuj datę ważności ręcznie',
            ),
            const SizedBox(height: 12),
            _buildIconExplanation(
              context,
              LucideIcons.blocks,
              'Określ pozostałą ilość w opakowaniu',
            ),
            const SizedBox(height: 12),
            _buildIconExplanation(
              context,
              LucideIcons.packagePlus,
              'Dodaj nowe opakowanie',
            ),
            const SizedBox(height: 12),
            _buildIconExplanation(
              context,
              LucideIcons.trash2,
              'Usuń opakowanie',
              color: AppColors.expired,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconExplanation(
    BuildContext context,
    IconData icon,
    String description, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Sekcja "Usuń lek" na dole karty
  Widget _buildDeleteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek - tylko tekst
        Text(
          'Usuń lek',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6b7280),
          ),
        ),
        const SizedBox(height: 12),
        // Podpowiedź lightbulb
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.expiringSoon.withAlpha(20)
                : AppColors.expiringSoon.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.expiringSoon.withAlpha(50)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.lightbulb,
                size: 18,
                color: AppColors.expiringSoon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jeśli chcesz usunąć tylko jedno opakowanie, przejdź do sekcji "Termin ważności"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Przycisk usunięcia
        NeuButton(
          onPressed: widget.onDelete,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.trash2, size: 16, color: AppColors.expired),
              const SizedBox(width: 8),
              Text(
                'Usuń cały lek z apteczki',
                style: TextStyle(
                  color: AppColors.expired,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return LucideIcons.circleX;
      case ExpiryStatus.expiringSoon:
        return LucideIcons.triangleAlert;
      case ExpiryStatus.valid:
        return LucideIcons.circleCheck;
      case ExpiryStatus.unknown:
        return LucideIcons.circleOff;
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
