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
import '../widgets/barcode_scanner.dart';
import '../widgets/karton_icons.dart';
import '../widgets/batch_date_input_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../theme/app_theme.dart';
import '../utils/tag_normalization.dart';

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
  DateTime? _terminWaznosci;
  bool _isSaving = false;

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
            onTap: () => setState(() => _manualExpanded = !_manualExpanded),
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
          // Nazwa leku
          TextFormField(
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
              if (value.trim().length < 2) {
                return 'Nazwa leku jest za krótka';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Termin ważności (opcjonalnie)
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
                        'Termin ważności (opcjonalnie)',
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

          // Przycisk zapisu z AI
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveMedicine,
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
            label: const Text('Zapisz lek'),
          ),
        ],
      ),
    );
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
                tagi: [
                  ...drug
                      .toMedicine('')
                      .tagi, // tagi z RPL (Rp/OTC, forma, substancje)
                  ...processTagsForImport(med.tagi), // tagi z AI
                ].toSet().toList(), // usun duplikaty
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

    final name = _nazwaController.text.trim();

    setState(() => _isSaving = true);

    // Pokaz dialog przetwarzania AI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AiProcessingDialog(medicineName: name),
    );

    try {
      // Wywolaj AI aby uzupelnic dane leku
      final geminiService = GeminiNameLookupService();
      final result = await geminiService.lookupByName(name);

      // Zamknij dialog przetwarzania
      if (mounted) Navigator.of(context).pop();

      if (!result.found || result.medicine == null) {
        // AI nie rozpoznalo - pokaz blad
        _showError(result.reason ?? 'Nie rozpoznano leku "$name"');
        return;
      }

      // AI rozpoznalo - zapisz z uzupelnionymi danymi
      final aiMedicine = result.medicine!;
      final medicine = Medicine(
        id: const Uuid().v4(),
        nazwa: aiMedicine.nazwa ?? name,
        opis: aiMedicine.opis,
        wskazania: aiMedicine.wskazania,
        tagi: processTagsForImport(aiMedicine.tagi),
        terminWaznosci: _terminWaznosci?.toIso8601String().split('T')[0],
        dataDodania: DateTime.now().toIso8601String(),
      );

      await widget.storageService.saveMedicine(medicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano: ${medicine.nazwa}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Wyczysc formularz
        _nazwaController.clear();
        setState(() => _terminWaznosci = null);
      }
    } on GeminiException catch (e) {
      // Zamknij dialog jesli jeszcze otwarty
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError(e.message);
    } catch (e) {
      // Zamknij dialog jesli jeszcze otwarty
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Błąd: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
