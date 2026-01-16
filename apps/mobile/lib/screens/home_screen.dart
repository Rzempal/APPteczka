import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../config/app_config.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/theme_provider.dart';
import '../services/update_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/medicine_card.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/label_selector.dart';
import '../widgets/karton_icons.dart';
import '../widgets/app_bottom_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic/neumorphic.dart';
import 'edit_medicine_screen.dart';
import 'medicine_detail_sheet.dart';
import 'pdf_viewer_screen.dart';
import '../utils/tag_normalization.dart';
import '../utils/duplicate_detection.dart';

/// Opcje sortowania
enum SortOption {
  nameAsc('Nazwa A-Z', LucideIcons.arrowDownAZ),
  nameDesc('Nazwa Z-A', LucideIcons.arrowUpAZ),
  expiryAsc('Termin ważności od najkrótszego', LucideIcons.clockArrowDown),
  expiryDesc('Termin ważności od najdłuższego', LucideIcons.clockArrowUp),
  dateAddedAsc('Data dodania od najstarszego', LucideIcons.calendarArrowUp),
  dateAddedDesc('Data dodania od najnowszego', LucideIcons.calendarArrowDown);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

/// Główny ekran - lista leków (Apteczka)
class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  final UpdateService updateService;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToAdd;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.themeProvider,
    required this.updateService,
    this.onNavigateToSettings,
    this.onNavigateToAdd,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

/// Publiczny State dla HomeScreen - umożliwia dostęp z zewnątrz przez GlobalKey
class HomeScreenState extends State<HomeScreen> {
  List<Medicine> _medicines = [];
  FilterState _filterState = const FilterState();
  SortOption _sortOption = SortOption.nameAsc;
  String? _expandedMedicineId; // ID karty rozwiniętej jako akordeon
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltersSheetOpen = false;
  bool _isManagementSheetOpen = false;
  final FocusNode _searchFocusNode = FocusNode();

  // Help bottom sheet state
  bool _isHelpTooltipOpen = false;

  // Sort bottom sheet state
  bool _isSortSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Check for updates on init
    widget.updateService.addListener(_onUpdateChanged);
    widget.updateService.checkForUpdate();

