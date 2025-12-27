import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../widgets/gemini_scanner.dart';

/// Ekran dodawania leków - wszystkie metody importu
class AddMedicineScreen extends StatefulWidget {
  final StorageService storageService;

  const AddMedicineScreen({super.key, required this.storageService});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // Formularz ręczny
  final _formKey = GlobalKey<FormState>();
  final _nazwaController = TextEditingController();
  final _opisController = TextEditingController();
  final _wskazaniaController = TextEditingController();
  final _tagiController = TextEditingController();
  DateTime? _terminWaznosci;
  bool _isSaving = false;

  // Import JSON
  final _jsonController = TextEditingController();
  bool _isImporting = false;

  // Expanded sections
  bool _geminiExpanded = true;
  bool _jsonExpanded = false;
  bool _fileExpanded = false;
  bool _manualExpanded = false;

  @override
  void dispose() {
    _nazwaController.dispose();
    _opisController.dispose();
    _wskazaniaController.dispose();
    _tagiController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plusCircle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Dodaj leki'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header info
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.plusCircle,
                        color: Colors.white,
                        size: 24,
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
                            'Możesz skanować zdjęcia, importować JSON lub dodać ręcznie',
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

            // 1. Gemini AI Scanner
            _buildExpandableSection(
              icon: LucideIcons.sparkles,
              title: 'Gemini AI Vision',
              subtitle: 'Skanuj zdjęcia leków automatycznie',
              isExpanded: _geminiExpanded,
              onToggle: () =>
                  setState(() => _geminiExpanded = !_geminiExpanded),
              child: GeminiScanner(
                onResult: _handleGeminiResult,
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

            const SizedBox(height: 12),

            // 2. Wklej JSON
            _buildExpandableSection(
              icon: LucideIcons.clipboard,
              title: 'Wklej JSON',
              subtitle: 'Importuj dane z AI lub kopii zapasowej',
              isExpanded: _jsonExpanded,
              onToggle: () => setState(() => _jsonExpanded = !_jsonExpanded),
              child: _buildJsonImportSection(theme),
            ),

            const SizedBox(height: 12),

            // 3. Import z pliku
            _buildExpandableSection(
              icon: LucideIcons.folderDown,
              title: 'Import z pliku',
              subtitle: 'Wczytaj plik JSON z urządzenia',
              isExpanded: _fileExpanded,
              onToggle: () => setState(() => _fileExpanded = !_fileExpanded),
              child: _buildFileImportSection(theme),
            ),

            const SizedBox(height: 12),

            // 4. Dodaj ręcznie
            _buildExpandableSection(
              icon: LucideIcons.edit,
              title: 'Dodaj ręcznie',
              subtitle: 'Wprowadź dane leku samodzielnie',
              isExpanded: _manualExpanded,
              onToggle: () =>
                  setState(() => _manualExpanded = !_manualExpanded),
              child: _buildManualForm(theme),
            ),

            const SizedBox(height: 24),

            // Prompt AI info
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.lightbulb,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wskazówka',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Możesz też użyć ChatGPT/Claude z ręcznym promptem. Skopiuj prompt poniżej i wklej odpowiedź w sekcji "Wklej JSON".',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copyAiPrompt,
                      icon: const Icon(LucideIcons.copy),
                      label: const Text('Kopiuj prompt AI'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
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

  Widget _buildJsonImportSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _jsonController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '{"leki": [...]}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(LucideIcons.clipboardCheck),
                label: const Text('Wklej'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isImporting ? null : _importFromJson,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.download),
                label: const Text('Importuj'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileImportSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Wybierz plik JSON z kopią zapasową lub eksportem z wersji webowej.',
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
          label: const Text('Wybierz plik JSON'),
        ),
      ],
    );
  }

  Widget _buildManualForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nazwa
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
              return null;
            },
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

          // Tagi
          TextFormField(
            controller: _tagiController,
            decoration: InputDecoration(
              labelText: 'Tagi (oddzielone przecinkami)',
              hintText: 'przeciwbólowy, lek OTC',
              prefixIcon: const Icon(LucideIcons.tags),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Termin ważności
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.calendar),
            title: const Text('Termin ważności'),
            subtitle: Text(
              _terminWaznosci != null
                  ? '${_terminWaznosci!.day.toString().padLeft(2, '0')}.${_terminWaznosci!.month.toString().padLeft(2, '0')}.${_terminWaznosci!.year}'
                  : 'Nie ustawiono',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
    int imported = 0;
    for (final lek in result.leki) {
      final medicine = Medicine(
        id: const Uuid().v4(),
        nazwa: lek.nazwa,
        opis: lek.opis,
        wskazania: lek.wskazania,
        tagi: lek.tagi,
        dataDodania: DateTime.now().toIso8601String(),
      );
      await widget.storageService.saveMedicine(medicine);
      imported++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zaimportowano $imported leków z Gemini AI'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _jsonController.text = data!.text!;
    }
  }

  Future<void> _importFromJson() async {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      _showError('Wklej dane JSON do zaimportowania');
      return;
    }

    setState(() => _isImporting = true);

    try {
      final medicines = _parseJsonToMedicines(text);

      if (medicines.isEmpty) {
        throw const FormatException('Brak leków do zaimportowania');
      }

      final confirmed = await _confirmImport(medicines.length);

      if (confirmed == true) {
        await widget.storageService.importMedicines(medicines);
        _jsonController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zaimportowano ${medicines.length} leków'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Błąd parsowania JSON: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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

      final medicines = _parseJsonToMedicines(content);

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

  List<Medicine> _parseJsonToMedicines(String text) {
    final data = jsonDecode(text);

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowy format JSON');
    }

    final lekiRaw = data['leki'];
    if (lekiRaw is! List) {
      throw const FormatException('Brak tablicy "leki" w JSON');
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
        tagi: _tagiController.text
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList(),
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
        _tagiController.clear();
        setState(() => _terminWaznosci = null);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyAiPrompt() {
    const prompt = '''Rozpoznaj leki ze zdjęcia i zwróć w formacie JSON:

{
  "leki": [
    {
      "nazwa": "Dokładna nazwa leku z opakowania",
      "opis": "Krótki opis działania (max 100 znaków)",
      "wskazania": ["wskazanie 1", "wskazanie 2"],
      "tagi": ["ból", "przeciwgorączkowy", "lek OTC"]
    }
  ]
}

Dozwolone tagi: ból, ból głowy, gorączka, kaszel, katar, alergia, nudności, biegunka, przeciwbólowy, przeciwgorączkowy, przeciwzapalny, lek OTC, lek Rx, suplement, dla dorosłych, dla dzieci.''';

    Clipboard.setData(const ClipboardData(text: prompt));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Prompt skopiowany! Wklej go do ChatGPT/Gemini ze zdjęciem leków.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
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
