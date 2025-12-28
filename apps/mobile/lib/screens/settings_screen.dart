import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';

/// Ekran ustawień aplikacji (uproszczony)
class SettingsScreen extends StatelessWidget {
  final dynamic storageService; // kept for API compatibility
  final ThemeProvider themeProvider;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.themeProvider,
  });

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

  Widget _buildSyncSection(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: NeuDecoration.concave(isDark: isDark, radius: 10),
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
    final currentMode = themeProvider.themeMode;

    return Container(
      decoration: NeuDecoration.concave(isDark: isDark, radius: 12),
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
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
          _buildThemeOption(
            context,
            theme,
            isDark,
            icon: LucideIcons.sun,
            label: 'Jasny',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _buildThemeOption(
            context,
            theme,
            isDark,
            icon: LucideIcons.moon,
            label: 'Ciemny',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
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
