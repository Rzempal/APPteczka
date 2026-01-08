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
import '../widgets/gemini_scanner.dart';
import '../widgets/two_photo_scanner.dart';
import '../widgets/karton_icons.dart';
import '../widgets/batch_date_input_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../widgets/tag_selector_widget.dart';
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
  final _opisController = TextEditingController();
  final _wskazaniaController = TextEditingController();
  List<String> _selectedTags = []; // Zamiana z TextFormField na selektor
  DateTime? _terminWaznosci;
  bool _isSaving = false;
  bool _isLookingUp = false; // AI name lookup

  // Import z pliku
  bool _isImporting = false;

  // Expanded sections - nowa kolejność
  bool _aiVisionExpanded = true; // 1. Gemini AI Vision (połączone tryby)
  int _aiVisionMode = 0; // 0 = 1 zdjęcie, 1 = 2 zdjęcia
  bool _manualExpanded = false; // 2. Dodaj ręcznie
  bool _fileExpanded = false; // 3. Import kopii

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

                // 2. Dodaj ręcznie (przesunięte)
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

                // 3. Import z pliku (przesunięte)
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

          // Zawartość rozwijana
          if (_aiVisionExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Toggle trybów
                  _buildModeToggle(theme, isDark, aiColor),
                  const SizedBox(height: 16),

                  // Odpowiedni skaner w zależności od trybu
                  if (_aiVisionMode == 0)
                    GeminiScanner(
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
                    )
                  else
                    TwoPhotoScanner(
                      onResult: _handleTwoPhotoResult,
                      onError: widget.onError,
                      onComplete: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lek został zaimportowany!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme, bool isDark, Color aiColor) {
    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          // Swipe gesture - przełączanie trybu AI
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 100) return; // Ignoruj małe ruchy

          HapticFeedback.lightImpact();

          if (velocity < 0 && _aiVisionMode == 0) {
            // Swipe left → tryb 2 zdjęcia
            setState(() => _aiVisionMode = 1);
          } else if (velocity > 0 && _aiVisionMode == 1) {
            // Swipe right → tryb 1 zdjęcie
            setState(() => _aiVisionMode = 0);
          }
        },
        child: Row(
          children: [
            // Tryb 1 zdjęcie
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // Całe pole dotykowe
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _aiVisionMode = 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: _aiVisionMode == 0
                      ? NeuDecoration.convex(isDark: isDark, radius: 10)
                      : null,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.imagePlus,
                        size: 22,
                        color: _aiVisionMode == 0
                            ? aiColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 zdjęcie',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _aiVisionMode == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _aiVisionMode == 0
                              ? aiColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tryb 2 zdjęcia
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // Całe pole dotykowe
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _aiVisionMode = 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: _aiVisionMode == 1
                      ? NeuDecoration.convex(isDark: isDark, radius: 10)
                      : null,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.images,
                        size: 22,
                        color: _aiVisionMode == 1
                            ? aiColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2 zdjęcia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _aiVisionMode == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _aiVisionMode == 1
                              ? aiColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

    for (final lek in result.leki) {
      final medicine = Medicine(
        id: const Uuid().v4(),
        nazwa: lek.nazwa,
        opis: lek.opis,
        wskazania: lek.wskazania,
        tagi: processTagsForImport(lek.tagi),
        terminWaznosci: lek.terminWaznosci,
        dataDodania: DateTime.now().toIso8601String(),
      );
      await widget.storageService.saveMedicine(medicine);
      importedMedicines.add(medicine);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zaimportowano ${importedMedicines.length} leków z Gemini AI',
        ),
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

  /// Handler dla trybu 2-zdjęciowego (pojedynczy lek)
  void _handleTwoPhotoResult(ScannedMedicine lek) async {
    final medicine = Medicine(
      id: const Uuid().v4(),
      nazwa: lek.nazwa,
      opis: lek.opis,
      wskazania: lek.wskazania,
      tagi: processTagsForImport(lek.tagi),
      terminWaznosci: lek.terminWaznosci,
      dataDodania: DateTime.now().toIso8601String(),
    );
    await widget.storageService.saveMedicine(medicine);
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
