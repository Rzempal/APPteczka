import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'neumorphic/neumorphic.dart';
import 'filters_sheet.dart' show tagCategories;

/// BottomSheet do edycji karty leku - konsoliduje wszystkie edycje w jedno miejsce
/// Obsługuje: nazwę, opis, wskazania, etykiety, własne tagi
class MedicineEditSheet extends StatefulWidget {
  final Medicine medicine;
  final List<UserLabel> availableLabels;
  final StorageService storageService;
  final VoidCallback? onMedicineUpdated;

  const MedicineEditSheet({
    super.key,
    required this.medicine,
    required this.availableLabels,
    required this.storageService,
    this.onMedicineUpdated,
  });

  /// Pokazuje BottomSheet do edycji karty leku
  static Future<void> show({
    required BuildContext context,
    required Medicine medicine,
    required List<UserLabel> availableLabels,
    required StorageService storageService,
    VoidCallback? onMedicineUpdated,
  }) async {
    await AppBottomSheet.show(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _MedicineEditSheetContent(
        medicine: medicine,
        availableLabels: availableLabels,
        storageService: storageService,
        onMedicineUpdated: onMedicineUpdated,
        scrollController: scrollController,
      ),
    );
  }

  @override
  State<MedicineEditSheet> createState() => _MedicineEditSheetState();
}

class _MedicineEditSheetState extends State<MedicineEditSheet> {
  @override
  Widget build(BuildContext context) {
    return _MedicineEditSheetContent(
      medicine: widget.medicine,
      availableLabels: widget.availableLabels,
      storageService: widget.storageService,
      onMedicineUpdated: widget.onMedicineUpdated,
      scrollController: ScrollController(),
    );
  }
}

/// Wewnętrzny widget z logiką edycji
class _MedicineEditSheetContent extends StatefulWidget {
  final Medicine medicine;
  final List<UserLabel> availableLabels;
  final StorageService storageService;
  final VoidCallback? onMedicineUpdated;
  final ScrollController scrollController;

  const _MedicineEditSheetContent({
    required this.medicine,
    required this.availableLabels,
    required this.storageService,
    this.onMedicineUpdated,
    required this.scrollController,
  });

  @override
  State<_MedicineEditSheetContent> createState() =>
      _MedicineEditSheetContentState();
}

class _MedicineEditSheetContentState extends State<_MedicineEditSheetContent> {
  late TextEditingController _nazwaController;
  late TextEditingController _opisController;
  late TextEditingController _wskazaniaController;
  late TextEditingController _customTagsController;

  late List<String> _selectedLabels;
  bool _hasChanges = false;
  bool _isSaving = false;

  // Walidacja w czasie rzeczywistym
  String? _nazwaError;

  @override
  void initState() {
    super.initState();

    _nazwaController = TextEditingController(text: widget.medicine.nazwa ?? '');
    _opisController = TextEditingController(text: widget.medicine.opis);
    _wskazaniaController = TextEditingController(
      text: widget.medicine.wskazania.join(', '),
    );

    // Wyodrębnienie tagów spoza predefiniowanych kategorii
    final categorizedTags = tagCategories.values.expand((e) => e).toSet();
    final customTags = widget.medicine.tagi
        .where((t) => !categorizedTags.contains(t))
        .toList();
    _customTagsController = TextEditingController(text: customTags.join(', '));

    _selectedLabels = List<String>.from(widget.medicine.labels);

    // Listeners dla walidacji w czasie rzeczywistym
    _nazwaController.addListener(_validateNazwa);
    _nazwaController.addListener(_markChanged);
    _opisController.addListener(_markChanged);
    _wskazaniaController.addListener(_markChanged);
    _customTagsController.addListener(_markChanged);
  }

