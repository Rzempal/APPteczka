import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final Set<String> selectedLabels;
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

/// Kategorie zakładek filtrów
enum FilterTab {
  labels,
  expiry,
  symptoms,
  classification,
  substances,
  custom;

  IconData get icon {
    switch (this) {
      case FilterTab.labels:
        return LucideIcons.tag;
      case FilterTab.expiry:
        return LucideIcons.calendarClock;
      case FilterTab.symptoms:
        return LucideIcons.activity;
      case FilterTab.classification:
        return LucideIcons.folderTree;
      case FilterTab.substances:
        return LucideIcons.flaskConical;
      case FilterTab.custom:
        return LucideIcons.hash;
    }
  }

  String get label {
    switch (this) {
      case FilterTab.labels:
        return 'Etykiety';
      case FilterTab.expiry:
        return 'Termin';
      case FilterTab.symptoms:
        return 'Objawy';
      case FilterTab.classification:
        return 'Klasyfikacja';
      case FilterTab.substances:
        return 'Substancje';
      case FilterTab.custom:
        return 'Moje';
    }
  }
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

/// Podkategorie dla "Klasyfikacja"
const Map<String, List<String>> tagsKlasyfikacja = {
  'Rodzaj i postać leku': [
    'bez recepty',
    'na receptę',
    'suplement',
    'wyrób medyczny',
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
};

/// Popularne tagi - predefiniowane
const List<String> popularSymptomsTag = [
  'ból',
  'gorączka',
  'przeziębienie',
  'kaszel',
  'alergia',
];
const List<String> popularClassificationTags = [
  'bez recepty',
  'tabletki',
  'syrop',
  'dla dzieci',
  'suplement',
];

/// Wszystkie tagi kategorii (dla wykluczeń w "Moje")
final Map<String, List<String>> tagCategories = {...tagsKlasyfikacja};

/// Identyfikuje tagi będące substancjami czynnymi (łacińska nomenklatura)
bool isActiveSubstanceTag(String tag) {
  final lower = tag.toLowerCase();
  final latinEndings = [
    'um',
    'is',
    'us',
    'ae',
    'i',
    'as',
    'os',
    'dum',
    'lum',
    'num',
    'rum',
    'tum',
    'chloridum',
    'bromidum',
    'iodidum',
    'natricum',
    'kalicum',
    'calcicum',
  ];

  for (final ending in latinEndings) {
    if (lower.endsWith(ending) && tag.length > ending.length + 2) {
      return true;
    }
  }

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

/// FiltersSheet z Horizontal Category Tabs - Soft UI 2026
class FiltersSheet extends StatefulWidget {
  final FilterState initialState;
  final List<String> availableTags;
  final List<UserLabel> availableLabels;
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
  FilterTab _activeTab = FilterTab.symptoms;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    // Auto-select first tab with content
    if (widget.availableLabels.isNotEmpty) {
      _activeTab = FilterTab.labels;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Buduje zawartość FiltersSheet do osadzenia w AppBottomSheet.show
  /// [scrollController] - przekazany z AppBottomSheet
  Widget buildContent(BuildContext context, ScrollController scrollController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onApply(_state);
        }
      },
      child: Column(
        children: [
          // Header with title and clear button
          _buildHeader(context),

          // Search bar (inset neumorphic)
          _buildSearchBar(context, isDark),

          // Horizontal category tabs
          _buildCategoryTabs(context, isDark),

          const Divider(height: 1),

          // Content area
          Expanded(child: _buildTabContent(context, scrollController, isDark)),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fallback dla kompatybilności wstecznej - używa buildContent z pustym scrollController
    return buildContent(context, ScrollController());
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          if (_state.hasActiveFilters)
            IconButton(
              onPressed: _clearFilters,
              icon: Icon(LucideIcons.funnelX, color: AppColors.expired),
              tooltip: 'Wyczyść filtry',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: NeuDecoration.basin(isDark: isDark, radius: 16),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              size: 18,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Szukaj w tagach...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: FilterTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = FilterTab.values[index];
          final isActive = tab == _activeTab;
          final count = _getTabCount(tab);

          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: isActive
                  ? NeuDecoration.pressed(isDark: isDark, radius: 14)
                  : NeuDecoration.flat(isDark: isDark, radius: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 16,
                    color: isActive
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withAlpha(50)
                            : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getTabCount(FilterTab tab) {
    switch (tab) {
      case FilterTab.labels:
        return widget.availableLabels.length;
      case FilterTab.expiry:
        return ExpiryFilter.values.length;
      case FilterTab.symptoms:
        return tagsObjawIDzialanie.values
            .expand((e) => e)
            .where((t) => widget.availableTags.contains(t))
            .length;
      case FilterTab.classification:
        return tagsKlasyfikacja.values
            .expand((e) => e)
            .where((t) => widget.availableTags.contains(t))
            .length;
      case FilterTab.substances:
        return extractActiveSubstances(widget.availableTags).length;
      case FilterTab.custom:
        return _getCustomTags().length;
    }
  }

  List<String> _getCustomTags() {
    final categorizedTags = <String>{
      ...tagCategories.values.expand((e) => e),
      ...tagsObjawIDzialanie.values.expand((e) => e),
    };
    return widget.availableTags
        .where((t) => !categorizedTags.contains(t) && !isActiveSubstanceTag(t))
        .toList()
      ..sort();
  }

  Widget _buildTabContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: _buildActiveTabContent(isDark),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case FilterTab.labels:
        return _buildLabelsTab(isDark);
      case FilterTab.expiry:
        return _buildExpiryTab(isDark);
      case FilterTab.symptoms:
        return _buildSymptomsTab(isDark);
      case FilterTab.classification:
        return _buildClassificationTab(isDark);
      case FilterTab.substances:
        return _buildSubstancesTab(isDark);
      case FilterTab.custom:
        return _buildCustomTagsTab(isDark);
    }
  }

  // ========== TAB: ETYKIETY ==========
  Widget _buildLabelsTab(bool isDark) {
    if (widget.availableLabels.isEmpty) {
      return _buildEmptyState('Brak etykiet', 'Dodaj etykiety do swoich leków');
    }

    final filtered = widget.availableLabels
        .where(
          (l) =>
              _searchQuery.isEmpty ||
              l.name.toLowerCase().contains(_searchQuery),
        )
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filtered.map((label) {
        final isSelected = _state.selectedLabels.contains(label.id);
        final colorInfo = labelColors[label.color]!;

        return GestureDetector(
          onTap: () => _toggleLabel(label.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: isSelected
                ? NeuDecoration.pressed(isDark: isDark, radius: 14).copyWith(
                    border: Border.all(
                      color: Color(colorInfo.hexValue),
                      width: 1.5,
                    ),
                  )
                : NeuDecoration.flat(isDark: isDark, radius: 14),
            child: Row(
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
                const SizedBox(width: 8),
                Text(
                  label.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleLabel(String labelId) {
    setState(() {
      final newLabels = Set<String>.from(_state.selectedLabels);
      if (newLabels.contains(labelId)) {
        newLabels.remove(labelId);
      } else {
        newLabels.add(labelId);
      }
      _state = _state.copyWith(selectedLabels: newLabels);
    });
  }

  // ========== TAB: TERMIN WAŻNOŚCI ==========
  Widget _buildExpiryTab(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpiryFilter.values.map((filter) {
        final isSelected = _state.expiryFilter == filter;

        return GestureDetector(
          onTap: () {
            setState(() {
              _state = _state.copyWith(
                expiryFilter: isSelected ? ExpiryFilter.all : filter,
              );
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: isSelected
                ? NeuDecoration.pressed(isDark: isDark, radius: 14).copyWith(
                    border: Border.all(
                      color: _getExpiryColor(filter),
                      width: 1.5,
                    ),
                  )
                : NeuDecoration.flat(isDark: isDark, radius: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getExpiryIcon(filter),
                  size: 16,
                  color: isSelected
                      ? _getExpiryColor(filter)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  filter.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== TAB: OBJAWY ==========
  Widget _buildSymptomsTab(bool isDark) {
    return _buildTagTabWithPopular(
      tagsObjawIDzialanie,
      popularSymptomsTag,
      isDark,
    );
  }

  // ========== TAB: KLASYFIKACJA ==========
  Widget _buildClassificationTab(bool isDark) {
    return _buildTagTabWithPopular(
      tagsKlasyfikacja,
      popularClassificationTags,
      isDark,
    );
  }

  Widget _buildTagTabWithPopular(
    Map<String, List<String>> categories,
    List<String> popularTags,
    bool isDark,
  ) {
    // Filter available tags
    final allTags = categories.values.expand((e) => e).toList();
    final availableInCategory = allTags
        .where((t) => widget.availableTags.contains(t))
        .toList();

    // Filter by search
    final filtered = _searchQuery.isEmpty
        ? availableInCategory
        : availableInCategory
              .where((t) => t.toLowerCase().contains(_searchQuery))
              .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'Brak tagów',
        'Żaden tag w tej kategorii nie pasuje',
      );
    }

    // Popular tags (that are available)
    final popular = popularTags.where((t) => filtered.contains(t)).toList();

    // Remaining tags
    final remaining = filtered.where((t) => !popular.contains(t)).toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (popular.isNotEmpty && _searchQuery.isEmpty) ...[
          _buildSectionHeader('Popularne', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popular.map((tag) => _buildTagChip(tag, isDark)).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (remaining.isNotEmpty) ...[
          _buildSectionHeader('Wszystkie (A-Z)', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: remaining
                .map((tag) => _buildTagChip(tag, isDark))
                .toList(),
          ),
        ],
      ],
    );
  }

  // ========== TAB: SUBSTANCJE ==========
  Widget _buildSubstancesTab(bool isDark) {
    final substances = extractActiveSubstances(widget.availableTags);
    final filtered = _searchQuery.isEmpty
        ? substances
        : substances
              .where((t) => t.toLowerCase().contains(_searchQuery))
              .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'Brak substancji czynnych',
        'Substancje są wykrywane automatycznie z bazy leków (łacińskie nazwy)',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filtered.map((tag) => _buildTagChip(tag, isDark)).toList(),
    );
  }

  // ========== TAB: MOJE TAGI ==========
  Widget _buildCustomTagsTab(bool isDark) {
    final customTags = _getCustomTags();
    final filtered = _searchQuery.isEmpty
        ? customTags
        : customTags
              .where((t) => t.toLowerCase().contains(_searchQuery))
              .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'Brak niestandardowych tagów',
        'Dodaj własne tagi do swoich leków',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filtered.map((tag) => _buildTagChip(tag, isDark)).toList(),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }

  Widget _buildTagChip(String tag, bool isDark) {
    final isSelected = _state.selectedTags.contains(tag);

    return GestureDetector(
      onTap: () => _toggleTag(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: isSelected
            ? NeuDecoration.pressed(isDark: isDark, radius: 14).copyWith(
                border: Border.all(color: AppColors.primary, width: 1.5),
              )
            : NeuDecoration.flat(isDark: isDark, radius: 14),
        child: Text(
          tag,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      final newTags = Set<String>.from(_state.selectedTags);
      if (newTags.contains(tag)) {
        newTags.remove(tag);
      } else {
        newTags.add(tag);
      }
      _state = _state.copyWith(selectedTags: newTags);
    });
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(LucideIcons.searchX, size: 48, color: AppColors.lightTextMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_state.hasActiveFilters)
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expired,
                  side: BorderSide(color: AppColors.expired),
                ),
                child: Text('Wyczyść (${_state.activeFilterCount})'),
              ),
            ),
          if (_state.hasActiveFilters) const SizedBox(width: 12),
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

    // Filtr tagów (logika AND)
    if (state.selectedTags.isNotEmpty) {
      if (!state.selectedTags.every((t) => m.tagi.contains(t))) {
        return false;
      }
    }

    // Filtr etykiet (logika AND)
    if (state.selectedLabels.isNotEmpty) {
      if (!state.selectedLabels.every((l) => m.labels.contains(l))) {
        return false;
      }
    }

    // Filtr terminu ważności LUB duplikatów
    if (state.expiryFilter != ExpiryFilter.all) {
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
