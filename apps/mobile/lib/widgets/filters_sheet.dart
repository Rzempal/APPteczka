import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../models/medicine.dart';
import '../models/label.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'neumorphic/neumorphic.dart';
import '../utils/duplicate_detection.dart';

/// Stan filtra - wersja Mobile kompatybilna z logiką Web
class FilterState {
  final String searchQuery;
  final Set<String> selectedTags;
  final Set<String> selectedLabels; // Nowe: filtrowanie po etykietach
  final ExpiryFilter expiryFilter;

  const FilterState({
    this.searchQuery = '',
    this.selectedTags = const {},
    this.selectedLabels = const {},
    this.expiryFilter = ExpiryFilter.all,
  });

  FilterState copyWith({
    String? searchQuery,
    Set<String>? selectedTags,
    Set<String>? selectedLabels,
    ExpiryFilter? expiryFilter,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedLabels: selectedLabels ?? this.selectedLabels,
      expiryFilter: expiryFilter ?? this.expiryFilter,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedTags.isNotEmpty ||
      selectedLabels.isNotEmpty ||
      expiryFilter != ExpiryFilter.all;

  int get activeFilterCount {
    int count = 0;
    if (expiryFilter != ExpiryFilter.all) count++;
    count += selectedTags.length;
    count += selectedLabels.length;
    return count;
  }
}

enum ExpiryFilter {
  all('Wszystkie'),
  expired('Przeterminowane'),
  expiringSoon('Kończą się'),
  valid('Ważne'),
  duplicates('Potencjalne duplikaty');

  final String label;
  const ExpiryFilter(this.label);
}

/// Podkategorie dla "Objawy i działanie" - posortowane alfabetycznie
const Map<String, List<String>> tagsObjawIDzialanie = {
  'Ból': [
    'ból',
    'ból gardła',
    'ból głowy',
    'ból menstruacyjny',
    'ból mięśni',
    'ból ucha',
    'mięśnie i stawy',
    'przeciwbólowy',
  ],
  'Układ pokarmowy': [
    'biegunka',
    'kolka',
    'nudności',
    'przeczyszczający',
    'przeciwbiegunkowy',
    'przeciwwymiotny',
    'układ pokarmowy',
    'wzdęcia',
    'wymioty',
    'zaparcia',
    'zgaga',
  ],
  'Układ oddechowy': [
    'duszność',
    'gorączka',
    'kaszel',
    'katar',
    'nos',
    'przeciwgorączkowy',
    'przeciwkaszlowy',
    'układ oddechowy',
    'wykrztuśny',
  ],
  'Skóra i alergia': [
    'alergia',
    'nawilżający',
    'oparzenie',
    'przeciwhistaminowy',
    'przeciwświądowy',
    'rana',
    'skóra',
    'sucha skóra',
    'suche oczy',
    'świąd',
    'ukąszenie',
    'wysypka',
  ],
  'Inne': [
    'afty',
    'antybiotyk',
    'bezsenność',
    'choroba lokomocyjna',
    'jama ustna',
    'odkażający',
    'probiotyk',
    'przeciwzapalny',
    'rozkurczowy',
    'steryd',
    'stres',
    'układ nerwowy',
    'uspokajający',
    'ząbkowanie',
  ],
};

/// Podkategorie dla "Klasyfikacja" - Rodzaj i postac, Grupa docelowa, Typ infekcji
const Map<String, List<String>> tagsKlasyfikacja = {
  'Rodzaj i postać leku': [
    // Status recepty
    'bez recepty',
    'na receptę',
    'suplement',
    'wyrób medyczny',
    // Postaci farmaceutyczne
    'tabletki',
    'kapsułki',
    'syrop',
    'maść',
    'zastrzyki',
    'krople',
    'aerozol',
    'czopki',
    'plastry',
    'proszek/zawiesina',
  ],
  'Grupa docelowa': [
    'dla dorosłych',
    'dla dzieci',
    'dla kobiet w ciąży',
    'dla niemowląt',
  ],
  'Typ infekcji': [
    'grypa',
    'infekcja bakteryjna',
    'infekcja grzybicza',
    'infekcja wirusowa',
    'przeziębienie',
  ],
  // 'Substancja czynna' - dynamiczna, generowana z apteczki uzytkownika
};

/// Wszystkie tagi kategorii (dla wykluczeń w "Moje")
final Map<String, List<String>> tagCategories = {...tagsKlasyfikacja};

/// Identyfikuje tagi bedace substancjami czynnymi (lacinska nomenklatura)
/// Np. "Escitalopramum", "Paracetamolum", "Ambroxoli hydrochloridum"
bool isActiveSubstanceTag(String tag) {
  // Substancje czynne maja lacinska nazwe - koncowki typowe
  final lower = tag.toLowerCase();
  final latinEndings = [
    'um', 'is', 'us', 'ae', 'i', 'as', 'os', // typowe lacińskie
    'dum', 'lum', 'num', 'rum', 'tum', // -um z przedrostkiem
    'chloridum', 'bromidum', 'iodidum', // sole
    'natricum', 'kalicum', 'calcicum', // sole z kationami
  ];

  // Sprawdz czy konczy sie na lacinska koncowke
  for (final ending in latinEndings) {
    if (lower.endsWith(ending) && tag.length > ending.length + 2) {
      return true;
    }
  }

  // Sprawdz czy zawiera typowe wzorce substancji
  if (lower.contains(' hydrochloridum') ||
      lower.contains(' natricum') ||
      lower.contains(' kalicum') ||
      lower.contains('acidum ')) {
    return true;
  }

  return false;
}

/// Wyodrębnia substancje czynne z listy tagów
List<String> extractActiveSubstances(List<String> tags) {
  return tags.where(isActiveSubstanceTag).toList()..sort();
}

/// Filtr Sheet - styl zbliżony do wersji Web
class FiltersSheet extends StatefulWidget {
  final FilterState initialState;
  final List<String> availableTags;
  final List<UserLabel> availableLabels; // Nowe: etykiety
  final Function(FilterState) onApply;

  const FiltersSheet({
    super.key,
    required this.initialState,
    required this.availableTags,
    required this.availableLabels,
    required this.onApply,
  });

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late FilterState _state;
  final Map<String, bool> _expandedCategories = {};
  bool _labelsExpanded = false;
  bool _expiryExpanded = false;
  bool _tagsExpanded = false;
  bool _otherTagsExpanded = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    for (final category in tagCategories.keys) {
      _expandedCategories[category] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Auto-save filters on close (swipe down or tap outside)
          widget.onApply(_state);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(BottomSheetConstants.radius),
              ),
            ),
            child: Column(
              children: [
                // Handle
                const BottomSheetDragHandle(),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.funnel,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtry',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Clear filters - red icon
                    if (_state.hasActiveFilters)
                      IconButton(
                        onPressed: _clearFilters,
                        icon: Icon(
                          LucideIcons.funnelX,
                          color: AppColors.expired,
                        ),
                        tooltip: 'Wyczyść filtry',
                      ),
                  ],
                ),
              ),