  void _validateNazwa() {
    final nazwa = _nazwaController.text.trim();
    setState(() {
      if (nazwa.isEmpty) {
        _nazwaError = 'Nazwa leku jest wymagana';
      } else if (nazwa.length < 2) {
        _nazwaError = 'Nazwa musi mieć co najmniej 2 znaki';
      } else {
        _nazwaError = null;
      }
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    // Auto-save przy zamknięciu jeśli są zmiany
    if (_hasChanges && !_isSaving) {
      _saveChanges(showConfirmation: false);
    }
    _nazwaController.dispose();
    _opisController.dispose();
    _wskazaniaController.dispose();
    _customTagsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges({bool showConfirmation = true}) async {
    // Walidacja przed zapisem
    _validateNazwa();
    if (_nazwaError != null) {
      if (showConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_nazwaError!),
            backgroundColor: AppColors.expired,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Zbierz wszystkie zmiany
      final nazwa = _nazwaController.text.trim();
      final opis = _opisController.text.trim();
      final wskazania = _wskazaniaController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Własne tagi - połącz z systemowymi
      final categorizedTags = tagCategories.values.expand((e) => e).toSet();
      final systemTags = widget.medicine.tagi
          .where((t) => categorizedTags.contains(t))
          .toList();
      final newCustomTags = _customTagsController.text
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedMedicine = widget.medicine.copyWith(
        nazwa: nazwa,
        opis: opis.isEmpty ? '' : opis,
        wskazania: wskazania,
        labels: _selectedLabels,
        tagi: [...systemTags, ...newCustomTags],
      );

      await widget.storageService.saveMedicine(updatedMedicine);
      widget.onMedicineUpdated?.call();

      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zmiany zapisane'),
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleLabel(String labelId) {
    setState(() {
      if (_selectedLabels.contains(labelId)) {
        _selectedLabels.remove(labelId);
      } else {
        _selectedLabels.add(labelId);
      }
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Auto-save przy zamknięciu przez gesture/back
        if (didPop && _hasChanges && !_isSaving) {
          _saveChanges(showConfirmation: false);
        }
      },
      child: Column(
        children: [
          // === HEADER ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clipboardPenLine,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edytuj kartę leku',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_hasChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expiringSoon.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Niezapisane',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expiringSoon,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // === CONTENT ===
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAZWA
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: LucideIcons.textCursorInput,
                    title: 'Nazwa leku',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nazwaController,
                    isDark: isDark,
                    hintText: 'Wprowadź nazwę leku...',
                    errorText: _nazwaError,
                  ),

                  const SizedBox(height: 24),

                  // OPIS
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: LucideIcons.fileText,
                    title: 'Opis',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _opisController,
                    isDark: isDark,
                    hintText: 'Opis działania leku...',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // WSKAZANIA
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: LucideIcons.stethoscope,
                    title: 'Wskazania',
                    subtitle: 'Oddziel przecinkami',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _wskazaniaController,
                    isDark: isDark,
                    hintText: 'np. ból głowy, gorączka, przeziębienie...',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // ETYKIETY
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: LucideIcons.tags,
                    title: 'Etykiety',
                  ),
                  const SizedBox(height: 8),
                  _buildLabelsSelector(isDark),

                  const SizedBox(height: 24),

                  // WŁASNE TAGI
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: LucideIcons.hash,
                    title: 'Własne tagi',
                    subtitle: 'Tagi spoza listy kontrolowanej',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _customTagsController,
                    isDark: isDark,
                    hintText: 'np. domowe, mama, dziecko...',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // === FOOTER: SAVE BUTTON ===
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(30)
                      : Colors.black.withAlpha(10),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving || _nazwaError != null
                      ? null
                      : () => _saveChanges(),
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(LucideIcons.check, size: 18),
                  label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz wszystko'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            '• $subtitle',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool isDark,
    required String hintText,
    int maxLines = 1,
    String? errorText,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: NeuDecoration.basin(isDark: isDark, radius: 14).copyWith(
            border: errorText != null
                ? Border.all(color: AppColors.expired, width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expired,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabelsSelector(bool isDark) {
    if (widget.availableLabels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: NeuDecoration.basin(isDark: isDark, radius: 14),
        child: Row(
          children: [
            Icon(
              LucideIcons.info,
              size: 16,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'Brak dostępnych etykiet',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableLabels.map((label) {
        final isSelected = _selectedLabels.contains(label.id);
        final colorInfo = labelColors[label.color]!;
        final labelColor = Color(colorInfo.hexValue);

        return GestureDetector(
          onTap: () => _toggleLabel(label.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: isSelected
                ? NeuDecoration.pressed(
                    isDark: isDark,
                    radius: 14,
                  ).copyWith(border: Border.all(color: labelColor, width: 1.5))
                : NeuDecoration.flat(isDark: isDark, radius: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: labelColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.check, size: 14, color: labelColor),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
