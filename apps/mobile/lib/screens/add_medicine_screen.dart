import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/gemini_name_lookup_service.dart';
import '../services/date_ocr_service.dart';
import '../services/rpl_service.dart';
import '../services/app_logger.dart';
import '../widgets/barcode_scanner.dart';
import '../widgets/karton_icons.dart';
import '../widgets/batch_date_input_sheet.dart';
import '../widgets/rpl_autocomplete.dart';
import '../widgets/rpl_package_selector.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../theme/app_theme.dart';
import '../utils/tag_normalization.dart';

/// Lek oczekujący na zapis (Batch Mode)
class PendingDrug {
  final RplDrugDetails drugDetails;
  final RplPackage selectedPackage;
  final DateTime addedAt;

  PendingDrug({
    required this.drugDetails,
    required this.selectedPackage,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  String get displayName => drugDetails.fullName;
  String get packaging => selectedPackage.packaging;
  String get gtin => selectedPackage.gtin;
}

/// Ekran dodawania leków - wszystkie metody importu
class AddMedicineScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(String?)? onError;

  const AddMedicineScreen({
    super.key,
    required this.storageService,
    this.onError,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  static final Logger _log = AppLogger.getLogger('AddMedicineScreen');

  // Formularz ręczny
  final _formKey = GlobalKey<FormState>();
  final _nazwaController = TextEditingController();
  bool _isSaving = false;

  // Batch Mode - lista kolejkowanych leków
  final RplService _rplService = RplService();
  final List<PendingDrug> _pendingDrugs = [];

  // Flaga blokująca callbacks podczas async wyboru opakowania
  bool _isProcessingRplSelection = false;

  // Import z pliku
  bool _isImporting = false;

  // Expanded sections
  bool _barcodeExpanded =
      true; // 1. Skaner kodów kreskowych (domyślnie rozwinięty)
  bool _manualExpanded = false; // 2. Dodaj ręcznie
  bool _fileExpanded = false; // 3. Import kopii

  @override
  void dispose() {
    _nazwaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Dodaj leki'),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info
                Container(
                  decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        NeuInsetContainer(
                          borderRadius: 12,
                          padding: const EdgeInsets.all(12),
                          child: KartonOpenIcon(size: 32, isDark: isDark),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wybierz metodę dodawania',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Możesz skanować zdjęcia, wczytać kopię zapasową lub dodać ręcznie',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 1. Skaner kodów kreskowych (wspomagany AI)
                _buildBarcodeScannerSection(theme, isDark),

                const SizedBox(height: 12),

                // 2. Dodaj ręcznie (z AI)
                _buildManualEntrySection(theme, isDark),

                const SizedBox(height: 12),

                // 3. Import z pliku
                _buildExpandableSection(
                  icon: LucideIcons.folderDown,
                  title: 'Import kopii zapasowej',
                  subtitle: 'Wczytaj kopię zapasową z urządzenia',
                  isExpanded: _fileExpanded,
                  onToggle: () =>
                      setState(() => _fileExpanded = !_fileExpanded),
                  child: _buildFileImportSection(theme, isDark),
                  isDark: isDark,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          // Gradient fade-out na dole
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground)
                          .withAlpha(0),
                      isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    required bool isDark,
    Color? iconColor, // Optional custom icon color (for AI sections)
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  // ================== SEKCJA SKANER KODÓW KRESKOWYCH ==================

  /// Buduje sekcję skanera kodów kreskowych z ikoną kaskadową (barcode + AI)
  Widget _buildBarcodeScannerSection(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header z ikoną kaskadową
          InkWell(
            onTap: () => setState(() => _barcodeExpanded = !_barcodeExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ikona kaskadowa: barcode + AI sparkles
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.barcode,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              LucideIcons.sparkles,
                              color: aiColor,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skaner kodów kreskowych',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Dodaj lek skanując kod kreskowy i datę ważności swoim aparatem',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _barcodeExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Zawartość rozwijana - skaner
          if (_barcodeExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: BarcodeScannerWidget(
                onComplete: _handleBarcodeResult,
                onError: widget.onError,
              ),
            ),
        ],
      ),
    );
  }

  /// Buduje sekcję ręcznego dodawania z ikoną kaskadową (pencil + AI)
  Widget _buildManualEntrySection(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header z ikoną kaskadową
          InkWell(
            onTap: () => _toggleManualSection(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ikona kaskadowa: pencil (zielony) + AI sparkles
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              LucideIcons.sparkles,
                              color: aiColor,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dodaj ręcznie',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Wpisz nazwę leku - AI uzupełni resztę',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _manualExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Zawartość rozwijana - formularz
          if (_manualExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildManualForm(theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildFileImportSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Wybierz plik z kopią zapasową.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isImporting ? null : _importFromFile,
          icon: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.folderOpen),
          label: const Text('Wybierz plik'),
        ),
      ],
    );
  }

  Widget _buildManualForm(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pole wyszukiwania (tylko do wyszukiwania, bez walidacji)
          RplAutocomplete(
            controller: _nazwaController,
            labelText: 'Wyszukaj lek',
            hintText: 'np. Paracetamol, Apap...',
            onSelected: _onRplMedicineSelected,
            onTextChanged: (text) {
              // Ignoruj zmiany podczas async wyboru opakowania (race condition fix)
              if (_isProcessingRplSelection) {
                _log.fine('onTextChanged ignored - RPL selection in progress');
                return;
              }
            },
            // Brak walidatora - pole służy tylko do wyszukiwania
          ),

          const SizedBox(height: 16),

          // Lista oczekujących leków (Batch Mode)
          if (_pendingDrugs.isNotEmpty) ...[
            _buildPendingDrugsList(theme, isDark),
            const SizedBox(height: 16),
          ],

          // Przycisk zapisu - aktywny tylko gdy są leki na liście
          FilledButton.icon(
            onPressed: _pendingDrugs.isEmpty || _isSaving
                ? null
                : _saveBatchMedicines,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(LucideIcons.sparkles, color: aiColor),
            label: Text(
              _pendingDrugs.isEmpty
                  ? 'Wybierz leki z listy'
                  : 'Zapisz ${_pendingDrugs.length} lek${_pendingDrugs.length == 1
                        ? ''
                        : _pendingDrugs.length < 5
                        ? 'i'
                        : 'ów'}',
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje listę oczekujących leków (karty z Badge RPL)
  Widget _buildPendingDrugsList(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header z liczbą leków i przyciskiem czyszczenia
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dodano (${_pendingDrugs.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_pendingDrugs.length > 1)
              TextButton.icon(
                onPressed: _clearPendingDrugs,
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  'Wyczyść',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista kart leków
        ...List.generate(_pendingDrugs.length, (index) {
          final drug = _pendingDrugs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPendingDrugCard(drug, index, theme, isDark),
          );
        }),
      ],
    );
  }

  /// Karta pojedynczego leku w liście oczekujących
  Widget _buildPendingDrugCard(
    PendingDrug drug,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final timeStr =
        '${drug.addedAt.hour.toString().padLeft(2, '0')}:${drug.addedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(80)),
      ),
      child: Row(
        children: [
          // Ikona weryfikacji RPL
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(isDark ? 50 : 30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 20,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),

          // Info o leku
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      LucideIcons.package,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        drug.packaging,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dodano: $timeStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Przycisk usunięcia
          IconButton(
            icon: Icon(LucideIcons.x, size: 18, color: theme.colorScheme.error),
            onPressed: () => _removePendingDrug(index),
            tooltip: 'Usuń z listy',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ==================== HANDLERS RPL ====================

  /// Handler po wybraniu leku z autocomplete RPL (Batch Mode)
  /// Dodaje lek do listy _pendingDrugs i czyści pole wyszukiwania
  Future<void> _onRplMedicineSelected(RplSearchResult result) async {
    _log.info(
      'RPL selection started: ${result.displayLabel} (id: ${result.id})',
    );

    // Ustaw flagę PRZED async operacjami - blokuje onTextChanged callbacks
    setState(() => _isProcessingRplSelection = true);

    try {
      // Pobierz szczegóły leku (z listą opakowań)
      _log.fine('Fetching drug details for id: ${result.id}');
      final details = await _rplService.fetchDetailsById(result.id);

      if (details == null) {
        _log.warning('Failed to fetch drug details for id: ${result.id}');
        _showError('Nie udało się pobrać szczegółów leku z RPL');
        return;
      }

      _log.fine(
        'Drug details fetched: ${details.fullName}, packages: ${details.packages.length}',
      );

      // Pokaż selector opakowań (jeśli więcej niż 1)
      if (!mounted) return;
      _log.fine('Showing package selector sheet');
      final selection = await RplPackageSelectorSheet.show(
        context: context,
        drugDetails: details,
      );

      if (selection != null) {
        _log.info(
          'Package selected: ${selection.selectedPackage.packaging} (GTIN: ${selection.selectedPackage.gtin})',
        );

        // BATCH MODE: Dodaj do listy oczekujących
        final pendingDrug = PendingDrug(
          drugDetails: selection.drugDetails,
          selectedPackage: selection.selectedPackage,
        );

        setState(() {
          _pendingDrugs.add(pendingDrug);
        });

        // Wyczyść pole wyszukiwania - gotowe na kolejny lek
        _nazwaController.clear();
        _log.info(
          'Drug added to pending list. Total pending: ${_pendingDrugs.length}',
        );

        // Haptic feedback
        HapticFeedback.lightImpact();
      } else {
        _log.fine('Package selection cancelled by user');
      }
    } finally {
      // ZAWSZE resetuj flagę - nawet przy błędach
      if (mounted) {
        setState(() => _isProcessingRplSelection = false);
        _log.fine('RPL selection processing completed');
      }
    }
  }

  /// Usuwa lek z listy oczekujących
  void _removePendingDrug(int index) {
    _log.info('Removing pending drug at index $index');
    setState(() {
      _pendingDrugs.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  /// Przełącza rozwinięcie sekcji ręcznego dodawania
  /// Z ochroną przed utratą niezapisanych leków
  Future<void> _toggleManualSection() async {
    // Jeśli rozwijamy - po prostu rozwiń
    if (!_manualExpanded) {
      setState(() => _manualExpanded = true);
      return;
    }

    // Jeśli zwijamy i są niezapisane leki - ostrzeż
    if (_pendingDrugs.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Porzucić zmiany?'),
          content: Text(
            'Na liście ${_pendingDrugs.length == 1 ? 'znajduje się' : 'znajdują się'} '
            '${_pendingDrugs.length} niezapisany${_pendingDrugs.length == 1 ? '' : 'ch'} '
            'lek${_pendingDrugs.length == 1
                ? ''
                : _pendingDrugs.length < 5
                ? 'i'
                : 'ów'}. '
            'Zwinięcie sekcji spowoduje ich utratę.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Wróć do edycji'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Porzuć i zwiń'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Użytkownik potwierdził - wyczyść i zwiń
      setState(() {
        _pendingDrugs.clear();
        _nazwaController.clear();
        _manualExpanded = false;
      });
      _log.info(
        'User confirmed discarding ${_pendingDrugs.length} pending drugs',
      );
      return;
    }

    // Brak niezapisanych leków - po prostu zwiń
    setState(() => _manualExpanded = false);
  }

  /// Czyści całą listę oczekujących (z potwierdzeniem)
  Future<void> _clearPendingDrugs() async {
    if (_pendingDrugs.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić listę?'),
        content: Text(
          'Czy na pewno chcesz usunąć ${_pendingDrugs.length} lek(ów) z listy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _pendingDrugs.clear();
      });
      _log.info('Pending drugs list cleared');
    }
  }

  // ==================== HANDLERS ====================

  /// Handler dla skanera kodów kreskowych (lista leków)
  /// Batch processing: OCR dat + AI enrichment
  void _handleBarcodeResult(List<ScannedDrug> drugs) async {
    if (drugs.isEmpty) return;

    // Pokaz dialog przetwarzania
    final progressNotifier = ValueNotifier<_ProcessingProgress>(
      _ProcessingProgress(current: 0, total: drugs.length * 2, stage: 'OCR'),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProcessingDialog(progress: progressNotifier),
    );

    final dateOcrService = DateOcrService();
    final geminiService = GeminiNameLookupService();
    final importedMedicines = <Medicine>[];
    final failedOcrDrugs = <ScannedDrug>[];

    try {
      // === ETAP 1: Batch OCR dat (rownolegle) ===
      await Future.wait(
        drugs.map((drug) async {
          if (drug.tempImagePath != null && drug.expiryDate == null) {
            try {
              final result = await dateOcrService.recognizeDate(
                File(drug.tempImagePath!),
              );
              if (result.terminWaznosci != null) {
                drug.expiryDate = result.terminWaznosci;
              } else {
                failedOcrDrugs.add(drug);
              }
            } catch (_) {
              failedOcrDrugs.add(drug);
            }
          }
          progressNotifier.value = progressNotifier.value.increment();
        }),
      );

      // === ETAP 2: AI enrichment (rownolegle) ===
      progressNotifier.value = progressNotifier.value.copyWith(stage: 'AI');

      await Future.wait(
        drugs.map((drug) async {
          try {
            final result = await geminiService.lookupByName(
              drug.drugInfo.fullName,
            );
            if (result.found && result.medicine != null) {
              // Tworzymy Medicine z polaczeniem danych z RPL i AI
              final med = result.medicine!;
              final medicine = Medicine(
                id: const Uuid().v4(),
                nazwa: drug.drugInfo.fullName,
                opis: med.opis,
                wskazania: med.wskazania,
                tagi: <dynamic>{
                  ...drug
                      .toMedicine('')
                      .tagi, // tagi z RPL (Rp/OTC, forma, substancje)
                  ...processTagsForImport(med.tagi), // tagi z AI
                }.toList(), // usun duplikaty
                packages: drug.expiryDate != null
                    ? [
                        MedicinePackage(
                          expiryDate: drug.expiryDate!,
                          pieceCount: drug.pieceCount,
                        ),
                      ]
                    : [],
                dataDodania: DateTime.now().toIso8601String(),
                leafletUrl: drug.drugInfo.leafletUrl,
              );
              await widget.storageService.saveMedicine(medicine);
              importedMedicines.add(medicine);
            } else {
              // AI nie rozpoznalo - zapisz tylko dane z RPL
              final medicine = drug.toMedicine(const Uuid().v4());
              await widget.storageService.saveMedicine(medicine);
              importedMedicines.add(medicine);
            }
          } catch (_) {
            // Blad AI - zapisz tylko dane z RPL
            final medicine = drug.toMedicine(const Uuid().v4());
            await widget.storageService.saveMedicine(medicine);
            importedMedicines.add(medicine);
          }
          progressNotifier.value = progressNotifier.value.increment();
        }),
      );
    } finally {
      // Zamknij dialog przetwarzania
      if (mounted) Navigator.of(context).pop();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zaimportowano ${importedMedicines.length} lekow ze skanera',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pokaz dialog reczny dla lekow bez rozpoznanej daty
    final medicinesWithoutDate = importedMedicines
        .where((m) => m.packages.isEmpty || m.packages.first.expiryDate.isEmpty)
        .toList();

    if (medicinesWithoutDate.isNotEmpty) {
      BatchDateInputSheet.showIfNeeded(
        context: context,
        medicines: medicinesWithoutDate,
        storageService: widget.storageService,
        onComplete: () {},
      );
    }

    // Zwin sekcje skanera
    setState(() => _barcodeExpanded = false);
  }

  Future<void> _importFromFile() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      final medicines = await _parseJsonAndImportLabels(content);

      if (medicines.isEmpty) {
        throw const FormatException('Brak leków w pliku');
      }

      final confirmed = await _confirmImport(medicines.length);

      if (confirmed == true) {
        await widget.storageService.importMedicines(medicines);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zaimportowano ${medicines.length} leków z pliku'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Błąd importu pliku: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// Parsuje JSON i importuje leki + etykiety (jeśli są w backup)
  Future<List<Medicine>> _parseJsonAndImportLabels(String text) async {
    final data = jsonDecode(text);

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowy format JSON');
    }

    // Import etykiet (jeśli są w backup)
    final labelsRaw = data['labels'];
    if (labelsRaw is List && labelsRaw.isNotEmpty) {
      for (final item in labelsRaw) {
        if (item is Map<String, dynamic>) {
          try {
            final label = UserLabel.fromJson(item);
            await widget.storageService.saveLabel(label);
          } catch (_) {
            // Ignoruj uszkodzone etykiety
          }
        }
      }
    }

    // Import leków
    final lekiRaw = data['leki'];
    if (lekiRaw is! List) {
      throw const FormatException('Brak leków w pliku');
    }

    final medicines = <Medicine>[];
    for (final item in lekiRaw) {
      if (item is Map<String, dynamic>) {
        final medicineData = Map<String, dynamic>.from(item);
        if (medicineData['id'] == null) {
          medicineData['id'] = const Uuid().v4();
        }
        if (medicineData['dataDodania'] == null) {
          medicineData['dataDodania'] = DateTime.now().toIso8601String();
        }
        medicines.add(Medicine.fromJson(medicineData));
      }
    }

    return medicines;
  }

  Future<bool?> _confirmImport(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź import'),
        content: Text('Czy chcesz zaimportować $count leków?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importuj'),
          ),
        ],
      ),
    );
  }

  /// Zapisuje wszystkie leki z listy oczekujących (Batch Mode)
  Future<void> _saveBatchMedicines() async {
    if (_pendingDrugs.isEmpty) return;

    _log.info('Starting batch save of ${_pendingDrugs.length} medicines');
    setState(() => _isSaving = true);

    // Pokaz dialog przetwarzania
    final progressNotifier = ValueNotifier<_ProcessingProgress>(
      _ProcessingProgress(current: 0, total: _pendingDrugs.length, stage: 'AI'),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProcessingDialog(progress: progressNotifier),
    );

    final geminiService = GeminiNameLookupService();
    final savedMedicines = <Medicine>[];

    try {
      // Przetwarzaj każdy lek z listy
      for (final pendingDrug in _pendingDrugs) {
        try {
          final rpl = pendingDrug.drugDetails;
          final pkg = pendingDrug.selectedPackage;

          // AI uzupełnia opis, wskazania, tagi
          final aiResult = await geminiService.lookupByName(rpl.fullName);
          final aiMedicine = aiResult.found ? aiResult.medicine : null;

          // Generuj tagi z RPL
          final rplTags = _generateTagsFromRpl(rpl, pkg);

          final medicine = Medicine(
            id: const Uuid().v4(),
            nazwa: rpl.fullName,
            opis: aiMedicine?.opis ?? rpl.form,
            wskazania: aiMedicine?.wskazania ?? [],
            tagi: [
              ...rplTags,
              ...processTagsForImport(aiMedicine?.tagi ?? []),
            ].toSet().toList(),
            // Brak daty ważności - będzie ustawiona na końcu przez BatchDateInputSheet
            packages: [],
            dataDodania: DateTime.now().toIso8601String(),
            leafletUrl: rpl.leafletUrl,
          );

          await widget.storageService.saveMedicine(medicine);
          savedMedicines.add(medicine);
          _log.fine('Saved medicine: ${medicine.nazwa}');
        } catch (e) {
          _log.warning('Error saving medicine ${pendingDrug.displayName}: $e');
          // Kontynuuj z pozostałymi lekami
        }

        progressNotifier.value = progressNotifier.value.increment();
      }

      // Zamknij dialog przetwarzania
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (savedMedicines.isEmpty) {
        _showError('Nie udało się zapisać żadnego leku');
        return;
      }

      // Wyczyść listę oczekujących i pole wyszukiwania
      setState(() {
        _pendingDrugs.clear();
        _nazwaController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zapisano ${savedMedicines.length} lek(ów)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Pokaż dialog do ustawienia dat ważności (format MM/YYYY)
        BatchDateInputSheet.showIfNeeded(
          context: context,
          medicines: savedMedicines,
          storageService: widget.storageService,
          onComplete: () {
            _log.info('Batch date input completed');
          },
        );

        // Zwiń sekcję po zapisie
        setState(() => _manualExpanded = false);
      }
    } catch (e) {
      // Zamknij dialog jeśli jeszcze otwarty
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Błąd zapisu: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Generuje tagi na podstawie danych z RPL
  List<String> _generateTagsFromRpl(RplDrugDetails rpl, RplPackage? pkg) {
    final tags = <String>{};

    // Status recepty
    final category =
        pkg?.accessibilityCategory?.toUpperCase() ??
        rpl.accessibilityCategory?.toUpperCase();
    if (category == 'OTC') {
      tags.add('bez recepty');
    } else if (category == 'RP' || category == 'RPZ') {
      tags.add('na receptę');
    }

    // Postac farmaceutyczna
    if (rpl.form.isNotEmpty) {
      final formLower = rpl.form.toLowerCase();
      if (formLower.contains('tabletk')) {
        tags.add('tabletki');
      } else if (formLower.contains('kaps')) {
        tags.add('kapsułki');
      } else if (formLower.contains('syrop')) {
        tags.add('syrop');
      } else if (formLower.contains('masc') || formLower.contains('krem')) {
        tags.add('maść');
      } else if (formLower.contains('zastrzyk') ||
          formLower.contains('iniekcj')) {
        tags.add('zastrzyki');
      } else if (formLower.contains('krople')) {
        tags.add('krople');
      } else if (formLower.contains('aerozol') || formLower.contains('spray')) {
        tags.add('aerozol');
      } else if (formLower.contains('czopk')) {
        tags.add('czopki');
      } else if (formLower.contains('plast')) {
        tags.add('plastry');
      } else if (formLower.contains('zawies') ||
          formLower.contains('proszek')) {
        tags.add('proszek/zawiesina');
      }
    }

    // Substancje czynne
    if (rpl.activeSubstance.isNotEmpty) {
      final substances = rpl.activeSubstance
          .split(RegExp(r'\s*\+\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      tags.addAll(substances);
    }

    return tags.toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==================== POMOCNICZE KLASY PRZETWARZANIA ====================

/// Stan przetwarzania batch
class _ProcessingProgress {
  final int current;
  final int total;
  final String stage; // 'OCR' lub 'AI'

  const _ProcessingProgress({
    required this.current,
    required this.total,
    required this.stage,
  });

  _ProcessingProgress increment() {
    return _ProcessingProgress(
      current: current + 1,
      total: total,
      stage: stage,
    );
  }

  _ProcessingProgress copyWith({String? stage}) {
    return _ProcessingProgress(
      current: current,
      total: total,
      stage: stage ?? this.stage,
    );
  }

  double get progress => total > 0 ? current / total : 0;
}

/// Dialog przetwarzania z progressem (dla skanera)
class _ProcessingDialog extends StatelessWidget {
  final ValueNotifier<_ProcessingProgress> progress;

  const _ProcessingDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<_ProcessingProgress>(
          valueListenable: progress,
          builder: (context, prog, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  prog.stage == 'OCR'
                      ? LucideIcons.scanText
                      : LucideIcons.sparkles,
                  size: 48,
                  color: aiColor,
                ),
                const SizedBox(height: 16),
                Text(
                  prog.stage == 'OCR'
                      ? 'Rozpoznaje daty...'
                      : 'AI uzupelnia dane...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${prog.current} / ${prog.total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: prog.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(aiColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dialog przetwarzania AI (dla recznego dodawania)
class _AiProcessingDialog extends StatelessWidget {
  final String medicineName;

  const _AiProcessingDialog({required this.medicineName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 48, color: aiColor),
            const SizedBox(height: 16),
            Text(
              'AI rozpoznaje lek...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicineName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(aiColor),
            ),
          ],
        ),
      ),
    );
  }
}