              const Divider(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ========== MOJE ETYKIETY ==========
                      if (widget.availableLabels.isNotEmpty) ...[
                        _buildLabelsSectionHeader(),
                        if (_labelsExpanded) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.availableLabels.map((label) {
                              final isSelected = _state.selectedLabels.contains(
                                label.id,
                              );
                              final colorInfo = labelColors[label.color]!;

                              return FilterChip(
                                selected: isSelected,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Color(colorInfo.hexValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(label.name),
                                  ],
                                ),
                                labelStyle: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    final newLabels = Set<String>.from(
                                      _state.selectedLabels,
                                    );
                                    if (selected) {
                                      newLabels.add(label.id);
                                    } else {
                                      newLabels.remove(label.id);
                                    }
                                    _state = _state.copyWith(
                                      selectedLabels: newLabels,
                                    );
                                  });
                                },
                                selectedColor: Color(
                                  colorInfo.hexValue,
                                ).withValues(alpha: 0.3),
                                checkmarkColor: Color(colorInfo.hexValue),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],

                      // ========== TERMIN WAŻNOŚCI ==========
                      _buildMainSectionHeader(
                        icon: LucideIcons.calendarHeart,
                        title: 'Termin ważności',
                        isExpanded: _expiryExpanded,
                        onTap: () =>
                            setState(() => _expiryExpanded = !_expiryExpanded),
                        trailing: _state.expiryFilter != ExpiryFilter.all
                            ? Icon(
                                _getExpiryIcon(_state.expiryFilter),
                                size: 16,
                                color: _getExpiryColor(_state.expiryFilter),
                              )
                            : null,
                      ),
                      if (_expiryExpanded) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ExpiryFilter.values.map((filter) {
                            final isSelected = _state.expiryFilter == filter;
                            return FilterChip(
                              selected: isSelected,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check, size: 16),
                                    const SizedBox(width: 4),
                                  ],
                                  Icon(_getExpiryIcon(filter), size: 16),
                                  const SizedBox(width: 4),
                                  Text(filter.label),
                                ],
                              ),
                              labelStyle: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _state = _state.copyWith(
                                    expiryFilter: selected
                                        ? filter
                                        : ExpiryFilter.all,
                                  );
                                });
                              },
                              selectedColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: AppColors.primary,
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ========== TAGI ==========
                      _buildMainSectionHeader(
                        icon: LucideIcons.hash,
                        title: 'Tagi',
                        isExpanded: _tagsExpanded,
                        onTap: () =>
                            setState(() => _tagsExpanded = !_tagsExpanded),
                        trailing: _state.selectedTags.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_state.selectedTags.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_tagsExpanded) ...[
                        const SizedBox(height: 12),

                        // === KLASYFIKACJA (z podkategoriami + dynamiczna Substancja czynna) ===
                        _buildKlasyfikacjaWithSubstances(
                          _expandedCategories['Klasyfikacja'] ?? false,
                        ),

                        // === OBJAWY I DZIAŁANIE (z podkategoriami) ===
                        _buildCategoryWithSubcategories(
                          'Objawy i działanie',
                          tagsObjawIDzialanie,
                          _expandedCategories['Objawy i działanie'] ?? false,
                        ),

                        // Moje tagi (niestandardowe)
                        _buildOtherTagsSection(),
                      ], // Close if (_tagsExpanded)

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Clear button
                    if (_state.hasActiveFilters)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.expired,
                            side: BorderSide(color: AppColors.expired),
                          ),
                          child: const Text('Wyczyść'),
                        ),
                      ),
                    if (_state.hasActiveFilters) const SizedBox(width: 12),
                    // Apply button
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(_state);
                          Navigator.pop(context);
                        },
                        child: const Text('Zastosuj filtry'),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabelsSectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _labelsExpanded = !_labelsExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: NeuDecoration.flat(isDark: isDark, radius: 8),
        child: Row(
          children: [
            // Chevron arrow with rotation
            Transform.rotate(
              angle: _labelsExpanded ? math.pi / 2 : 0,
              child: Icon(
                LucideIcons.chevronRight,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.tag, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Moje etykiety',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            if (_state.selectedLabels.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_state.selectedLabels.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Main section header (Neu style) for Moje etykiety, Termin ważności, #tags
  Widget _buildMainSectionHeader({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: NeuDecoration.flat(isDark: isDark, radius: 8),
        child: Row(
          children: [
            // Chevron arrow with rotation
            Transform.rotate(
              angle: isExpanded ? math.pi / 2 : 0,
              child: Icon(
                LucideIcons.chevronRight,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
      ),
    );
  }

  /// Kategoria z podkategoriami (dla "Objawy i działanie")
  Widget _buildCategoryWithSubcategories(
    String name,
    Map<String, List<String>> subcategories,
    bool isExpanded,
  ) {
    // Zlicz wszystkie dostępne tagi
    final allTags = subcategories.values.expand((t) => t).toList();
    final availableTags = allTags
        .where((t) => widget.availableTags.contains(t))
        .toList();

    if (availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount = availableTags
        .where((t) => _state.selectedTags.contains(t))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Główny nagłówek kategorii
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[name] = !(_expandedCategories[name] ?? false);
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Transform.rotate(
                  angle: isExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${availableTags.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Podkategorie
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subcategories.entries.map((subEntry) {
                final subName = subEntry.key;
                final subTags =
                    subEntry.value
                        .where((t) => widget.availableTags.contains(t))
                        .toList()
                      ..sort(); // Sortowanie alfabetyczne

                if (subTags.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        subName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subTags.map(_buildTagChip).toList(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Buduje sekcje Klasyfikacja z dynamiczna podkategoria "Substancja czynna"
  Widget _buildKlasyfikacjaWithSubstances(bool isExpanded) {
    // Pobierz substancje czynne z dostepnych tagow
    final activeSubstances = extractActiveSubstances(widget.availableTags);

    // Polacz statyczne kategorie z dynamiczna
    final subcategories = Map<String, List<String>>.from(tagsKlasyfikacja);
    if (activeSubstances.isNotEmpty) {
      subcategories['Substancja czynna'] = activeSubstances;
    }

    // Zlicz wszystkie dostepne tagi
    final allTags = subcategories.values.expand((t) => t).toList();
    final availableTags =
        allTags.where((t) => widget.availableTags.contains(t)).toList();

    if (availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount =
        availableTags.where((t) => _state.selectedTags.contains(t)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Główny nagłówek kategorii
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories['Klasyfikacja'] =
                  !(_expandedCategories['Klasyfikacja'] ?? false);
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Transform.rotate(
                  angle: isExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Klasyfikacja',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${availableTags.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Podkategorie
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subcategories.entries.map((subEntry) {
                final subName = subEntry.key;
                final subTags =
                    subEntry.value
                        .where((t) => widget.availableTags.contains(t))
                        .toList()
                      ..sort();

                if (subTags.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        subName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subTags.map(_buildTagChip).toList(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategorySection(
    String name,
    List<String> tags,
    bool isExpanded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[name] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Chevron arrow with rotation
                Transform.rotate(
                  angle: isExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tags.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOtherTagsSection() {
    // Zbierz wszystkie tagi z kategorii ORAZ z podkategorii "Objawy i działanie"
    final categorizedTags = <String>{
      ...tagCategories.values.expand((e) => e),
      ...tagsObjawIDzialanie.values.expand((e) => e),
    };
    // Wyklucz substancje czynne (wyswietlane w Klasyfikacja > Substancja czynna)
    final otherTags = widget.availableTags
        .where((t) => !categorizedTags.contains(t) && !isActiveSubstanceTag(t))
        .toList()
      ..sort();

    if (otherTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Styled like "Objawy i działanie" - bez zielonego akcentu
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _otherTagsExpanded = !_otherTagsExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Chevron arrow with rotation
                Transform.rotate(
                  angle: _otherTagsExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Moje',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${otherTags.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_otherTagsExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: otherTags.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _state.selectedTags.contains(tag);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(tag),
      labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
      onSelected: (selected) {
        setState(() {
          final newTags = Set<String>.from(_state.selectedTags);
          if (selected) {
            newTags.add(tag);
          } else {
            newTags.remove(tag);
          }
          _state = _state.copyWith(selectedTags: newTags);
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  void _clearFilters() {
    setState(() {
      _state = const FilterState();
    });
  }

  IconData _getExpiryIcon(ExpiryFilter filter) {
    switch (filter) {
      case ExpiryFilter.all:
        return Icons.all_inclusive;
      case ExpiryFilter.expired:
        return Icons.error_outline;
      case ExpiryFilter.expiringSoon:
        return Icons.warning_amber_outlined;
      case ExpiryFilter.valid:
        return Icons.check_circle_outline;
      case ExpiryFilter.duplicates:
        return LucideIcons.copy;
    }
  }

  Color _getExpiryColor(ExpiryFilter filter) {
    switch (filter) {
      case ExpiryFilter.all:
        return AppColors.primary;
      case ExpiryFilter.expired:
        return AppColors.expired;
      case ExpiryFilter.expiringSoon:
        return AppColors.expiringSoon;
      case ExpiryFilter.valid:
        return AppColors.valid;
      case ExpiryFilter.duplicates:
        return AppColors.primary;
    }
  }
}

/// Funkcja aplikująca filtry do listy leków
List<Medicine> applyFilters(List<Medicine> medicines, FilterState state) {
  return medicines.where((m) {
    // Filtr tekstowy
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      final matchesName = m.nazwa?.toLowerCase().contains(query) ?? false;
      final matchesDesc = m.opis.toLowerCase().contains(query);
      final matchesTags = m.tagi.any((t) => t.toLowerCase().contains(query));
      final matchesWskazania = m.wskazania.any(
        (w) => w.toLowerCase().contains(query),
      );

      if (!matchesName && !matchesDesc && !matchesTags && !matchesWskazania) {
        return false;
      }
    }

    // Filtr tagów (logika AND - lek musi mieć WSZYSTKIE wybrane tagi)
    if (state.selectedTags.isNotEmpty) {
      if (!state.selectedTags.every((t) => m.tagi.contains(t))) {
        return false;
      }
    }

    // Filtr etykiet (logika AND - lek musi mieć WSZYSTKIE wybrane etykiety)
    if (state.selectedLabels.isNotEmpty) {
      if (!state.selectedLabels.every((l) => m.labels.contains(l))) {
        return false;
      }
    }

    // Filtr terminu ważności LUB duplikatów
    if (state.expiryFilter != ExpiryFilter.all) {
      // Specjalna obsługa dla duplikatów - wymaga całej listy
      if (state.expiryFilter == ExpiryFilter.duplicates) {
        if (!hasDuplicates(m, medicines)) return false;
      } else {
        final status = m.expiryStatus;
        switch (state.expiryFilter) {
          case ExpiryFilter.expired:
            if (status != ExpiryStatus.expired) return false;
          case ExpiryFilter.expiringSoon:
            if (status != ExpiryStatus.expiringSoon) return false;
          case ExpiryFilter.valid:
            if (status != ExpiryStatus.valid) return false;
          case ExpiryFilter.all:
          case ExpiryFilter.duplicates:
            break;
        }
      }
    }

    return true;
  }).toList();
}
