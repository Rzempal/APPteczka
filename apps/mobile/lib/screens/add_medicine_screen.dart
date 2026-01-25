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
import '../services/gemini_shelf_life_service.dart';
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
import '../utils/pharmaceutical_form_helper.dart';

/// Akcja importu kopii zapasowej
enum _ImportAction { add, overwrite, cancel }

/// Status przetwarzania AI dla leku oczekującego
enum ProcessingStatus { pending, processing, completed, error }

/// Lek oczekujący na zapis (Batch Mode)

class PendingDrug {
  final RplDrugDetails drugDetails;
  final RplPackage selectedPackage;
  final DateTime addedAt;
  // Kopia nazwy z momentu tworzenia - zabezpieczenie przed utratą danych
  final String _cachedName;
  final String _cachedPower;

  // === Background processing fields ===
  ProcessingStatus processingStatus = ProcessingStatus.pending;
  String? processedName; // Poprawiona nazwa z AI
  String? processedDescription; // Opis z AI
  List<String>? processedTags; // Tagi z AI
  List<String>? processedWskazania; // Wskazania z AI

  PendingDrug({
    required this.drugDetails,
    required this.selectedPackage,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now(),
       _cachedName = drugDetails.name,
       _cachedPower = drugDetails.power;

  /// Nazwa leku z fallbackiem do cache (używa przetworzonej nazwy gdy dostępna)
  String get displayName {
    // Jeśli AI przetworzyło nazwę, użyj jej
    if (processedName != null && processedName!.isNotEmpty) {
      return processedName!;
    }
    if (drugDetails.fullName.isNotEmpty) {
      return drugDetails.fullName;
    }
    // Fallback do zbuforowanej nazwy
    if (_cachedName.isNotEmpty) {
      if (_cachedPower.isNotEmpty) {
        return '$_cachedName $_cachedPower';
      }
      return _cachedName;
    }
    return 'Nieznany lek (id: ${drugDetails.id})';
  }

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
  bool _heroExpanded = false; // 0. Hero info (domyślnie zwinięty)
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
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: KartonOpenIcon(size: 24, isDark: isDark),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Dodaj leki'),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info - akordeon z podpowiedziami
                _buildHeroAccordion(theme, isDark),

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
                  subtitle:
                      'Wybierz plik kopii zapasowej, aby przywrócić zawartość apteczki.',
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
      decoration: NeuDecoration.flat(
        isDark: isDark,
        borderRadius: AppTheme.organicRadiusSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
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

  // ================== SEKCJA HERO AKORDEON ==================

  /// Buduje akordeon Hero z podpowiedziami o metodach dodawania
  Widget _buildHeroAccordion(ThemeData theme, bool isDark) {
    final lightbulbColor = _heroExpanded ? Colors.amber.shade600 : Colors.grey;

    return Container(
      decoration: NeuDecoration.flat(
        isDark: isDark,
        borderRadius: AppTheme.organicRadiusSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header - klikalne
          InkWell(
            onTap: () => setState(() => _heroExpanded = !_heroExpanded),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  NeuInsetContainer(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      LucideIcons.lightbulb,
                      size: 24,
                      color: lightbulbColor,
                    ),
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
                          'Wybierz sposób dodania leków do apteczki.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _heroExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Zawartość rozwijana - podpowiedzi
          if (_heroExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tryb skanowania
                  Text(
                    'Tryb skanowania:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHeroTip(
                    theme,
                    'Skanuj kod z opakowania – najszybszy sposób dodania leku. Aplikacja spróbuje rozpoznać lek automatycznie.',
                  ),
                  const SizedBox(height: 4),
                  _buildHeroTip(
                    theme,
                    'Zrób zdjęcie opakowania – AI rozpozna nazwę leku ze zdjęcia.',
                  ),

                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Tryb ręczny
                  Text(
                    'Tryb ręczny:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHeroTip(
                    theme,
                    'Wyszukaj lek ręcznie w Rejestrze Produktów Leczniczych i dodaj go do apteczki.',
                  ),

                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Backup tip
                  Text(
                    'Wykonuj regularnie kopię zapasową apteczki',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Ustawienia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kopia zapasowa',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildHeroTip(
                    theme,
                    'Dane są przechowywane lokalnie na Twoim telefonie. Odinstalowanie aplikacji lub wyczyszczenie jej danych spowoduje utratę zawartości apteczki.',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Buduje pojedynczą podpowiedź w akordeon Hero
  Widget _buildHeroTip(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // ================== SEKCJA SKANER KODÓW KRESKOWYCH ==================

  /// Buduje sekcję skanera kodów kreskowych z ikoną kaskadową (barcode + AI)
  Widget _buildBarcodeScannerSection(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Container(
      decoration: NeuDecoration.flat(
        isDark: isDark,
        borderRadius: AppTheme.organicRadiusSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header z ikoną kaskadową
          InkWell(
            onTap: () => setState(() => _barcodeExpanded = !_barcodeExpanded),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ikona kaskadowa: scanSearch + AI sparkles
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.scanSearch,
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
                          'Zeskanuj lek',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Zeskanuj kod z opakowania, aby rozpoznać lek.',
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
      decoration: NeuDecoration.flat(
        isDark: isDark,
        borderRadius: AppTheme.organicRadiusSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header z ikoną kaskadową
          InkWell(
            onTap: () => _toggleManualSection(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
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
                          LucideIcons.textSearch,
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
                          'Wyszukaj lek',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Wpisz nazwę leku, aby wyszukać go w Rejestrze Produktów Leczniczych.',
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
          'Wybierz plik kopii zapasowej z urządzenia.',
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

  /// Zwraca kolor tła dla ikony statusu przetwarzania
  Color _getStatusColor(ProcessingStatus status, bool isDark) {
    switch (status) {
      case ProcessingStatus.pending:
        return Colors.blue.withAlpha(isDark ? 50 : 30);
      case ProcessingStatus.processing:
        return Colors.orange.withAlpha(isDark ? 50 : 30);
      case ProcessingStatus.completed:
        return Colors.green.withAlpha(isDark ? 50 : 30);
      case ProcessingStatus.error:
        return Colors.red.withAlpha(isDark ? 50 : 30);
    }
  }

  /// Buduje ikonę statusu przetwarzania
  Widget _buildStatusIcon(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.pending:
        return const Icon(LucideIcons.clock, size: 20, color: Colors.blue);
      case ProcessingStatus.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        );
      case ProcessingStatus.completed:
        return const Icon(LucideIcons.sparkles, size: 20, color: Colors.green);
      case ProcessingStatus.error:
        return const Icon(LucideIcons.circleAlert, size: 20, color: Colors.red);
    }
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
          // Ikona statusu przetwarzania AI
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(drug.processingStatus, isDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildStatusIcon(drug.processingStatus),
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
      // Przekazujemy result.nazwa i result.postac jako fallback gdy API details nie zwraca tych pól
      _log.fine('Fetching drug details for id: ${result.id}');
      final details = await _rplService.fetchDetailsById(
        result.id,
        knownName: result.nazwa,
        knownForm: result.postac,
      );

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

        // DEBUG: Loguj szczegóły selection.drugDetails przed tworzeniem PendingDrug
        _log.fine(
          'selection.drugDetails: name="${selection.drugDetails.name}", '
          'power="${selection.drugDetails.power}", '
          'fullName="${selection.drugDetails.fullName}", id=${selection.drugDetails.id}',
        );

        // BATCH MODE: Dodaj do listy oczekujących
        final pendingDrug = PendingDrug(
          drugDetails: selection.drugDetails,
          selectedPackage: selection.selectedPackage,
        );

        // DEBUG: Weryfikuj że PendingDrug ma poprawne dane
        _log.fine(
          'PendingDrug created: displayName="${pendingDrug.displayName}", '
          'drugDetails.name="${pendingDrug.drugDetails.name}"',
        );

        setState(() {
          _pendingDrugs.add(pendingDrug);
        });

        // === BACKGROUND PROCESSING TRIGGER ===
        // Jeśli lista > 3, uruchom przetwarzanie dla najstarszego edytowalnego
        if (_pendingDrugs.length > 3) {
          final indexToProcess =
              _pendingDrugs.length -
              4; // lek który właśnie stracił edytowalność
          _startBackgroundProcessing(indexToProcess);
        }

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

  /// Uruchamia przetwarzanie AI w tle dla leku o danym indeksie
  Future<void> _startBackgroundProcessing(int index) async {
    if (index < 0 || index >= _pendingDrugs.length) return;

    final drug = _pendingDrugs[index];

    // Sprawdź czy lek nie jest już przetwarzany
    if (drug.processingStatus != ProcessingStatus.pending) {
      _log.fine('Drug at index $index already processed/processing');
      return;
    }

    _log.info(
      'Starting background processing for drug at index $index: ${drug.displayName}',
    );

    // Ustaw status na processing
    setState(() {
      drug.processingStatus = ProcessingStatus.processing;
    });

    try {
      final geminiService = GeminiNameLookupService();
      final result = await geminiService.lookupByName(drug.displayName);

      // Sprawdź czy lek nadal istnieje na liście (mógł być usunięty)
      if (index >= _pendingDrugs.length || _pendingDrugs[index] != drug) {
        _log.fine('Drug was removed during processing, skipping update');
        return;
      }

      if (result.found && result.medicine != null) {
        final med = result.medicine!;
        setState(() {
          drug.processingStatus = ProcessingStatus.completed;
          drug.processedName = med.nazwa;
          drug.processedDescription = med.opis;
          drug.processedTags = med.tagi;
          drug.processedWskazania = med.wskazania;
        });
        _log.info('Background processing completed for: ${drug.displayName}');
      } else {
        // AI nie rozpoznało - ustaw jako completed bez danych
        setState(() {
          drug.processingStatus = ProcessingStatus.completed;
        });
        _log.fine('AI did not recognize drug: ${drug.displayName}');
      }
    } catch (e) {
      _log.warning('Background processing error: $e');
      if (mounted &&
          index < _pendingDrugs.length &&
          _pendingDrugs[index] == drug) {
        setState(() {
          drug.processingStatus = ProcessingStatus.error;
        });
      }
    }
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
  /// Batch processing: OCR nazw + OCR dat + AI enrichment
  void _handleBarcodeResult(List<ScannedDrug> drugs) async {
    if (drugs.isEmpty) return;

    // Oblicz liczbę etapów (3 dla produktów spoza RPL, 2 dla produktów z RPL)
    final unknownDrugs = drugs.where((d) => !d.isFromRpl).toList();
    final totalSteps = drugs.length * 2 + unknownDrugs.length;

    // Pokaz dialog przetwarzania
    final progressNotifier = ValueNotifier<_ProcessingProgress>(
      _ProcessingProgress(current: 0, total: totalSteps, stage: 'OCR'),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProcessingDialog(progress: progressNotifier),
    );

    final dateOcrService = DateOcrService();
    final geminiService = GeminiNameLookupService();
    final geminiOcrService = GeminiService(); // Do OCR nazw produktów
    final importedMedicines = <Medicine>[];
    final failedOcrDrugs = <ScannedDrug>[];

    try {
      // === ETAP 0: Batch OCR nazw produktów (dla brak RPL) ===
      if (unknownDrugs.isNotEmpty) {
        progressNotifier.value = progressNotifier.value.copyWith(
          stage: 'Nazwy',
        );
        await Future.wait(
          unknownDrugs.map((drug) async {
            if (drug.tempProductImagePath != null) {
              try {
                final result = await geminiOcrService.scanImage(
                  File(drug.tempProductImagePath!),
                );
                if (result.leki.isNotEmpty) {
                  final scanned = result.leki.first;
                  drug.scannedName = scanned.nazwa;
                  drug.scannedDescription = scanned.opis;
                  drug.scannedTags = scanned.tagi;
                  drug.scannedPower = scanned.power;
                  drug.scannedCapacity = scanned.capacity;
                  drug.scannedProductType = scanned.productType;
                  drug.scannedPharmaceuticalForm = scanned.postacFarmaceutyczna;
                }
              } catch (_) {
                // OCR nazwy nie powiodło się - produkt zostanie jako "Nieznany"
              }
            }
            progressNotifier.value = progressNotifier.value.increment();
          }),
        );
      }

      // === ETAP 1: Batch OCR dat (rownolegle) ===
      progressNotifier.value = progressNotifier.value.copyWith(stage: 'Daty');
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
            // === OPTIMIZATION: Sprawdź cached AI data z background processing ===
            String? aiOpis;
            List<String>? aiWskazania;
            List<String>? aiTagi;
            bool aiFound = false;

            if (drug.processingStatus == ScanProcessingStatus.completed &&
                drug.aiDescription != null) {
              // Użyj cached data z background processing
              _log.fine('Using cached AI data for: ${drug.displayName}');
              aiOpis = drug.aiDescription;
              aiWskazania = drug.aiWskazania;
              aiTagi = drug.aiTags;
              aiFound = true;
            } else {
              // Odpytaj Gemini (dla pending/error/niezakończonych)
              _log.fine('Querying Gemini for: ${drug.displayName}');
              final result = await geminiService.lookupByName(drug.displayName);
              if (result.found && result.medicine != null) {
                aiOpis = result.medicine!.opis;
                aiWskazania = result.medicine!.wskazania;
                aiTagi = result.medicine!.tagi;
                aiFound = true;
              }
            }

            if (aiFound) {
              // Tworzymy Medicine z polaczeniem danych z RPL i AI
              final form = drug.drugInfo?.form;
              final medicine = Medicine(
                id: const Uuid().v4(),
                nazwa: drug.displayName,
                opis: aiOpis ?? '',
                wskazania: aiWskazania ?? [],
                tagi: <String>{
                  ...drug
                      .toMedicine('')
                      .tagi, // tagi z RPL (Rp/OTC, forma, substancje)
                  ...processTagsForImport(aiTagi ?? []), // tagi z AI
                }.toList(), // usun duplikaty
                packages: drug.expiryDate != null
                    ? [
                        MedicinePackage(
                          expiryDate: drug.expiryDate!,
                          pieceCount: drug.pieceCount,
                          unit: PharmaceuticalFormHelper.getPackageUnit(form),
                        ),
                      ]
                    : [],
                dataDodania: DateTime.now().toIso8601String(),
                leafletUrl: drug.drugInfo?.leafletUrl,
                isVerifiedByBarcode: drug.isFromRpl,
                pharmaceuticalForm: form?.isNotEmpty == true ? form : null,
              );
              await widget.storageService.saveMedicine(medicine);
              _triggerShelfLifeAnalysis(
                medicine,
              ); // Auto-trigger shelf life analysis
              importedMedicines.add(medicine);
            } else {
              // AI nie rozpoznalo - zapisz tylko dane z RPL
              final medicine = drug.toMedicine(const Uuid().v4());
              // Force update isVerifiedByBarcode if it is from RPL
              final medicineWithVerification = medicine.copyWith(
                isVerifiedByBarcode: drug.isFromRpl,
              );
              await widget.storageService.saveMedicine(
                medicineWithVerification,
              );
              importedMedicines.add(medicineWithVerification);
            }
          } catch (_) {
            // Blad AI - zapisz tylko dane z RPL
            final medicine = drug.toMedicine(const Uuid().v4());
            // Force update isVerifiedByBarcode if it is from RPL
            final medicineWithVerification = medicine.copyWith(
              isVerifiedByBarcode: drug.isFromRpl,
            );
            await widget.storageService.saveMedicine(medicineWithVerification);
            importedMedicines.add(medicineWithVerification);
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
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final filePath = result.files.single.path!;
      final fileName = filePath.toLowerCase();

      // Walidacja rozszerzenia
      if (!fileName.endsWith('.json') && !fileName.endsWith('.karton')) {
        _showError(
          'Nieobsługiwany format pliku. Wybierz plik .json lub .karton',
        );
        return;
      }

      final file = File(filePath);
      final content = await file.readAsString();

      final medicines = await _parseJsonAndImportLabels(content);

      if (medicines.isEmpty) {
        throw const FormatException('Brak leków w pliku');
      }

      final action = await _showImportActionDialog(medicines.length);

      if (action == null || action == _ImportAction.cancel) {
        return;
      }

      if (action == _ImportAction.overwrite) {
        // Nadpisz - usuń wszystkie istniejące leki
        await widget.storageService.clearMedicines();
      }

      // Dodaj nowe leki
      await widget.storageService.importMedicines(medicines);

      if (mounted) {
        final actionText = action == _ImportAction.overwrite
            ? 'Nadpisano apteczkę'
            : 'Dodano ${medicines.length} leków z pliku';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actionText),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  /// Dialog wyboru akcji importu (3 opcje)
  Future<_ImportAction?> _showImportActionDialog(int count) {
    String getPolishPlural(int count) {
      if (count == 1) return 'lek';
      if (count >= 2 && count <= 4) return 'leki';
      if (count >= 12 && count <= 14) return 'leków';
      final lastDigit = count % 10;
      if (lastDigit >= 2 && lastDigit <= 4) return 'leki';
      return 'leków';
    }

    return showDialog<_ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.fileInput, size: 32),
        title: const Text('Import kopii zapasowej'),
        content: Text(
          'Plik zawiera $count ${getPolishPlural(count)}.\nCo chcesz zrobić?',
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ImportAction.cancel),
            child: const Text('Anuluj'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _ImportAction.overwrite),
            child: const Text('Nadpisz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ImportAction.add),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  /// Zapisuje wszystkie leki z listy oczekujących (Batch Mode)
  Future<void> _saveBatchMedicines() async {
    if (_pendingDrugs.isEmpty) return;

    _log.info('Starting batch save of ${_pendingDrugs.length} medicines');

    // DEBUG: Loguj szczegóły wszystkich leków przed zapisem
    for (int i = 0; i < _pendingDrugs.length; i++) {
      final pd = _pendingDrugs[i];
      _log.fine(
        'Pending[$i]: name="${pd.drugDetails.name}", '
        'power="${pd.drugDetails.power}", '
        'fullName="${pd.drugDetails.fullName}", '
        'id=${pd.drugDetails.id}',
      );
    }

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

          // Pobierz nazwę leku z fallbackami
          final drugName = rpl.fullName.isNotEmpty
              ? rpl.fullName
              : rpl.name.isNotEmpty
              ? rpl.name
              : pendingDrug.displayName;

          _log.fine(
            'Processing drug: name="$drugName" '
            '(rpl.fullName="${rpl.fullName}", rpl.name="${rpl.name}", '
            'displayName="${pendingDrug.displayName}")',
          );

          // Walidacja - pomijaj leki bez nazwy
          if (drugName.isEmpty) {
            _log.warning('Skipping drug with empty name, id=${rpl.id}');
            continue;
          }

          // === OPTIMIZATION: Użyj cached AI data jeśli dostępne ===
          String? aiOpis;
          List<String>? aiWskazania;
          List<String>? aiTagi;

          if (pendingDrug.processingStatus == ProcessingStatus.completed &&
              pendingDrug.processedDescription != null) {
            // Użyj cached data z background processing
            _log.fine('Using cached AI data for: $drugName');
            aiOpis = pendingDrug.processedDescription;
            aiWskazania = pendingDrug.processedWskazania;
            aiTagi = pendingDrug.processedTags;
          } else {
            // Odpytaj Gemini (dla pending/error)
            _log.fine('Querying Gemini for: $drugName');
            final aiResult = await geminiService.lookupByName(drugName);
            if (aiResult.found && aiResult.medicine != null) {
              aiOpis = aiResult.medicine!.opis;
              aiWskazania = aiResult.medicine!.wskazania;
              aiTagi = aiResult.medicine!.tagi;
            }
          }

          // Generuj tagi z RPL
          final rplTags = _generateTagsFromRpl(rpl, pkg);

          final medicine = Medicine(
            id: const Uuid().v4(),
            nazwa: drugName,
            opis: aiOpis ?? rpl.form,
            wskazania: aiWskazania ?? [],
            tagi: <String>{
              ...rplTags,
              ...processTagsForImport(aiTagi ?? []),
            }.toList(),

            // Opakowanie z pieceCount z RPL - data będzie ustawiona przez BatchDateInputSheet
            packages: [
              MedicinePackage(
                expiryDate: '',
                pieceCount: _parsePackaging(pkg.packaging),
                unit: PharmaceuticalFormHelper.getPackageUnit(rpl.form),
              ),
            ],
            dataDodania: DateTime.now().toIso8601String(),
            leafletUrl: rpl.leafletUrl,
            // Manual entry via RPL search is considered verified
            isVerifiedByBarcode: true,
            pharmaceuticalForm: rpl.form.isNotEmpty ? rpl.form : null,
          );

          await widget.storageService.saveMedicine(medicine);
          _triggerShelfLifeAnalysis(
            medicine,
          ); // Auto-trigger shelf life analysis
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

  /// Parsuje packaging na ilość sztuk
  /// Np. "28 tabl. (2 x 14)" -> 28, "1 butelka 120 ml" -> 120
  /// Skopiowane z barcode_scanner.dart dla spójności
  int? _parsePackaging(String? packaging) {
    if (packaging == null || packaging.isEmpty) return null;

    final lower = packaging.toLowerCase();

    // Wzorzec 1: "28 tabl.", "30 kaps.", "10 amp."
    final countMatch = RegExp(
      r'^(\d+)\s*(tabl|kaps|amp|sasz|czop|plast)',
    ).firstMatch(lower);
    if (countMatch != null) {
      return int.tryParse(countMatch.group(1)!);
    }

    // Wzorzec 2: "1 butelka 120 ml", "1 tuba 30 g"
    final volumeMatch = RegExp(r'(\d+)\s*(ml|g)\b').firstMatch(lower);
    if (volumeMatch != null) {
      return int.tryParse(volumeMatch.group(1)!);
    }

    // Wzorzec 3: pierwsza liczba
    final firstNumber = RegExp(r'(\d+)').firstMatch(lower);
    if (firstNumber != null) {
      return int.tryParse(firstNumber.group(1)!);
    }

    return null;
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

  /// Uruchamia analizę shelf life dla leku z ulotką
  Future<void> _triggerShelfLifeAnalysis(Medicine medicine) async {
    // Sprawdź czy lek ma ulotkę
    if (medicine.leafletUrl == null || medicine.leafletUrl!.isEmpty) {
      return;
    }

    // Sprawdź czy analiza już została wykonana lub jest w trakcie
    if (medicine.shelfLifeStatus == 'completed' ||
        medicine.shelfLifeStatus == 'pending' ||
        medicine.shelfLifeStatus == 'manual') {
      return;
    }

    _log.info('Triggering shelf life analysis for medicine: ${medicine.nazwa}');

    // Ustaw status na "pending" i zapisz
    final medicineWithPendingStatus = medicine.copyWith(
      shelfLifeStatus: 'pending',
    );
    await widget.storageService.saveMedicine(medicineWithPendingStatus);

    // Uruchom analizę w tle (fire and forget)
    _analyzeShelfLifeInBackground(medicineWithPendingStatus);
  }

  /// Analizuje shelf life w tle i aktualizuje wynik
  Future<void> _analyzeShelfLifeInBackground(Medicine medicine) async {
    try {
      final service = GeminiShelfLifeService();
      final result = await service.analyzeLeaflet(medicine.leafletUrl!);

      if (result.found) {
        // Znaleziono informację o shelf life
        final updatedMedicine = medicine.copyWith(
          shelfLifeAfterOpening: result.shelfLife,
          shelfLifeStatus: 'completed',
        );
        await widget.storageService.saveMedicine(updatedMedicine);
        _log.info('Shelf life analysis completed: ${result.period}');
      } else {
        // Nie znaleziono w ulotce (to nie jest błąd)
        final updatedMedicine = medicine.copyWith(shelfLifeStatus: 'not_found');
        await widget.storageService.saveMedicine(updatedMedicine);
        _log.info('Shelf life not found in leaflet: ${result.reason}');
      }
    } catch (e) {
      _log.severe('Error analyzing shelf life: $e');
      // Oznacz jako błąd
      final updatedMedicine = medicine.copyWith(shelfLifeStatus: 'error');
      await widget.storageService.saveMedicine(updatedMedicine);
    }
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
