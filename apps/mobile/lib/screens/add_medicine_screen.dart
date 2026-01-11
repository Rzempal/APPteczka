import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/gemini_name_lookup_service.dart';
import '../services/date_ocr_service.dart';
import '../widgets/gemini_scanner.dart';
import '../widgets/barcode_scanner.dart';
import '../widgets/karton_icons.dart';
import '../widgets/batch_date_input_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../widgets/tag_selector_widget.dart';
import '../theme/app_theme.dart';
import '../utils/tag_normalization.dart';
import '../utils/ean_validator.dart';
import '../services/rpl_service.dart';

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
  // Formularz ręczny
  final _formKey = GlobalKey<FormState>();
  final _nazwaController = TextEditingController();
  final _opisController = TextEditingController();
  final _wskazaniaController = TextEditingController();
  List<String> _selectedTags = []; // Zamiana z TextFormField na selektor
  DateTime? _terminWaznosci;
  bool _isSaving = false;
  bool _isLookingUp = false; // AI name lookup

  // Import z pliku
  bool _isImporting = false;

  // Expanded sections - nowa kolejność
  bool _aiVisionExpanded = true; // 1. Gemini AI Vision
  bool _barcodeExpanded = false; // 2. Skanuj kod kreskowy
  bool _manualExpanded = false; // 3. Dodaj ręcznie
  bool _fileExpanded = false; // 4. Import kopii

  @override
  void dispose() {
    _nazwaController.dispose();
    _opisController.dispose();
    _wskazaniaController.dispose();
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

                // 1. Gemini AI Vision (połączone tryby)
                _buildAiVisionSection(theme, isDark),

                const SizedBox(height: 12),

                // 2. Skanuj kod kreskowy (EAN)
                _buildExpandableSection(
                  icon: LucideIcons.barcode,
                  title: 'Skanuj kod kreskowy',
                  subtitle: 'Ciagale skanowanie kodow EAN z apteczki',
                  isExpanded: _barcodeExpanded,
                  onToggle: () =>
                      setState(() => _barcodeExpanded = !_barcodeExpanded),
                  child: _buildBarcodeSection(theme, isDark),
                  isDark: isDark,
                  iconColor: theme.colorScheme.primary,
                ),

                const SizedBox(height: 12),

                // 3. Dodaj ręcznie (przesunięte)
                _buildExpandableSection(
                  icon: LucideIcons.pencil,
                  title: 'Dodaj ręcznie',
                  subtitle: 'Wprowadź dane leku samodzielnie',
                  isExpanded: _manualExpanded,
                  onToggle: () =>
                      setState(() => _manualExpanded = !_manualExpanded),
                  child: _buildManualForm(theme, isDark),
                  isDark: isDark,
                  iconColor: isDark
                      ? AppColors.aiAccentDark
                      : AppColors.aiAccentLight,
                ),

                const SizedBox(height: 12),

                // 4. Import z pliku (przesunięte)
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

  // ================== SEKCJA GEMINI AI VISION ==================

  Widget _buildAiVisionSection(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header główny - rozwijana sekcja
          InkWell(
            onTap: () => setState(() => _aiVisionExpanded = !_aiVisionExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, color: aiColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dodaj za pomocą Gemini AI Vision',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Zrób zdjęcie opakowań i pozwól AI rozpoznać leki',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _aiVisionExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Zawartość rozwijana - jeden tryb skanowania
          if (_aiVisionExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GeminiScanner(
                onResult: _handleGeminiResult,
                onError: widget.onError,
                onImportComplete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leki zostały zaimportowane!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ================== SEKCJA SKANER KODOW KRESKOWYCH ==================

  Widget _buildBarcodeSection(ThemeData theme, bool isDark) {
    return BarcodeScannerWidget(
      onComplete: _handleBarcodeResult,
      onError: widget.onError,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nazwa z przyciskiem Rozpoznaj
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nazwaController,
                  decoration: InputDecoration(
                    labelText: 'Nazwa leku *',
                    hintText: 'np. Paracetamol 500mg',
                    prefixIcon: const Icon(LucideIcons.pill),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj nazwę leku';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Przycisk Rozpoznaj AI
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isLookingUp ? null : _lookupByName,
                    icon: _isLookingUp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.sparkles, size: 18),
                    label: const Text('AI'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Opis
          TextFormField(
            controller: _opisController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Opis działania *',
              hintText: 'Krótki opis działania leku',
              prefixIcon: const Icon(LucideIcons.fileText),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Podaj opis leku';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Wskazania
          TextFormField(
            controller: _wskazaniaController,
            decoration: InputDecoration(
              labelText: 'Wskazania (oddzielone przecinkami)',
              hintText: 'ból głowy, gorączka',
              prefixIcon: const Icon(LucideIcons.clipboardList),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Tagi - selektor z listą
          TagSelectorWidget(
            selectedTags: _selectedTags,
            onChanged: (tags) => setState(() => _selectedTags = tags),
          ),

          const SizedBox(height: 16),

          // Termin ważności
          NeuInsetContainer(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Termin ważności',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        _terminWaznosci != null
                            ? '${_terminWaznosci!.day.toString().padLeft(2, '0')}.${_terminWaznosci!.month.toString().padLeft(2, '0')}.${_terminWaznosci!.year}'
                            : 'Nie ustawiono',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_terminWaznosci != null)
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => setState(() => _terminWaznosci = null),
                  ),
                IconButton(
                  icon: const Icon(LucideIcons.calendarDays),
                  onPressed: _selectDate,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Przycisk zapisu
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveMedicine,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: const Text('Zapisz lek'),
          ),
        ],
      ),
    );
  }

  // ==================== HANDLERS ====================

  void _handleGeminiResult(GeminiScanResult result) async {
    final importedMedicines = <Medicine>[];
    int verifiedCount = 0;
    final rplService = RplService();

    for (final lek in result.leki) {
      Medicine medicine;

      // Sprawdz czy mamy poprawny kod kreskowy
      final normalizedEan = EanValidator.normalize(lek.ean);

      if (normalizedEan != null) {
        // Probuj pobrac dane z RPL
        final rplInfo = await rplService.fetchDrugByEan(normalizedEan);

        if (rplInfo != null) {
          // Sukces - merge danych RPL + Gemini
          verifiedCount++;

          // Sprawdz czy nazwa z Gemini rozni sie od RPL (konflikt)
          String? verificationNote;
          if (lek.nazwa != null && lek.nazwa!.isNotEmpty) {
            final geminiNameLower = lek.nazwa!.toLowerCase().trim();
            final rplNameLower = rplInfo.name.toLowerCase().trim();
            // Jesli nazwa Gemini nie zawiera sie w nazwie RPL i odwrotnie
            if (!rplNameLower.contains(geminiNameLower) &&
                !geminiNameLower.contains(rplNameLower)) {
              verificationNote =
                  'Nazwa nie pasuje do kodu kreskowego, wyszukano po kodzie';
            }
          }

          // Buduj opis z danych RPL + Gemini
          final opisParts = <String>[];
          if (rplInfo.activeSubstance.isNotEmpty) {
            opisParts.add(rplInfo.activeSubstance);
          }
          if (rplInfo.form.isNotEmpty) {
            opisParts.add(rplInfo.form);
          }
          if (lek.opis.isNotEmpty) {
            opisParts.add(lek.opis);
          }
          final mergedOpis = opisParts.join('. ');

          // Generuj tagi z RPL (podobnie jak w barcode_scanner.dart)
          final rplTags = _generateRplTags(rplInfo);

          medicine = Medicine(
            id: const Uuid().v4(),
            nazwa: rplInfo.fullName, // RPL ma priorytet
            opis: mergedOpis,
            wskazania: lek.wskazania, // Gemini
            tagi: [
              ...rplTags, // Tagi z RPL (recepta, forma, substancje)
              ...processTagsForImport(lek.tagi), // Tagi z Gemini
            ].toSet().toList(), // Usun duplikaty
            terminWaznosci: lek.terminWaznosci, // Gemini (RPL nie ma dat)
            dataDodania: DateTime.now().toIso8601String(),
            leafletUrl: rplInfo.leafletUrl, // RPL
            isVerifiedByBarcode: true,
            verificationNote: verificationNote,
          );
        } else {
          // EAN poprawny ale nie znaleziono w RPL - uzyj danych Gemini
          medicine = Medicine(
            id: const Uuid().v4(),
            nazwa: lek.nazwa,
            opis: lek.opis,
            wskazania: lek.wskazania,
            tagi: processTagsForImport(lek.tagi),
            terminWaznosci: lek.terminWaznosci,
            dataDodania: DateTime.now().toIso8601String(),
          );
        }
      } else {
        // Brak EAN lub niepoprawny - uzyj danych Gemini (jak do tej pory)
        medicine = Medicine(
          id: const Uuid().v4(),
          nazwa: lek.nazwa,
          opis: lek.opis,
          wskazania: lek.wskazania,
          tagi: processTagsForImport(lek.tagi),
          terminWaznosci: lek.terminWaznosci,
          dataDodania: DateTime.now().toIso8601String(),
        );
      }

      await widget.storageService.saveMedicine(medicine);
      importedMedicines.add(medicine);
    }

    if (!mounted) return;

    // Snackbar z informacja o weryfikacji
    final snackMessage = verifiedCount > 0
        ? 'Zaimportowano ${importedMedicines.length} leków ($verifiedCount zweryfikowanych)'
        : 'Zaimportowano ${importedMedicines.length} leków z Gemini AI';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pokaż sheet do uzupełniania dat dla leków bez daty
    BatchDateInputSheet.showIfNeeded(
      context: context,
      medicines: importedMedicines,
      storageService: widget.storageService,
      onComplete: () {},
    );
  }

  /// Generuje tagi na podstawie danych z RPL (kopiowane z barcode_scanner.dart)
  List<String> _generateRplTags(RplDrugInfo drugInfo) {
    final tags = <String>{};

    // 1. Status recepty (accessibilityCategory)
    final category = drugInfo.accessibilityCategory?.toUpperCase();
    if (category != null) {
      if (category == 'OTC') {
        tags.add('bez recepty');
      } else if (category == 'RP' || category == 'RPZ') {
        tags.add('na receptę');
      }
    }

    // 2. Postac farmaceutyczna
    if (drugInfo.form.isNotEmpty) {
      final formLower = drugInfo.form.toLowerCase();
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

    // 3. Substancje czynne (dzielimy po " + ")
    if (drugInfo.activeSubstance.isNotEmpty) {
      final substances = drugInfo.activeSubstance
          .split(RegExp(r'\s*\+\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      tags.addAll(substances);
    }

    return tags.toList();
  }

  /// Handler dla skanera kodow kreskowych (lista lekow)
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
      await Future.wait(drugs.map((drug) async {
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
      }));

      // === ETAP 2: AI enrichment (rownolegle) ===
      progressNotifier.value = progressNotifier.value.copyWith(stage: 'AI');

      await Future.wait(drugs.map((drug) async {
        try {
          final result = await geminiService.lookupByName(drug.drugInfo.fullName);
          if (result.found && result.medicine != null) {
            // Tworzymy Medicine z polaczeniem danych z RPL i AI
            final med = result.medicine!;
            final medicine = Medicine(
              id: const Uuid().v4(),
              nazwa: drug.drugInfo.fullName,
              opis: med.opis,
              wskazania: med.wskazania,
              tagi: [
                ...drug.toMedicine('').tagi, // tagi z RPL (Rp/OTC, forma, substancje)
                ...processTagsForImport(med.tagi), // tagi z AI
              ].toSet().toList(), // usun duplikaty
              packages: drug.expiryDate != null
                  ? [MedicinePackage(expiryDate: drug.expiryDate!, pieceCount: drug.pieceCount)]
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
      }));
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _terminWaznosci ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() => _terminWaznosci = picked);
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final medicine = Medicine(
        id: const Uuid().v4(),
        nazwa: _nazwaController.text.trim(),
        opis: _opisController.text.trim(),
        wskazania: _wskazaniaController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        tagi: processTagsForImport(_selectedTags),
        terminWaznosci: _terminWaznosci?.toIso8601String().split('T')[0],
        dataDodania: DateTime.now().toIso8601String(),
      );

      await widget.storageService.saveMedicine(medicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano: ${medicine.nazwa}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Wyczyść formularz
        _nazwaController.clear();
        _opisController.clear();
        _wskazaniaController.clear();
        setState(() {
          _selectedTags = [];
          _terminWaznosci = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Wyszukuje dane leku na podstawie wpisanej nazwy przez AI
  Future<void> _lookupByName() async {
    final name = _nazwaController.text.trim();
    if (name.isEmpty) {
      _showError('Wpisz nazwę leku');
      return;
    }

    if (name.length < 2) {
      _showError('Nazwa leku jest za krótka');
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      final service = GeminiNameLookupService();
      final result = await service.lookupByName(name);

      if (!mounted) return;

      if (result.found && result.medicine != null) {
        final med = result.medicine!;

        // Wypełnij formularz danymi z AI
        setState(() {
          // Aktualizuj nazwę jeśli AI poprawiła literówki
          if (med.nazwa != null && med.nazwa!.isNotEmpty) {
            _nazwaController.text = med.nazwa!;
          }
          _opisController.text = med.opis;
          _wskazaniaController.text = med.wskazania.join(', ');
          _selectedTags = processTagsForImport(med.tagi);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rozpoznano: ${med.nazwa ?? name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        // Nie rozpoznano
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.reason ?? 'Nie rozpoznano produktu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on GeminiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Błąd rozpoznawania: $e');
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
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

/// Dialog przetwarzania z progressem
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
                  prog.stage == 'OCR' ? LucideIcons.scanText : LucideIcons.sparkles,
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
