import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';

/// Ekran kopii zapasowej - import/eksport
class BackupScreen extends StatefulWidget {
  final StorageService storageService;

  const BackupScreen({super.key, required this.storageService});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _importController = TextEditingController();
  int _medicineCount = 0;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _updateCount();
  }

  void _updateCount() {
    setState(() {
      _medicineCount = widget.storageService.getMedicines().length;
    });
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('📦 Kopia zapasowa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Twoja apteczka',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '$_medicineCount ${_getPolishPlural(_medicineCount)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Eksport
            Text(
              'Eksport',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Skopiuj dane apteczki do schowka w formacie JSON. Możesz je zaimportować w wersji webowej lub innym urządzeniu.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _medicineCount > 0 ? _exportToClipboard : null,
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopiuj do schowka'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Import
            Text(
              'Import',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Wklej dane JSON z kopii zapasowej lub eksportu z wersji webowej.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _importController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '{"leki": [...]}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pasteFromClipboard,
                            icon: const Icon(Icons.paste),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: const Text('Importuj'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Wyczyść
            Text(
              'Niebezpieczna strefa',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Usuń wszystkie leki z apteczki. Ta operacja jest nieodwracalna!',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _medicineCount > 0 ? _confirmClear : null,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Wyczyść apteczkę'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
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

  String _getPolishPlural(int count) {
    if (count == 1) return 'lek';
    if (count >= 2 && count <= 4) return 'leki';
    if (count >= 12 && count <= 14) return 'leków';
    final lastDigit = count % 10;
    if (lastDigit >= 2 && lastDigit <= 4) return 'leki';
    return 'leków';
  }

  Future<void> _exportToClipboard() async {
    final json = widget.storageService.exportToJson();
    await Clipboard.setData(ClipboardData(text: json));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skopiowano $_medicineCount leków do schowka'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _importController.text = data!.text!;
    }
  }

  Future<void> _importFromJson() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showError('Wklej dane JSON do zaimportowania');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
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
          // Generuj nowe ID jeśli brak
          final medicineData = Map<String, dynamic>.from(item);
          if (medicineData['id'] == null) {
            medicineData['id'] = DateTime.now().millisecondsSinceEpoch
                .toString();
          }
          if (medicineData['dataDodania'] == null) {
            medicineData['dataDodania'] = DateTime.now().toIso8601String();
          }
          medicines.add(Medicine.fromJson(medicineData));
        }
      }

      if (medicines.isEmpty) {
        throw const FormatException('Brak leków do zaimportowania');
      }

      // Pokaż dialog potwierdzenia
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Potwierdź import'),
            content: Text('Czy chcesz zaimportować ${medicines.length} leków?'),
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

        if (confirmed == true) {
          await widget.storageService.importMedicines(medicines);
          _importController.clear();
          _updateCount();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Zaimportowano ${medicines.length} leków'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Błąd parsowania JSON: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
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

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyść apteczkę?'),
        content: const Text(
          'Wszystkie leki zostaną usunięte. Ta operacja jest nieodwracalna!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Usuń wszystko'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearMedicines();
      _updateCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apteczka została wyczyszczona'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
