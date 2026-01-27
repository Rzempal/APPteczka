import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/pharmaceutical_form_helper.dart';
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
  String? _selectedForm;
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
    _selectedForm = widget.medicine.pharmaceuticalForm;

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
        pharmaceuticalForm: _selectedForm,
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

                  // POSTAĆ FARMACEUTYCZNA
                  _buildSectionHeader(
                    theme,
                    isDark,
                    icon: PharmaceuticalFormHelper.getIcon(_selectedForm),
                    title: 'Postać farmaceutyczna',
                  ),
                  const SizedBox(height: 8),
                  _buildFormSelector(isDark),

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

  Widget _buildFormSelector(bool isDark) {
    final theme = Theme.of(context);
    final formIcon = PharmaceuticalFormHelper.getIcon(_selectedForm);
    final displayText = _selectedForm ?? 'Wybierz postać...';

    return GestureDetector(
      onTap: () => _showFormPicker(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: NeuDecoration.basin(isDark: isDark, radius: 14),
        child: Row(
          children: [
            Icon(
              formIcon,
              size: 20,
              color: _selectedForm != null
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white54 : Colors.black38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: _selectedForm != null
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  /// Pokazuje BottomSheet z listą postaci farmaceutycznych i wyszukiwarką
  void _showFormPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormPickerSheet(
        isDark: isDark,
        selectedForm: _selectedForm,
        onSelect: (form) {
          setState(() {
            _selectedForm = form;
            _hasChanges = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// BottomSheet z listą postaci farmaceutycznych i wyszukiwarką
class _FormPickerSheet extends StatefulWidget {
  final bool isDark;
  final String? selectedForm;
  final ValueChanged<String> onSelect;

  const _FormPickerSheet({
    required this.isDark,
    required this.selectedForm,
    required this.onSelect,
  });

  @override
  State<_FormPickerSheet> createState() => _FormPickerSheetState();
}

class _FormPickerSheetState extends State<_FormPickerSheet> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<PharmaceuticalFormDefinition> _filteredDefinitions = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredDefinitions = List.from(PharmaceuticalFormHelper.definitions);
    _searchController.addListener(_filterForms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterForms() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredDefinitions = List.from(PharmaceuticalFormHelper.definitions);
      } else {
        _filteredDefinitions = PharmaceuticalFormHelper.definitions.where((
          def,
        ) {
          return def.mainName.toLowerCase().contains(query) ||
              def.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // Stała minimalna wysokość 50%
    final minHeight = screenHeight * 0.5;
    final maxHeight = screenHeight * 0.85;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.pill, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Postać farmaceutyczna',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search bar with Floating Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: NeuDecoration.basin(
                isDark: widget.isDark,
                radius: 14,
              ),
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 20,
                    color: widget.isDark ? Colors.white54 : Colors.black38,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  labelText: 'Wyszukaj postać...',
                  labelStyle: TextStyle(
                    color: widget.isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: false,
                ),
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _filteredDefinitions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final def = _filteredDefinitions[index];
                final isSelected = widget.selectedForm == def.mainName;

                return _buildListItem(theme, def, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    ThemeData theme,
    PharmaceuticalFormDefinition def,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => widget.onSelect(def.mainName),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? NeuDecoration.pressed(isDark: widget.isDark, radius: 12).copyWith(
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(100),
                  width: 1.5,
                ),
              )
            : NeuDecoration.flat(isDark: widget.isDark, radius: 12),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                def.icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (widget.isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 12),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.mainName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (def.description.isNotEmpty)
                    Text(
                      def.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Unit Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black26 : Colors.white60,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Text(
                PharmaceuticalFormHelper.getUnitLabel(def.mainName),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
