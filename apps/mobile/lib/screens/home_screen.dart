import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/theme_provider.dart';
import '../widgets/medicine_card.dart';
import '../widgets/filters_sheet.dart';
import '../theme/app_theme.dart';
import 'edit_medicine_screen.dart';
import 'medicine_detail_sheet.dart';

/// Opcje sortowania
enum SortOption {
  nameAsc('Nazwa A-Z', LucideIcons.arrowUpAZ),
  nameDesc('Nazwa Z-A', LucideIcons.arrowDownAZ),
  expiryAsc('Termin ↑', LucideIcons.calendarClock),
  expiryDesc('Termin ↓', LucideIcons.calendarClock),
  dateAddedAsc('Data dodania ↑', LucideIcons.calendarPlus),
  dateAddedDesc('Data dodania ↓', LucideIcons.calendarPlus);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

/// Widok listy
enum ViewMode { list, full }

/// Główny ekran - lista leków (Apteczka)
class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ThemeProvider themeProvider;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.themeProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> _medicines = [];
  FilterState _filterState = const FilterState();
  SortOption _sortOption = SortOption.nameAsc;
  ViewMode _viewMode = ViewMode.full;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        sorted.sort((a, b) => (a.nazwa ?? '').compareTo(b.nazwa ?? ''));
      case SortOption.nameDesc:
        sorted.sort((a, b) => (b.nazwa ?? '').compareTo(a.nazwa ?? ''));
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
      tags.addAll(m.tagi);
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
            _buildHeaderLine1(theme),

            // Line 2: Search bar
            _buildSearchBar(theme, isDark),

            // Line 3: Counter | View | Sort | Filter
            _buildToolbar(theme, isDark),

            // Lista leków
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMedicines.isEmpty
                  ? _EmptyState(
                      onAddPressed: _addDemoMedicines,
                      hasFilters: _filterState.hasActiveFilters,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = _filteredMedicines[index];
                        return Dismissible(
                          key: Key(medicine.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.expired,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              LucideIcons.trash,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) => _confirmDelete(medicine),
                          onDismissed: (_) => _deleteMedicine(medicine),
                          child: MedicineCard(
                            medicine: medicine,
                            labels: _allLabels,
                            isCompact: _viewMode == ViewMode.list,
                            onTap: () => _showMedicineDetails(medicine),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLine1(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/favicon.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.pill, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tytuł
          Text(
            'Pudełko na leki',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: NeuDecoration.concave(isDark: isDark, radius: 12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Szukaj leku...',
            prefixIcon: const Icon(LucideIcons.packageSearch),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filterState = _filterState.copyWith(searchQuery: '');
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _filterState = _filterState.copyWith(searchQuery: value);
            });
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Licznik
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 8),
            child: Text(
              '${_filteredMedicines.length} ${_getPolishPlural(_filteredMedicines.length)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // Widok toggle
          _buildViewToggle(theme, isDark),
          const SizedBox(width: 8),
          // Sortowanie popup
          _buildSortButton(theme, isDark),
          const SizedBox(width: 8),
          // Filtry
          Badge(
            isLabelVisible: _filterState.hasActiveFilters,
            label: Text('${_filterState.activeFilterCount}'),
            child: Container(
              decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 8),
              child: IconButton(
                icon: const Icon(LucideIcons.filter, size: 20),
                onPressed: _showFilters,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 8),
      child: IconButton(
        icon: Icon(
          _viewMode == ViewMode.full
              ? LucideIcons.layoutGrid
              : LucideIcons.list,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _viewMode = _viewMode == ViewMode.full
                ? ViewMode.list
                : ViewMode.full;
          });
        },
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        tooltip: _viewMode == ViewMode.full ? 'Widok listy' : 'Pełny widok',
      ),
    );
  }

  Widget _buildSortButton(ThemeData theme, bool isDark) {
    return Container(
      decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 8),
      child: PopupMenuButton<SortOption>(
        icon: const Icon(LucideIcons.arrowDownUp, size: 20),
        tooltip: 'Sortowanie',
        onSelected: (option) {
          setState(() {
            _sortOption = option;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => SortOption.values.map((option) {
          final isSelected = option == _sortOption;
          return PopupMenuItem<SortOption>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(LucideIcons.check, size: 16, color: AppColors.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFilters() {
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
    ).then((_) => _loadMedicines()); // Refresh after filter sheet closes
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
      ),
    ).then((_) => _loadMedicines()); // Refresh after detail sheet closes
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
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;
  final bool hasFilters;

  const _EmptyState({required this.onAddPressed, this.hasFilters = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/apteczka.png',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => Icon(
                hasFilters ? LucideIcons.filterX : LucideIcons.pill,
                size: 80,
                color: AppColors.primary.withAlpha(128),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'Brak wyników' : 'Twoja apteczka jest pusta',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Zmień filtry aby zobaczyć leki.'
                  : 'Dodaj leki aby śledzić terminy ważności i szybko znajdować potrzebne preparaty.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!hasFilters)
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Dodaj przykładowe leki'),
              ),
          ],
        ),
      ),
    );
  }
}
