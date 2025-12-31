import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/theme_provider.dart';
import '../services/update_service.dart';
import '../widgets/neumorphic/neumorphic.dart';
import '../theme/app_theme.dart';

/// Ekran ustawień aplikacji
class SettingsScreen extends StatefulWidget {
  final dynamic storageService; // kept for API compatibility
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Aktualizacje
          _buildUpdateSection(context, theme, isDark),
          const SizedBox(height: 24),

          // Synchronizacja (coming soon)
          _buildSyncSection(context, theme, isDark),
          const SizedBox(height: 24),

          // Motyw
          _buildThemeSection(context, theme, isDark),
          const SizedBox(height: 32),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeuDecoration.basin(isDark: isDark, radius: 10),
                  child: Icon(
                    LucideIcons.download,
                    color: updateAvailable
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
                    onPressed:
                        status == UpdateStatus.downloading ||
                            status == UpdateStatus.installing
                        ? null
                        : () => updateService.startUpdate(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == UpdateStatus.downloading ||
                            status == UpdateStatus.installing)
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
                          status == UpdateStatus.installing
                              ? 'Instaluję...'
                              : 'Aktualizuj',
                        ),
                      ],
                    ),
                  ),
                ],
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: NeuDecoration.basin(isDark: isDark, radius: 10),
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

    return Container(
      decoration: NeuDecoration.basin(isDark: isDark, radius: 12),
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
}
