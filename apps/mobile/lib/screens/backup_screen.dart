import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Ekran kopii zapasowej - TYLKO EKSPORT
class BackupScreen extends StatefulWidget {
  final StorageService storageService;

  const BackupScreen({super.key, required this.storageService});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  int _medicineCount = 0;
  bool _isExporting = false;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.package, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Kopia zapasowa'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status - neumorficzna karta
            Container(
              decoration: NeuDecoration.flat(isDark: isDark, radius: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: NeuDecoration.convex(
                        isDark: isDark,
                        radius: 12,
                      ),
                      child: Image.asset(
                        'assets/backup.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          LucideIcons.package,
                          color: theme.colorScheme.primary,
                        ),
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

            // Eksport header
            Text(
              'Eksport danych',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Kopiuj do schowka - neumorficzna karta
            Container(
              decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clipboard,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kopiuj do schowka',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Skopiuj dane w formacie JSON do schowka',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _medicineCount > 0 ? _exportToClipboard : null,
                      icon: const Icon(LucideIcons.copy),
                      label: const Text('Kopiuj JSON'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Eksport do pliku - neumorficzna karta
            Container(
              decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.folderOutput,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zapisz do pliku',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Zapisz kopię zapasową jako plik JSON',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _medicineCount > 0 && !_isExporting
                          ? _exportToFile
                          : null,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.download),
                      label: const Text('Zapisz plik'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info o imporcie - neumorficzny styl concave
            Container(
              decoration: NeuDecoration.concave(isDark: isDark, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aby zaimportować dane, przejdź do zakładki "Dodaj" i wybierz metodę importu.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

  Future<void> _exportToFile() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final json = widget.storageService.exportToJson();
      final fileName =
          'apteczka_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';

      // Wybierz lokalizację do zapisu
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Zapisz kopię zapasową',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(json, encoding: utf8);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zapisano kopię do: ${file.path.split('/').last}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
