import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic/neumorphic.dart';

/// Ekran zarządzania apteczką - eksport, kopiowanie, danger zone
class ManageScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onNavigateToAdd;

  const ManageScreen({
    super.key,
    required this.storageService,
    this.onNavigateToAdd,
  });

  @override
  State<ManageScreen> createState() => ManageScreenState();
}

class ManageScreenState extends State<ManageScreen> {
  int _medicineCount = 0;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _updateCount();
  }

  /// Public method to refresh state (called when tab becomes visible)
  void refresh() {
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
            Icon(LucideIcons.folderCog, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Zarządzaj apteczką'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status - neumorficzna karta (bez collapse - zawsze widoczny)
            _buildStatusCard(theme, isDark),
            const SizedBox(height: 24),

            // Sekcja: Kopiuj listę leków
            _buildCopyListSection(theme, isDark),
            const SizedBox(height: 16),

            // Sekcja: PDF export (coming soon)
            _buildPdfSection(theme, isDark),
            const SizedBox(height: 24),

            // Nagłówek: Kopia zapasowa
            Text(
              'Kopia zapasowa',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Eksport do pliku (podstawowa funkcja - widoczna)
            _buildExportFileSection(theme, isDark),
            const SizedBox(height: 12),

            // Przywracanie kopii zapasowej (podstawowa funkcja - widoczna)
            _buildRestoreSection(theme, isDark),
            const SizedBox(height: 16),

            // Sekcja Zaawansowane (zwinięta)
            _buildAdvancedSection(theme, isDark),
            const SizedBox(height: 24),

            // Disclaimer (na samym dole, żółty/pomarańczowy)
            _buildDisclaimerSection(theme, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: NeuDecoration.convex(isDark: isDark, radius: 12),
              child: Image.asset(
                'assets/backup.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Icon(
                  LucideIcons.package,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Twoja apteczka', style: theme.textTheme.titleMedium),
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
    );
  }

  Widget _buildCopyListSection(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(LucideIcons.list, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skopiuj listę leków',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Format: "lek1, lek2, lek3, ..."',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _medicineCount > 0 ? _copyMedicineList : null,
        icon: const Icon(LucideIcons.copy),
        label: const Text('Kopiuj nazwy leków'),
      ),
    );
  }

  Widget _buildPdfSection(ThemeData theme, bool isDark) {
    // PDF section - no collapsible content, just info
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: NeuDecoration.basin(isDark: isDark, radius: 10),
              child: Icon(
                LucideIcons.fileSpreadsheet,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tabela leków do PDF',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Wkrótce',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Eksportuj tabelę leków gotową do wydruku',
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
    );
  }

  Widget _buildExportClipboardSection(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(LucideIcons.clipboard, color: theme.colorScheme.primary),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: NeuDecoration.basin(isDark: isDark, radius: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Przydatne gdy przeglądarka blokuje pobieranie plików',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _medicineCount > 0 ? _exportToClipboard : null,
            icon: const Icon(LucideIcons.copy),
            label: const Text('Kopiuj JSON'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportFileSection(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(LucideIcons.folderOutput, color: theme.colorScheme.primary),
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
      child: FilledButton.icon(
        onPressed: _medicineCount > 0 && !_isExporting ? _exportToFile : null,
        icon: _isExporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.download),
        label: const Text('Zapisz plik'),
      ),
    );
  }

  Widget _buildRestoreSection(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(LucideIcons.folderInput, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Przywracanie kopii zapasowej',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Wczytaj dane z pliku JSON',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aby przywrócić dane z kopii zapasowej przejdź do zakładki Dodaj → Import z pliku.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.onNavigateToAdd,
            icon: const Icon(LucideIcons.folderInput),
            label: const Text('Przejdź do importu'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection(ThemeData theme, bool isDark) {
    const exampleBackup = '''{
  "leki": [
    {
      "id": "abc-123",
      "nazwa": "Paracetamol",
      "opis": "Lek przeciwbólowy...",
      "wskazania": ["ból głowy"],
      "tagi": ["przeciwbólowy"],
      "labels": ["label-id-1"],
      "notatka": "Dawkowanie: 1 tabletka co 6h",
      "terminWaznosci": "2025-12-31",
      "dataDodania": "2024-01-15"
    }
  ]
}''';

    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(LucideIcons.fileText, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format pliku kopii zapasowej',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Schemat JSON do ręcznej edycji',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jeśli chcesz ręcznie utworzyć lub edytować plik, użyj tego formatu:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1f1c) : const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exampleBackup,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isDark
                    ? AppColors.primary.withAlpha(200)
                    : const Color(0xFF94a3b8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pola id i dataDodania zostaną wygenerowane automatycznie przy imporcie, jeśli ich brakuje.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.expiringSoon.withAlpha(30)
            : AppColors.expiringSoon.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expiringSoon.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.shieldAlert, color: AppColors.expiringSoon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informacja prawna',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.expiringSoon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aplikacja "Pudełko na leki" służy wyłącznie do organizacji domowej apteczki. Nie jest to wyrób medyczny. Przed użyciem leku zawsze skonsultuj się z lekarzem lub farmaceutą.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sekcja "Zaawansowane" - ukrywa mniej używane opcje
  Widget _buildAdvancedSection(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      header: Row(
        children: [
          Icon(
            LucideIcons.settings2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zaawansowane',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Opcje dla zaawansowanych użytkowników',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kopiuj do schowka
          _buildAdvancedExportClipboard(theme, isDark),
          const SizedBox(height: 12),

          // Format pliku
          _buildAdvancedFormatInfo(theme, isDark),
          const SizedBox(height: 12),

          // Strefa niebezpieczna
          _buildAdvancedDangerZone(theme, isDark),
        ],
      ),
    );
  }

  /// Kopiuj JSON do schowka (wewnątrz sekcji Zaawansowane)
  /// Używamy basin (wklęsły) dla hierarchii: flat > basin
  Widget _buildAdvancedExportClipboard(ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.basin(isDark: isDark, radius: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.clipboard,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kopiuj JSON do schowka',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Przydatne gdy przeglądarka blokuje pobieranie plików',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _medicineCount > 0 ? _exportToClipboard : null,
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Kopiuj JSON'),
            ),
          ),
        ],
      ),
    );
  }

  /// Format pliku (wewnątrz sekcji Zaawansowane)
  /// Używamy basin (wklęsły) dla hierarchii: flat > basin
  Widget _buildAdvancedFormatInfo(ThemeData theme, bool isDark) {
    const exampleBackup = '''{
  "leki": [
    {
      "id": "abc-123",
      "nazwa": "Paracetamol",
      "terminWaznosci": "2025-12-31"
    }
  ]
}''';

    return Container(
      decoration: NeuDecoration.basin(isDark: isDark, radius: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileCode,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Format pliku JSON',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1f1c) : const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exampleBackup,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: isDark
                    ? AppColors.primary.withAlpha(200)
                    : const Color(0xFF94a3b8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Strefa niebezpieczna (wewnątrz sekcji Zaawansowane)
  Widget _buildAdvancedDangerZone(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.expired.withAlpha(100), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.expired.withAlpha(isDark ? 15 : 10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: AppColors.expired,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Strefa niebezpieczna',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.expired,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nieodwracalne akcje - upewnij się, że masz kopię zapasową.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _medicineCount > 0 ? _showDeleteAllDialog : null,
              icon: Icon(
                LucideIcons.trash2,
                color: AppColors.expired,
                size: 16,
              ),
              label: Text(
                'Usuń wszystkie leki',
                style: TextStyle(color: AppColors.expired),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.expired.withAlpha(150)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme, bool isDark) {
    return NeuCollapsibleContainer(
      initiallyExpanded: false,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.expired.withAlpha(128), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
      ),
      header: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: AppColors.expired),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strefa niebezpieczna',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.expired,
                  ),
                ),
                Text(
                  'Nieodwracalne akcje',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poniższe akcje są nieodwracalne. Upewnij się, że masz kopię zapasową przed ich wykonaniem.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _medicineCount > 0 ? _showDeleteAllDialog : null,
            icon: Icon(LucideIcons.trash2, color: AppColors.expired),
            label: Text(
              'Usuń wszystkie leki',
              style: TextStyle(color: AppColors.expired),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.expired),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HANDLERS ====================

  String _getPolishPlural(int count) {
    if (count == 1) return 'lek';
    if (count >= 2 && count <= 4) return 'leki';
    if (count >= 12 && count <= 14) return 'leków';
    final lastDigit = count % 10;
    if (lastDigit >= 2 && lastDigit <= 4) return 'leki';
    return 'leków';
  }

  Future<void> _copyMedicineList() async {
    final namesString = widget.storageService.getMedicineNamesString();
    await Clipboard.setData(ClipboardData(text: namesString));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skopiowano listę $_medicineCount leków'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      final bytes = utf8.encode(json);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Zapisz kopię zapasową',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zapisano kopię: ${result.split('/').last.split('\\').last}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  Future<void> _showDeleteAllDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: AppColors.expired),
            const SizedBox(width: 12),
            const Text('Usuń wszystkie leki'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ta akcja jest nieodwracalna! Wszystkie leki ($_medicineCount) zostaną usunięte.',
              style: TextStyle(color: AppColors.expired),
            ),
            const SizedBox(height: 16),
            const Text('Aby potwierdzić, wpisz "Tak" poniżej:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Wpisz "Tak"',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim() == 'Tak') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wpisz dokładnie "Tak" aby potwierdzić'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
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
            content: Text('Wszystkie leki zostały usunięte'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