    // Pokaż tooltip pomocy po dodaniu pierwszego leku
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_medicines.isNotEmpty &&
          !widget.storageService.helpTooltipShown &&
          mounted) {
        _showHelpBottomSheet();
      }
    });
  }

  // ==================== PUBLICZNE API (dla ApteczkaToolbar) ====================

  /// Czy są aktywne filtry
  bool get hasActiveFilters => _filterState.hasActiveFilters;

  /// Odświeża listę leków
  void refresh() => _loadMedicines();

  /// Aktywuje pole wyszukiwania
  void activateSearch() {
    _searchFocusNode.requestFocus();
  }

  /// Otwiera bottomSheet sortowania
  void showSortBottomSheet() => _showSortBottomSheet();

  /// Otwiera bottomSheet filtrów
  void showFilters() => _showFilters();

  /// Czyści wszystkie filtry
  void clearFilters() => _clearFilters();

  /// Otwiera bottomSheet zarządzania apteczką
  void showFilterManagement() => _showFilterManagement();

  void _onUpdateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    widget.updateService.removeListener(_onUpdateChanged);
    super.dispose();
  }

  void _loadMedicines() {
    setState(() {
      _medicines = widget.storageService.getMedicines();
      _isLoading = false;
    });
  }

  List<Medicine> get _filteredMedicines {
    final filtered = applyFilters(_medicines, _filterState);
    return _sortMedicines(filtered);
  }

  List<Medicine> _sortMedicines(List<Medicine> medicines) {
    final sorted = List<Medicine>.from(medicines);
    switch (_sortOption) {
      case SortOption.nameAsc:
        sorted.sort(
          (a, b) => (a.nazwa ?? '').toLowerCase().compareTo(
            (b.nazwa ?? '').toLowerCase(),
          ),
        );
      case SortOption.nameDesc:
        sorted.sort(
          (a, b) => (b.nazwa ?? '').toLowerCase().compareTo(
            (a.nazwa ?? '').toLowerCase(),
          ),
        );
      case SortOption.expiryAsc:
        sorted.sort((a, b) {
          final aDate = a.terminWaznosci ?? '9999-12-31';
          final bDate = b.terminWaznosci ?? '9999-12-31';
          return aDate.compareTo(bDate);
        });
      case SortOption.expiryDesc:
        sorted.sort((a, b) {
          final aDate = a.terminWaznosci ?? '0000-01-01';
          final bDate = b.terminWaznosci ?? '0000-01-01';
          return bDate.compareTo(aDate);
        });
      case SortOption.dateAddedAsc:
        sorted.sort((a, b) => a.dataDodania.compareTo(b.dataDodania));
      case SortOption.dateAddedDesc:
        sorted.sort((a, b) => b.dataDodania.compareTo(a.dataDodania));
    }
    return sorted;
  }

  List<String> get _allTags {
    final tags = <String>{};
    for (final m in _medicines) {
      // Normalizuj tagi przy zbieraniu (konwersja starych → nowe)
      tags.addAll(normalizeTags(m.tagi));
    }
    return tags.toList()..sort();
  }

  List<UserLabel> get _allLabels {
    return widget.storageService.getLabels();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Line 1: Logo + Title
            _buildHeaderLine1(theme, isDark),

            // Line 2: Search bar
            _buildSearchBar(theme, isDark),

            // Line 3: Counter | View | Sort | Filter
            _buildToolbar(theme, isDark),

            // Lista leków - responsywny grid dla szerokich ekranów
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMedicines.isEmpty
                  ? _EmptyState(
                      onDemoPressed: _addDemoMedicines,
                      onAddPressed: widget.onNavigateToAdd,
                      hasFilters: _filterState.hasActiveFilters,
                    )
                  : Stack(
                      children: [
                        // Główna lista - tryb akordeonowy
                        ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredMedicines.length,
                          itemBuilder: (context, index) {
                            final medicine = _filteredMedicines[index];
                            final swipeEnabled =
                                widget.storageService.swipeGesturesEnabled;
                            final isExpanded =
                                _expandedMedicineId == medicine.id;

                            final card = MedicineCard(
                              medicine: medicine,
                              labels: _allLabels,
                              storageService: widget.storageService,
                              isCompact: !isExpanded,
                              isDuplicate: hasDuplicates(medicine, _medicines),
                              onExpand: () {
                                setState(() {
                                  // Toggle - kliknięcie na rozwiniętą kartę zwija ją
                                  if (_expandedMedicineId == medicine.id) {
                                    _expandedMedicineId = null;
                                  } else {
                                    _expandedMedicineId = medicine.id;
                                  }
                                });
                              },
                              onEdit: () => _editMedicine(medicine),
                              onDelete: () =>
                                  _deleteMedicineWithConfirm(medicine),
                              onTagTap: (tag) => _filterByTag(tag),
                              onLabelTap: (labelId) => _filterByLabel(labelId),
                              onMedicineUpdated: _loadMedicines,
                            );

                            if (!swipeEnabled) {
                              return card;
                            }

                            return Dismissible(
                              key: Key(medicine.id),
                              direction: DismissDirection.horizontal,
                              // Swipe w prawo → notatki
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 32),
                                color: Colors.transparent,
                                child: Icon(
                                  LucideIcons.clipboardPenLine,
                                  size: 32,
                                  color: isDark
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              // Swipe w lewo → etykiety
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 32),
                                color: Colors.transparent,
                                child: Icon(
                                  LucideIcons.tags,
                                  size: 32,
                                  color: isDark
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  // Swipe w lewo → edycja etykiet
                                  _showLabelsSheet(medicine);
                                } else {
                                  // Swipe w prawo → edycja notatki
                                  _showEditNoteDialog(medicine);
                                }
                                return false; // Nie usuwaj karty
                              },
                              child: card,
                            );
                          },
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLine1(ThemeData theme, bool isDark) {
    final updateAvailable = widget.updateService.updateAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo (Vector Icon - no decoration, blends with background)
          // Red accent for DEV builds
          KartonClosedIcon(
            size: 48,
            isDark: isDark,
            accentColor: AppConfig.isInternal ? AppColors.expired : null,
          ),
          const SizedBox(width: 12),
          // Tytuł
          Text(
            AppConfig.isInternal ? 'Karton DEV' : 'Karton z lekami',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConfig.isInternal
                  ? AppColors.expired
                  : AppColors.primary,
            ),
          ),
          // Update badge
          if (updateAvailable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onNavigateToSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.download,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktualizacja',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          // Zarządzaj Apteczką - przycisk z ikoną i tekstem
          GestureDetector(
            onTap: _showFilterManagement,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: _isManagementSheetOpen
                  ? NeuDecoration.pressed(isDark: isDark, radius: 12)
                  : NeuDecoration.flat(isDark: isDark, radius: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.menu,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Zarządzaj',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: _searchFocusNode.hasFocus
            ? NeuDecoration.searchBarFocused(isDark: isDark)
            : NeuDecoration.searchBar(isDark: isDark),
        child: Row(
          children: [
            // Search icon
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                LucideIcons.search,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Szukaj leku...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filterState = _filterState.copyWith(searchQuery: value);
                  });
                },
                onSubmitted: (_) {
                  _searchFocusNode.unfocus();
                },
              ),
            ),
            // Clear button (when text is present)
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filterState = _filterState.copyWith(searchQuery: '');
                  });
                },
              ),
            // Submit check button - visible only when focused
            if (_searchFocusNode.hasFocus)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    _searchFocusNode.unfocus();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: NeuDecoration.flatSmall(
                      isDark: isDark,
                      radius: 20,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Licznik - neumorficzny kontener
          NeuStaticContainer(
            isSmall: true,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.pillBottle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_filteredMedicines.length} ${_getPolishPlural(_filteredMedicines.length)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Przycisk pomocy - żarówka z efektem pressed
          GestureDetector(
            onTap: _toggleHelpTooltip,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 40,
              height: 40,
              decoration: _isHelpTooltipOpen
                  ? NeuDecoration.pressedSmall(isDark: isDark, radius: 12)
                  : NeuDecoration.flatSmall(isDark: isDark, radius: 12),
              child: Center(
                child: Icon(
                  LucideIcons.lightbulb,
                  size: 20,
                  color: _isHelpTooltipOpen
                      ? Colors.grey
                      : Colors.amber.shade600,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Sortowanie - bottomSheet
          NeuIconButton(
            icon: LucideIcons.arrowDownUp,
            onPressed: _showSortBottomSheet,
            isActive: _isSortSheetOpen,
            tooltip: 'Sortowanie',
          ),
          const SizedBox(width: 8),
          // Filtry
          NeuIconButtonBadge(
            count: _filterState.activeFilterCount,
            showBadge: _filterState.hasActiveFilters,
            button: NeuIconButton(
              icon: LucideIcons.funnel,
              onPressed: _showFilters,
              isActive: _isFiltersSheetOpen,
            ),
          ),
          const SizedBox(width: 8),
          // Wyczyść filtry
          NeuIconButton(
            icon: LucideIcons.funnelX,
            onPressed: _filterState.hasActiveFilters ? _clearFilters : null,
            tooltip: 'Wyczyść filtry',
            mode: _filterState.hasActiveFilters
                ? NeuIconButtonMode.visible
                : NeuIconButtonMode.iconOnly,
            iconColor: _filterState.hasActiveFilters ? AppColors.expired : null,
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    setState(() => _isFiltersSheetOpen = true);
    final labels = widget.storageService.getLabels();
    showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => FiltersSheet(
            initialState: _filterState,
            availableTags: _allTags,
            availableLabels: labels,
            onApply: (newState) {
              setState(() {
                _filterState = newState;
              });
            },
          ),
        )
        .then((_) {
          _loadMedicines();
        })
        .whenComplete(() {
          if (mounted) setState(() => _isFiltersSheetOpen = false);
        });
  }

  void _clearFilters() {
    setState(() {
      _filterState = const FilterState();
      _searchController.clear();
    });
  }

  // ==================== HELP BOTTOM SHEET ====================

  void _toggleHelpTooltip() {
    if (_isHelpTooltipOpen) {
      Navigator.of(context).pop();
    } else {
      _showHelpBottomSheet();
    }
  }

  void _showHelpBottomSheet() {
    // Oznacz jako pokazany
    widget.storageService.helpTooltipShown = true;

    setState(() => _isHelpTooltipOpen = true);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _HelpBottomSheetContent(isDark: isDark, theme: theme),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isHelpTooltipOpen = false);
      }
    });
  }

  // ==================== SORT BOTTOM SHEET ====================

  void _showSortBottomSheet() {
    setState(() => _isSortSheetOpen = true);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    AppBottomSheet.show(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: BottomSheetConstants.contentPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  LucideIcons.arrowDownUp,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sortuj',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sort options
            ...SortOption.values.map((option) {
              final isSelected = option == _sortOption;
              return InkWell(
                onTap: () {
                  setState(() => _sortOption = option);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Tekst po lewej - bez stylu neumorficznego
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Ikona po prawej - w kontenerze .flat/.pressed
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: isSelected
                            ? NeuDecoration.pressedSmall(isDark: isDark, radius: 10)
                            : NeuDecoration.flatSmall(isDark: isDark, radius: 10),
                        child: Icon(
                          option.icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _isSortSheetOpen = false);
    });
  }

  void _showFilterManagement() {
    setState(() => _isManagementSheetOpen = true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    AppBottomSheet.show(
      context: context,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: BottomSheetConstants.contentPadding,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(LucideIcons.menu, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Zarządzaj apteczką',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Zarządzaj etykietami
              ListTile(
                leading: Icon(
                  LucideIcons.tags,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Etykiety'),
                subtitle: const Text('Dodawaj, edytuj i usuwaj swoje etykiety'),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 8,
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLabelManagement();
                },
              ),

              const Divider(height: 24),

              // Zarządzaj tagami
              ListTile(
                leading: Icon(
                  LucideIcons.hash,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Tagi'),
                subtitle: const Text(
                  'Dodawaj, edytuj i usuwaj niestandardowe tagi z apteczki',
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 8,
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTagManagement();
                },
              ),

              const Divider(height: 24),

              // Skopiuj listę leków
              ListTile(
                leading: Icon(
                  LucideIcons.list,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Skopiuj listę leków'),
                subtitle: const Text(
                  'Zwraca liste leków oddzielonych przecinkami',
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 8,
                  ),
                  child: Icon(
                    LucideIcons.copy,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyMedicineList();
                },
              ),

              const Divider(height: 24),

              // Tabela do PDF
              ListTile(
                leading: Icon(
                  LucideIcons.fileSpreadsheet,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Tabela leków do PDF'),
                subtitle: const Text(
                  'Podgląd, udostępnianie i drukowanie tabeli',
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 8,
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _previewPdfExport();
                },
              ),

              const Divider(height: 24),

              // Wyczyść apteczkę - Strefa niebezpieczna
              ListTile(
                leading: Icon(LucideIcons.paintbrush, color: AppColors.expired),
                title: Text(
                  'Wyczyść apteczkę',
                  style: TextStyle(color: AppColors.expired),
                ),
                subtitle: Text(
                  'Nieodwracalna akcja',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.expired.withAlpha(180),
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteAllMedicinesDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: NeuDecoration.flatSmall(
                      isDark: isDark,
                      radius: 8,
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      color: AppColors.expired,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const Divider(height: 24),

              const SizedBox(height: 24),

              // Disclaimer
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.expiringSoon.withAlpha(30)
                      : AppColors.expiringSoon.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.expiringSoon.withAlpha(100),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.shieldAlert,
                      color: AppColors.expiringSoon,
                    ),
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
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
    ).whenComplete(() {
      if (mounted) setState(() => _isManagementSheetOpen = false);
    });
  }

  /// Kopiuje listę nazw leków do schowka
  Future<void> _copyMedicineList() async {
    final medicines = widget.storageService.getMedicines();
    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak leków do skopiowania'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final names = medicines.map((m) => m.nazwa ?? 'Bez nazwy').toList();
    final text = names.join(', ');
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skopiowano ${medicines.length} leków do schowka'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Generuje PDF i otwiera ekran podglądu
  Future<void> _previewPdfExport() async {
    final medicines = _filteredMedicines;
    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak leków do eksportu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      // Pokaż loader podczas generowania
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final service = PdfExportService();
      final file = await service.generateAndSavePdf(medicines);

      if (mounted) {
        Navigator.pop(context); // Zamknij loader

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PdfViewerScreen(file: file, title: 'Podgląd wydruku'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Zamknij loader w razie błędu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd generowania PDF: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Dialog potwierdzenia usunięcia wszystkich leków
  Future<void> _showDeleteAllMedicinesDialog() async {
    final medicines = widget.storageService.getMedicines();
    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apteczka jest już pusta'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
      final allMedicines = widget.storageService.getMedicines();
      for (final m in allMedicines) {
        await widget.storageService.deleteMedicine(m.id);
      }
      _loadMedicines();

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

  void _showLabelManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LabelManagementSheet(
        storageService: widget.storageService,
        onChanged: () => _loadMedicines(),
      ),
    ).then((_) {
      _loadMedicines();
      // Powrót do głównego menu po zamknięciu (gest lub przycisk wstecz)
      _showFilterManagement();
    });
  }

  void _showTagManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TagManagementSheet(
        storageService: widget.storageService,
        onChanged: () => _loadMedicines(),
      ),
    ).then((_) {
      _loadMedicines();
      // Powrót do głównego menu po zamknięciu (gest lub przycisk wstecz)
      _showFilterManagement();
    });
  }

  Future<bool> _confirmDelete(Medicine medicine) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usuń lek?'),
            content: Text('Czy na pewno chcesz usunąć "${medicine.nazwa}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.expired,
                ),
                child: const Text('Usuń'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _deleteMedicine(Medicine medicine) async {
    await widget.storageService.deleteMedicine(medicine.id);
    _loadMedicines();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usunięto: ${medicine.nazwa}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Usuwa lek z potwierdzeniem
  void _deleteMedicineWithConfirm(Medicine medicine) async {
    if (await _confirmDelete(medicine)) {
      _deleteMedicine(medicine);
    }
  }

  /// Otwiera ekran edycji leku
  void _editMedicine(Medicine medicine) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicineScreen(
          storageService: widget.storageService,
          medicine: medicine,
        ),
      ),
    );
    if (result == true) {
      _loadMedicines();
    }
  }

  /// Filtruje listę po tagu
  void _filterByTag(String tag) {
    setState(() {
      final newTags = Set<String>.from(_filterState.selectedTags);
      newTags.add(tag);
      _filterState = _filterState.copyWith(selectedTags: newTags);
      _expandedMedicineId = null; // Zwija kartę po filtracji
    });
  }

  /// Filtruje listę po etykiecie
  void _filterByLabel(String labelId) {
    setState(() {
      final newLabels = Set<String>.from(_filterState.selectedLabels);
      newLabels.add(labelId);
      _filterState = _filterState.copyWith(selectedLabels: newLabels);
      _expandedMedicineId = null; // Zwija kartę po filtracji
    });
  }

  String _getPolishPlural(int count) {
    if (count == 1) return 'lek';
    if (count >= 2 && count <= 4) return 'leki';
    if (count >= 12 && count <= 14) return 'leków';
    final lastDigit = count % 10;
    if (lastDigit >= 2 && lastDigit <= 4) return 'leki';
    return 'leków';
  }

  void _showMedicineDetails(Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MedicineDetailSheet(
        medicine: medicine,
        storageService: widget.storageService,
        onEdit: () async {
          Navigator.pop(context);
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EditMedicineScreen(
                storageService: widget.storageService,
                medicine: medicine,
              ),
            ),
          );
          if (result == true) {
            _loadMedicines();
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          if (await _confirmDelete(medicine)) {
            _deleteMedicine(medicine);
          }
        },
        onTagTap: (tag) {
          Navigator.pop(context);
          setState(() {
            final newTags = Set<String>.from(_filterState.selectedTags);
            newTags.add(tag);
            _filterState = _filterState.copyWith(selectedTags: newTags);
          });
        },
        onLabelTap: (labelId) {
          Navigator.pop(context);
          setState(() {
            final newLabels = Set<String>.from(_filterState.selectedLabels);
            newLabels.add(labelId);
            _filterState = _filterState.copyWith(selectedLabels: newLabels);
          });
        },
      ),
    ).then((_) => _loadMedicines()); // Refresh after detail sheet closes
  }

  /// Pokazuje bottom sheet z selectorem etykiet (swipe w lewo)
  void _showLabelsSheet(Medicine medicine) {
    // Lokalna kopia etykiet do reaktywnego UI
    List<String> currentLabels = List<String>.from(medicine.labels);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(BottomSheetConstants.radius),
                ),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.8,
                expand: false,
                builder: (context, scrollController) => Column(
                  children: [
                    const BottomSheetDragHandle(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: BottomSheetConstants.contentPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.tags,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Etykiety: ${medicine.nazwa ?? "Lek"}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // LabelSelector z reaktywnym stanem
                            LabelSelector(
                              storageService: widget.storageService,
                              selectedLabelIds: currentLabels,
                              isOpen: true,
                              onToggle: () {},
                              onLabelTap: (_) {},
                              onChanged: (newLabelIds) async {
                                // Aktualizuj lokalny stan (reaktywny UI)
                                setSheetState(() {
                                  currentLabels = newLabelIds;
                                });
                                // Zapisz do storage
                                await widget.storageService.updateMedicineLabels(
                                  medicine.id,
                                  newLabelIds,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _loadMedicines());
  }

  /// Pokazuje dialog edycji notatki (swipe w prawo)
  void _showEditNoteDialog(Medicine medicine) async {
    final controller = TextEditingController(text: medicine.notatka ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notatka: ${medicine.nazwa ?? "Lek"}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Wpisz notatkę...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null) {
      await widget.storageService.updateMedicineNote(medicine.id, result);
      _loadMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notatka zapisana'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addDemoMedicines() async {
    final demoMedicines = [
      Medicine(
        id: 'demo-1',
        nazwa: 'Paracetamol',
        opis: 'Lek przeciwbólowy i przeciwgorączkowy',
        wskazania: ['Ból głowy', 'Gorączka', 'Ból mięśni'],
        tagi: ['ból', 'gorączka', 'przeciwbólowy'],
        dataDodania: DateTime.now().toIso8601String(),
        terminWaznosci: DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String()
            .split('T')[0],
      ),
      Medicine(
        id: 'demo-2',
        nazwa: 'Ibuprofen',
        opis: 'Lek przeciwzapalny, przeciwbólowy',
        wskazania: ['Ból głowy', 'Stany zapalne', 'Ból zębów'],
        tagi: ['ból', 'przeciwzapalny', 'lek OTC'],
        dataDodania: DateTime.now().toIso8601String(),
        terminWaznosci: DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String()
            .split('T')[0],
      ),
      Medicine(
        id: 'demo-3',
        nazwa: 'Witamina C',
        opis: 'Suplement diety wzmacniający odporność',
        wskazania: ['Wzmocnienie odporności', 'Przeziębienie'],
        tagi: ['suplement', 'przeziębienie'],
        dataDodania: DateTime.now().toIso8601String(),
        terminWaznosci: DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String()
            .split('T')[0],
      ),
    ];

    for (final medicine in demoMedicines) {
      await widget.storageService.saveMedicine(medicine);
    }

    _loadMedicines();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dodano przykładowe leki!')));
    }
  }
}

/// Stan pusty - brak leków
class _EmptyState extends StatefulWidget {
  final VoidCallback? onAddPressed;
  final VoidCallback onDemoPressed;
  final bool hasFilters;

  const _EmptyState({
    required this.onDemoPressed,
    this.onAddPressed,
    this.hasFilters = false,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  // Niezależne toggle dla każdej ikony
  bool _showLeftTitle = false; // "Nie kop w pudle."
  bool _showRightTitle = false; // "Sprawdź w telefonie."

  void _onIconTap(int index) {
    setState(() {
      if (index == 0) {
        _showLeftTitle = !_showLeftTitle;
      } else {
        _showRightTitle = !_showRightTitle;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Widok z filtrami - prosty komunikat
    if (widget.hasFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.listX,
                size: 80,
                color: AppColors.primary.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                'Brak wyników',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Zmień filtry aby zobaczyć leki.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Widok pustej apteczki - nowy design
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Slogan - dwa niezależne tytuły, stała wysokość
            SizedBox(
              height: 80, // Stała wysokość - ikony nie przesuwają się
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Nie kop w pudle." - z lewej
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showLeftTitle ? 1.0 : 0.0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nie kop w pudle.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // "Sprawdź w telefonie." - z prawej
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showRightTitle ? 1.0 : 0.0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Sprawdź w telefonie.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ilustracja transformacji (bałagan → porządek)
            TransformationIllustration(
              iconSize: 72,
              isDark: isDark,
              onIconTap: _onIconTap,
            ),
            const SizedBox(height: 32),

            // Podtytuł
            Text(
              'Wrzuć leki do kartonu i zapanuj nad domową apteczką.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Dwa przyciski CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Przycisk "Dodaj leki"
                NeuButton(
                  label: 'Dodaj leki',
                  icon: LucideIcons.plus,
                  onPressed: widget.onAddPressed,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                const SizedBox(width: 16),
                // Przycisk "Przetestuj demo"
                NeuButton.primary(
                  label: 'Przetestuj',
                  icon: LucideIcons.sparkles,
                  onPressed: widget.onDemoPressed,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet zarządzania etykietami
class _LabelManagementSheet extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onChanged;

  const _LabelManagementSheet({
    required this.storageService,
    required this.onChanged,
  });

  @override
  State<_LabelManagementSheet> createState() => _LabelManagementSheetState();
}

class _LabelManagementSheetState extends State<_LabelManagementSheet> {
  late List<UserLabel> _labels;
  final Set<String> _selectedLabelIds = {};

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  void _loadLabels() {
    setState(() {
      _labels = widget.storageService.getLabels();
      // Usuń zaznaczenia dla usuniętych etykiet
      _selectedLabelIds.removeWhere((id) => !_labels.any((l) => l.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BottomSheetConstants.radius),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const BottomSheetDragHandle(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BottomSheetConstants.contentPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header z przyciskiem wstecz, tytułem i przyciskiem dodaj
                    Row(
                      children: [
                        // Przycisk wstecz
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: NeuDecoration.flatSmall(
                              isDark: isDark,
                              radius: 8,
                            ),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.tags, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Zarządzaj etykietami',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Przycisk dodaj etykietę
                        GestureDetector(
                          onTap: _createLabel,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: NeuDecoration.flatSmall(
                              isDark: isDark,
                              radius: 8,
                            ),
                            child: Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Przeciągnij etykietę aby zmienić kolejność. Zaznacz aby usunąć wiele.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _labels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.tag,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              128,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Brak etykiet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dodaj etykiety w szczegółach leku',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      itemCount: _labels.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final double elevation = Tween<double>(
                              begin: 0,
                              end: 6,
                            ).evaluate(animation);
                            return Material(
                              elevation: elevation,
                              borderRadius: BorderRadius.circular(8),
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final label = _labels[index];
                        final colorInfo = labelColors[label.color];
                        final color = colorInfo != null
                            ? Color(colorInfo.colorValue)
                            : Colors.grey;
                        final isSelected = _selectedLabelIds.contains(label.id);
                        return Container(
                          key: ValueKey(label.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: NeuDecoration.flatSmall(
                            isDark: isDark,
                            radius: 8,
                          ),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Checkbox dla multi-select
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedLabelIds.add(label.id);
                                      } else {
                                        _selectedLabelIds.remove(label.id);
                                      }
                                    });
                                  },
                                  activeColor: theme.colorScheme.primary,
                                ),
                                // Drag handle
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    LucideIcons.gripVertical,
                                    size: 20,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Color dot
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              label.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              colorInfo?.name ?? 'Szary',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.pen,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () => _editLabel(label),
                                  tooltip: 'Edytuj',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteLabel(label),
                                  tooltip: 'Usuń',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ),
                    // Przycisk "Usuń zaznaczone" (widoczny gdy >= 1 zaznaczona)
                    if (_selectedLabelIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _deleteSelectedLabels,
                          icon: const Icon(LucideIcons.trash, size: 18),
                          label: Text('Usuń zaznaczone (${_selectedLabelIds.length})'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _labels.removeAt(oldIndex);
      _labels.insert(newIndex, item);
    });
    // Zapisz nową kolejność
    widget.storageService.reorderLabels(_labels);
    widget.onChanged();
  }

  void _editLabel(UserLabel label) {
    final nameController = TextEditingController(text: label.name);
    LabelColor selectedColor = label.color;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edytuj etykietę'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Kolor:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LabelColor.values.map((c) {
                  final info = labelColors[c]!;
                  final isSelected = c == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(info.colorValue),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(info.colorValue),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;

                final updated = label.copyWith(
                  name: newName,
                  color: selectedColor,
                );
                widget.storageService.updateLabel(updated);
                widget.onChanged();
                _loadLabels();
                Navigator.pop(ctx);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLabel(UserLabel label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń etykietę?'),
        content: Text(
          'Czy na pewno chcesz usunąć etykietę "${label.name}"? Zostanie usunięta ze wszystkich leków.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.storageService.deleteLabel(label.id);
              widget.onChanged();
              _loadLabels();
              Navigator.pop(ctx);
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _createLabel() {
    final nameController = TextEditingController();
    LabelColor selectedColor = LabelColor.green;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nowa etykieta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text('Kolor:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LabelColor.values.map((c) {
                  final info = labelColors[c]!;
                  final isSelected = c == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(info.colorValue),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(info.colorValue),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newLabel = UserLabel(
                  id: Uuid().v4(),
                  name: name,
                  color: selectedColor,
                );
                widget.storageService.saveLabel(newLabel);
                widget.onChanged();
                _loadLabels();
                Navigator.pop(ctx);
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedLabels() {
    if (_selectedLabelIds.isEmpty) return;

    final count = _selectedLabelIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń zaznaczone etykiety?'),
        content: Text(
          'Czy na pewno chcesz usunąć $count ${count == 1 ? 'etykietę' : 'etykiet'}? Zostaną usunięte ze wszystkich leków.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              for (final id in _selectedLabelIds) {
                widget.storageService.deleteLabel(id);
              }
              widget.onChanged();
              _selectedLabelIds.clear();
              _loadLabels();
              Navigator.pop(ctx);
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }
}

/// Sheet zarządzania tagami
class _TagManagementSheet extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onChanged;

  const _TagManagementSheet({
    required this.storageService,
    required this.onChanged,
  });

  @override
  State<_TagManagementSheet> createState() => _TagManagementSheetState();
}

class _TagManagementSheetState extends State<_TagManagementSheet> {
  late Set<String> _customTags;

  // Wszystkie tagi systemowe (z kategorii)
  static final Set<String> _systemTags = {
    ...tagCategories.values.expand((e) => e),
    ...tagsObjawIDzialanie.values.expand((e) => e),
  };

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    final medicines = widget.storageService.getMedicines();
    final customTags = <String>{};
    for (final m in medicines) {
      // Filtruj tylko custom tagi (spoza kategorii systemowych)
      customTags.addAll(m.tagi.where((t) => !_systemTags.contains(t)));
    }
    setState(() {
      _customTags = customTags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sortedTags = _customTags.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BottomSheetConstants.radius),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const BottomSheetDragHandle(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BottomSheetConstants.contentPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header z przyciskiem wstecz
                    Row(
                      children: [
                        // Przycisk wstecz
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: NeuDecoration.flatSmall(
                              isDark: isDark,
                              radius: 8,
                            ),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.hash, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Moje tagi',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Edytuj lub usuń własne tagi z apteczki.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: sortedTags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.hash,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              128,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Brak własnych tagów',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tagi systemowe są zarządzane przez aplikację',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: sortedTags.length,
                      itemBuilder: (context, index) {
                        final tag = sortedTags[index];
                        final medicineCount = _getMedicineCountForTag(tag);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: NeuDecoration.flatSmall(
                            isDark: isDark,
                            radius: 8,
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.tag,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              tag,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '$medicineCount ${medicineCount == 1 ? 'lek' : 'leków'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.pen,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () => _editTag(tag),
                                  tooltip: 'Edytuj',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteTag(tag),
                                  tooltip: 'Usuń',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMedicineCountForTag(String tag) {
    return widget.storageService
        .getMedicines()
        .where((m) => m.tagi.contains(tag))
        .length;
  }

  void _editTag(String oldTag) {
    final controller = TextEditingController(text: oldTag);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edytuj tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nazwa tagu',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final newTag = controller.text.trim();
              if (newTag.isEmpty || newTag == oldTag) {
                Navigator.pop(ctx);
                return;
              }

              // Update all medicines with this tag
              final medicines = widget.storageService.getMedicines();
              for (final med in medicines) {
                if (med.tagi.contains(oldTag)) {
                  final newTags = med.tagi
                      .map((t) => t == oldTag ? newTag : t)
                      .toList();
                  widget.storageService.saveMedicine(
                    med.copyWith(tagi: newTags),
                  );
                }
              }

              widget.onChanged();
              _loadTags();
              Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _deleteTag(String tag) {
    final count = _getMedicineCountForTag(tag);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń tag?'),
        content: Text(
          'Czy na pewno chcesz usunąć tag "$tag"? Zostanie usunięty z $count ${count == 1 ? 'leku' : 'leków'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Remove tag from all medicines
              final medicines = widget.storageService.getMedicines();
              for (final med in medicines) {
                if (med.tagi.contains(tag)) {
                  final newTags = med.tagi.where((t) => t != tag).toList();
                  widget.storageService.saveMedicine(
                    med.copyWith(tagi: newTags),
                  );
                }
              }

              widget.onChanged();
              _loadTags();
              Navigator.pop(ctx);
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }
}

// ==================== HELP BOTTOM SHEET CONTENT ====================

class _HelpBottomSheetContent extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _HelpBottomSheetContent({required this.isDark, required this.theme});

  @override
  State<_HelpBottomSheetContent> createState() =>
      _HelpBottomSheetContentState();
}

class _HelpBottomSheetContentState extends State<_HelpBottomSheetContent> {
  bool _isFeaturesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BottomSheetConstants.radius),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const BottomSheetDragHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: BottomSheetConstants.contentPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(LucideIcons.lightbulb,
                            color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Podpowiedzi',
                          style: widget.theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // === Gesty na karcie leku ===
                    _buildSection(
                      icon: LucideIcons.hand,
                      title: 'Gesty na karcie leku',
                      items: [
                        'Przytrzymanie → pokaż szczegóły',
                        'Dotknięcie → rozwija kartę w widoku listy',
                        'Włącz w ustawieniach gesty przeciągania dla szybkiej edycji etykiet i notatek',
                      ],
                    ),
                    const SizedBox(height: 24),
                    // === Ciekawe funkcje (rozwijane) ===
                    GestureDetector(
                      onTap: () => setState(
                          () => _isFeaturesExpanded = !_isFeaturesExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: NeuDecoration.flat(
                          isDark: widget.isDark,
                          radius: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              color: widget.theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ciekawe funkcje',
                                style:
                                    widget.theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: _isFeaturesExpanded ? 0.5 : 0,
                              child: Icon(
                                LucideIcons.chevronDown,
                                color: widget.theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Rozwinięta zawartość
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _isFeaturesExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            _buildFeatureItem(
                              icon: LucideIcons.calculator,
                              title: 'Kalkulator zapasu leku',
                              description: 'Sprawdź do kiedy starczy ci leków',
                              path: 'Szczegóły leku → Termin ważności',
                            ),
                            const Divider(height: 24),
                            _buildFeatureItem(
                              icon: LucideIcons.copy,
                              title: 'Wykrywanie duplikatów',
                              description:
                                  'Specjalna ikona pokaże się na karcie leku.\nMożesz też przefiltrować listę po duplikatach.',
                              path: 'Filtry → Termin ważności',
                            ),
                            const Divider(height: 24),
                            _buildFeatureItem(
                              icon: LucideIcons.boxes,
                              title: 'Eksportuj listy',
                              description:
                                  'Wyeksportuj do PDF w formie tabelki gotowej do wydruku.\nSkopiuj do schowka wypisane po przecinku.',
                              path: 'Zarządzaj apteczką',
                            ),
                            const Divider(height: 24),
                            _buildFeatureItem(
                              icon: LucideIcons.search,
                              title: 'Szukaj w ulotce',
                              description: 'Wyszukaj i przypnij ulotkę leku',
                              path: 'Karta leku → Ulotka → Podepnij ulotkę',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: widget.theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: widget.theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 8),
            child: Text(
              '• $item',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required String path,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: widget.theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: widget.theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.cornerDownRight,
                      size: 14,
                      color: widget.theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        path,
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
