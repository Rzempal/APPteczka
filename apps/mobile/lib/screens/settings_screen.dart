import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../services/theme_provider.dart';
import '../services/update_service.dart';
import '../widgets/bug_report_sheet.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../theme/app_theme.dart';

/// Ekran ustawień aplikacji
class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _badgeVisible = false; // Badge hidden until manual check
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _badgeVisible = false; // Reset on entry
    widget.updateService.addListener(_onUpdateServiceChanged);
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    widget.updateService.removeListener(_onUpdateServiceChanged);
    _dotsController.dispose();
    super.dispose();
  }

  void _onUpdateServiceChanged() {
    // Show badge after check completes
    if (widget.updateService.status == UpdateStatus.idle &&
        (widget.updateService.isUpToDate ||
            widget.updateService.updateAvailable)) {
      _badgeVisible = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleCheckUpdate() async {
    await widget.updateService.checkForUpdate();
    // Badge will be shown via _onUpdateServiceChanged
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
            Icon(LucideIcons.settings2, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Ustawienia'),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Disclaimer na górze
              _buildDisclaimerSection(theme, isDark),
              const SizedBox(height: 24),

              // Aktualizacje (druga pozycja)
              _buildUpdateSection(context, theme, isDark),
              const SizedBox(height: 24),

              // Synchronizacja (coming soon)
              _buildSyncSection(context, theme, isDark),
              const SizedBox(height: 24),

              // Motyw
              _buildThemeSection(context, theme, isDark),
              const SizedBox(height: 24),

              // Gesty (coming soon)
              _buildGesturesSection(context, theme, isDark),
              const SizedBox(height: 24),

              // Kopia zapasowa (akordeon)
              _buildBackupSection(theme, isDark),
              const SizedBox(height: 24),

              // Zaawansowane (osobny akordeon)
              _buildAdvancedSection(theme, isDark),
              const SizedBox(height: 32),
            ],
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

  Widget _buildUpdateSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final updateService = widget.updateService;
    final status = updateService.status;
    final updateAvailable = updateService.updateAvailable;
    final isUpToDate = updateService.isUpToDate;

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Icon + Title/Status + Sprawdź button
            Row(
              children: [
                // Icon
                NeuInsetContainer(
                  borderRadius: 10,
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    LucideIcons.download,
                    // Red icon for DEV builds, otherwise normal color logic
                    color: AppConfig.isInternal
                        ? AppColors.expired
                        : updateAvailable
                        ? AppColors.primary
                        : isUpToDate
                        ? AppColors.valid
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + Version + Last check
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sprawdź aktualizacje',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge (only visible after manual check or during checking)
                          if (status == UpdateStatus.checking)
                            _buildAnimatedCheckingBadge()
                          else if (_badgeVisible && updateAvailable)
                            _buildStatusBadge(
                              'Dostępna!',
                              AppColors.primary,
                              isAccent: true,
                            )
                          else if (_badgeVisible && isUpToDate)
                            _buildStatusBadge(
                              'Aktualna',
                              theme.colorScheme.onSurfaceVariant,
                              isAccent: false,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wersja: v${updateService.currentVersionName ?? updateService.currentVersion ?? "Nieznana"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (updateService.lastCheckTime != null)
                        Text(
                          'Sprawdzono: ${_formatLastCheck(updateService.lastCheckTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              150,
                            ),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Compact Sprawdz button
                GestureDetector(
                  onTap:
                      status == UpdateStatus.checking ||
                          status == UpdateStatus.downloading
                      ? null
                      : _handleCheckUpdate,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: status == UpdateStatus.checking
                        ? NeuDecoration.pressed(isDark: isDark, radius: 10)
                        : NeuDecoration.flat(isDark: isDark, radius: 10),
                    child: Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Progress bar for download
            if (status == UpdateStatus.downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: updateService.downloadProgress / 100,
                backgroundColor: isDark
                    ? AppColors.darkShadowDark
                    : AppColors.lightShadowDark,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Pobieranie: ${updateService.downloadProgress.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],

            // Error message
            if (status == UpdateStatus.error &&
                updateService.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expired.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 16,
                      color: AppColors.expired,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        updateService.errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.expired,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Aktualizuj button (only when update available)
            if (updateAvailable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // New version info
                  Expanded(
                    child: Text(
                      '→ Nowa: ${updateService.latestVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Aktualizuj button
                  NeuButton.primary(
                    onPressed: status == UpdateStatus.downloading
                        ? null
                        : () => updateService.startUpdate(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == UpdateStatus.downloading ||
                            status == UpdateStatus.launchingInstaller)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(LucideIcons.download, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          status == UpdateStatus.launchingInstaller
                              ? 'Uruchamiam instalator...'
                              : 'Aktualizuj',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Hint when installer doesn't show up
              if (status == UpdateStatus.launchingInstaller &&
                  updateService.showInstallerHint)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Nic się nie dzieje? Kliknij ponownie aby uruchomić instalator.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, {bool isAccent = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isAccent ? 30 : 20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckingBadge() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        final dotCount = (_dotsController.value * 4).floor() % 4;
        final dots = '.' * dotCount;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Sprawdzam$dots',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  String _formatLastCheck(DateTime time) {
    return '${time.day}.${time.month.toString().padLeft(2, '0')} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getVersionText(UpdateService service) {
    final current = service.currentVersion ?? 'Nieznana';
    if (service.updateAvailable && service.latestVersion != null) {
      return 'Obecna: $current → Nowa: ${service.latestVersion}';
    }
    return 'Wersja: $current';
  }

  Widget _buildSyncSection(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            NeuInsetContainer(
              borderRadius: 10,
              padding: const EdgeInsets.all(10),
              child: Icon(
                LucideIcons.cloudCog,
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
                        'Konto / Synchronizacja',
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
                    'Synchronizacja między urządzeniami',
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

  Widget _buildThemeSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.palette, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Motyw aplikacji',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildThemeToggle(context, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeData theme, bool isDark) {
    final currentMode = widget.themeProvider.themeMode;

    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildThemeOption(
            context,
            theme,
            isDark,
            icon: LucideIcons.sunMoon,
            label: 'System',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => widget.themeProvider.setThemeMode(ThemeMode.system),
          ),
          _buildThemeOption(
            context,
            theme,
            isDark,
            icon: LucideIcons.sun,
            label: 'Jasny',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => widget.themeProvider.setThemeMode(ThemeMode.light),
          ),
          _buildThemeOption(
            context,
            theme,
            isDark,
            icon: LucideIcons.moon,
            label: 'Ciemny',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => widget.themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? NeuDecoration.convex(isDark: isDark, radius: 10)
              : null,
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== BACKUP SECTION ==================

  int _medicineCount = 0;
  bool _isExporting = false;
  bool _isBackupOpen = false;
  bool _isAdvancedOpen = false;

  Widget _buildDisclaimerSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.expiringSoon.withAlpha(30)
            : AppColors.expiringSoon.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expiringSoon.withAlpha(100)),
      ),
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
                  'Aplikacja "Karton z lekami" służy wyłącznie do organizacji domowej apteczki. Nie jest to wyrób medyczny. Przed użyciem leku zawsze skonsultuj się z lekarzem lub farmaceutą.',
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
    );
  }

  Widget _buildGesturesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            NeuInsetContainer(
              borderRadius: 10,
              padding: const EdgeInsets.all(10),
              child: Icon(
                LucideIcons.hand,
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
                        'Gesty przeciągania',
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
                    'Sterowanie gestami przeciągania',
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

  Widget _buildBackupSection(ThemeData theme, bool isDark) {
    _medicineCount = widget.storageService.getMedicines().length;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
          child: Column(
            children: [
              // Header - klikalne
              InkWell(
                onTap: () =>
                    setLocalState(() => _isBackupOpen = !_isBackupOpen),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.archive,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kopia zapasowa',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$_medicineCount ${_getPolishPlural(_medicineCount)} w apteczce',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isBackupOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              // Zawartość zwijana
              if (_isBackupOpen) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zapisz do pliku
                      _buildBackupExportFile(theme, isDark),
                      const SizedBox(height: 12),
                      // Przywracanie
                      _buildBackupRestore(theme, isDark),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupExportFile(ThemeData theme, bool isDark) {
    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.folderOutput,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zapisz do pliku',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Zapisz kopię zapasową jako plik JSON',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _medicineCount > 0 && !_isExporting
                  ? _exportToFile
                  : null,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.download, size: 16),
              label: const Text('Zapisz plik'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestore(ThemeData theme, bool isDark) {
    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.folderInput,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Przywracanie kopii zapasowej',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(
                  text:
                      'Aby przywrócić dane z kopii zapasowej, przejdź do zakładki "',
                ),
                TextSpan(
                  text: 'Dodaj leki',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: '" i wczytaj plik .json lub wklej skopiowany JSON.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToImport,
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text('Przejdź do importu'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImport() {
    // Navigate to Dodaj tab (index 1)
    Navigator.of(context).popUntil((route) => route.isFirst);
    // This will be handled by parent - for now just show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Przejdź do zakładki "Dodaj" aby zaimportować dane'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAdvancedSection(ThemeData theme, bool isDark) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          decoration: NeuDecoration.flat(isDark: isDark, radius: 12),
          child: Column(
            children: [
              // Header - klikalne
              InkWell(
                onTap: () =>
                    setLocalState(() => _isAdvancedOpen = !_isAdvancedOpen),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.brainCog,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zaawansowane',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        _isAdvancedOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              // Zawartość zwijana
              if (_isAdvancedOpen) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kopiuj JSON
                      _buildAdvancedExportClipboard(theme, isDark),
                      const SizedBox(height: 12),
                      // Format pliku
                      _buildAdvancedFormatInfo(theme, isDark),
                      const SizedBox(height: 12),
                      // Zgłoś problem
                      _buildAdvancedBugReport(theme, isDark),
                      const SizedBox(height: 12),
                      // Strefa niebezpieczna
                      _buildAdvancedDangerZone(theme, isDark),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedExportClipboard(ThemeData theme, bool isDark) {
    return NeuInsetContainer(
      borderRadius: 10,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.clipboard,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Kopiuj JSON',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _medicineCount > 0 ? _exportToClipboard : null,
              icon: const Icon(LucideIcons.copy, size: 14),
              label: const Text('Kopiuj do schowka'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFormatInfo(ThemeData theme, bool isDark) {
    const exampleBackup = '''
{
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

    return NeuInsetContainer(
      borderRadius: 10,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileCode,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Format pliku kopii zapasowej',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jeśli chcesz ręcznie utworzyć lub edytować plik, użyj tego formatu:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1f1c) : const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exampleBackup,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                height: 1.4,
                color: isDark
                    ? AppColors.primary.withAlpha(200)
                    : const Color(0xFF94a3b8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              children: [
                const TextSpan(text: 'Pola '),
                TextSpan(
                  text: 'id',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(10),
                  ),
                ),
                const TextSpan(text: ' i '),
                TextSpan(
                  text: 'dataDodania',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(10),
                  ),
                ),
                const TextSpan(
                  text:
                      ' zostaną wygenerowane automatycznie przy imporcie, jeśli ich brakuje.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedBugReport(ThemeData theme, bool isDark) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.bug, color: AppColors.expired, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zgłoś problem',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Masz problem z aplikacją lub pomysł na ulepszenie? Daj nam znać!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // FAB toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pokaż przycisk zgłaszania',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: widget.storageService.showBugReportFab,
                    onChanged: (value) {
                      setLocalState(() {
                        widget.storageService.showBugReportFab = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => BugReportSheet.show(context),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Wyślij zgłoszenie'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedDangerZone(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.expired.withAlpha(100), width: 1),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.expired.withAlpha(isDark ? 15 : 10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: AppColors.expired,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Strefa niebezpieczna',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.expired,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nieodwracalne akcje - upewnij się, że masz kopię zapasową przed ich wykonaniem.',
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
                size: 14,
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
    setState(() => _isExporting = true);

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
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: AppColors.expired),
            const SizedBox(width: 12),
            const Text('Usuń wszystkie leki?'),
          ],
        ),
        content: const Text(
          'Ta operacja jest nieodwracalna. Wszystkie leki zostaną trwale usunięte z apteczki.\n\nUpewnij się, że masz kopię zapasową!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            child: const Text('Usuń wszystko'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final medicines = widget.storageService.getMedicines();
      for (final m in medicines) {
        await widget.storageService.deleteMedicine(m.id);
      }
      setState(() => _medicineCount = 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usunięto wszystkie leki z apteczki'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
