// rpl_package_selector.dart - Bottom sheet do wyboru opakowania leku z RPL
// Pokazuje listę opakowań z GTIN do wyboru

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/rpl_service.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';

/// Wynik wyboru opakowania
class PackageSelectionResult {
  final RplDrugDetails drugDetails;
  final RplPackage selectedPackage;

  PackageSelectionResult({
    required this.drugDetails,
    required this.selectedPackage,
  });
}

/// Bottom sheet do wyboru opakowania leku z RPL
class RplPackageSelectorSheet extends StatelessWidget {
  final RplDrugDetails drugDetails;
  final BuildContext sheetContext; // Kontekst bottom sheeta do Navigator.pop

  const RplPackageSelectorSheet({
    super.key,
    required this.drugDetails,
    required this.sheetContext,
  });

  /// Pokazuje bottom sheet do wyboru opakowania
  /// Jeśli jest tylko jedno opakowanie - zwraca je automatycznie
  static Future<PackageSelectionResult?> show({
    required BuildContext context,
    required RplDrugDetails drugDetails,
  }) async {
    // Jeśli tylko jedno opakowanie - zwróć od razu bez pokazywania dialogu
    if (drugDetails.packages.length == 1) {
      return PackageSelectionResult(
        drugDetails: drugDetails,
        selectedPackage: drugDetails.packages.first,
      );
    }

    // Jeśli brak opakowań - zwróć null
    if (drugDetails.packages.isEmpty) {
      return null;
    }

    // Pokaż bottom sheet z listą opakowań
    return showModalBottomSheet<PackageSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // Uzyj root navigator aby uniknac konfliktow
      builder: (sheetContext) => RplPackageSelectorSheet(
        drugDetails: drugDetails,
        sheetContext: sheetContext, // Przekaz kontekst bottom sheeta
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.package,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wybierz opakowanie',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              drugDetails.fullName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drugDetails.form,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Lista opakowań
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: drugDetails.packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, index) {
                  final package = drugDetails.packages[index];
                  return _buildPackageTile(sheetContext, package, isDark);
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageTile(
    BuildContext sheetContext,
    RplPackage package,
    bool isDark,
  ) {
    final theme = Theme.of(sheetContext);
    final isRx = package.accessibilityCategory?.toUpperCase() == 'RP' ||
        package.accessibilityCategory?.toUpperCase() == 'RPZ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(sheetContext).pop(
              PackageSelectionResult(
                drugDetails: drugDetails,
                selectedPackage: package,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: NeuDecoration.flat(isDark: isDark, radius: 12),
            child: Row(
              children: [
                // Ikona opakowania
                NeuInsetContainer(
                  borderRadius: 10,
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    LucideIcons.box,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Info o opakowaniu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.packaging.isNotEmpty
                            ? package.packaging
                            : 'Opakowanie ${drugDetails.packages.indexOf(package) + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (package.gtin.isNotEmpty) ...[
                            Icon(
                              LucideIcons.barcode,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'EAN: ${package.gtin}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge Rp/OTC
                if (package.accessibilityCategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRx
                          ? Colors.red.withAlpha(30)
                          : Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      package.accessibilityCategory!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isRx ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
