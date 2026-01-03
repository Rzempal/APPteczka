import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../models/medicine.dart';
import '../models/label.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';

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
  valid('Ważne');

  final String label;
  const ExpiryFilter(this.label);
}

/// Kategorie tagów - jak w wersji Web
const Map<String, List<String>> tagCategories = {
  'Objawy': [
    'ból',
    'ból głowy',
    'ból gardła',
    'ból mięśni',
    'ból menstruacyjny',
    'ból ucha',
    'nudności',
    'wymioty',
    'biegunka',
    'zaparcia',
    'wzdęcia',
    'zgaga',
    'kolka',
    'gorączka',
    'kaszel',
    'katar',
    'duszność',
    'świąd',
    'wysypka',
    'oparzenie',
    'ukąszenie',
    'rana',
    'sucha skóra',
    'suche oczy',
    'alergia',
    'bezsenność',
    'stres',
    'choroba lokomocyjna',
    'afty',
    'ząbkowanie',
  ],
  'Typ infekcji': [
    'infekcja wirusowa',
    'infekcja bakteryjna',
    'infekcja grzybicza',
    'przeziębienie',
    'grypa',
  ],
  'Działanie leku': [
    'przeciwbólowy',
    'przeciwgorączkowy',
    'przeciwzapalny',
    'przeciwhistaminowy',
    'przeciwkaszlowy',
    'wykrztuśny',
    'przeciwwymiotny',
    'przeciwbiegunkowy',
    'przeczyszczający',
    'probiotyk',
    'nawilżający',
  ],
  'Grupa użytkowników': ['dla dorosłych', 'dla dzieci', 'dla niemowląt'],
};

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
  bool _labelsExpanded = true;
  bool _expiryExpanded = true;
  bool _tagsExpanded = true;
  bool _otherTagsExpanded = true;

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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Wyczyść'),
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
                    ),
                    if (_tagsExpanded) ...[
                      const SizedBox(height: 12),

                      // Kategorie tagów
                      ...tagCategories.entries.map((entry) {
                        final categoryName = entry.key;
                        final categoryTags = entry.value;
                        final availableInCategory = categoryTags
                            .where((t) => widget.availableTags.contains(t))
                            .toList();

                        if (availableInCategory.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final isExpanded =
                            _expandedCategories[categoryName] ?? false;

                        return _buildCategorySection(
                          categoryName,
                          availableInCategory,
                          isExpanded,
                        );
                      }),

                      // Inne tagi
                      _buildOtherTagsSection(),
                    ], // Close if (_tagsExpanded)

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_state);
                    Navigator.pop(context);
                  },
                  child: const Text('Zastosuj filtry'),
                ),
              ),
            ),
          ],
        ),
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
          ],
        ),
      ),
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
    final categorizedTags = tagCategories.values.expand((e) => e).toSet();
    final otherTags = widget.availableTags
        .where((t) => !categorizedTags.contains(t))
        .toList();

    if (otherTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Styled like other subcategory sections
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _otherTagsExpanded = !_otherTagsExpanded;
            });
          },
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
                  angle: _otherTagsExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Inne',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${otherTags.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withValues(alpha: 0.7),
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

    // Filtr terminu ważności
    if (state.expiryFilter != ExpiryFilter.all) {
      final status = m.expiryStatus;
      switch (state.expiryFilter) {
        case ExpiryFilter.expired:
          if (status != ExpiryStatus.expired) return false;
        case ExpiryFilter.expiringSoon:
          if (status != ExpiryStatus.expiringSoon) return false;
        case ExpiryFilter.valid:
          if (status != ExpiryStatus.valid) return false;
        case ExpiryFilter.all:
          break;
      }
    }

    return true;
  }).toList();
}
