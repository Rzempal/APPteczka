import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../widgets/medicine_card.dart';
import '../widgets/filters_sheet.dart';
import 'edit_medicine_screen.dart';

/// Opcje sortowania
enum SortOption {
  nameAsc('Nazwa A-Z', Icons.sort_by_alpha),
  nameDesc('Nazwa Z-A', Icons.sort_by_alpha),
  expiryAsc('Termin ↑', Icons.arrow_upward),
  expiryDesc('Termin ↓', Icons.arrow_downward);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

/// Główny ekran - lista leków (Apteczka)
class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> _medicines = [];
  FilterState _filterState = const FilterState();
  SortOption _sortOption = SortOption.nameAsc;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💊 Pudełko na leki'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Sortowanie
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sortuj',
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (context) => SortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 20,
                      color: _sortOption == option
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: _sortOption == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          // Filtr badge
          Badge(
            isLabelVisible: _filterState.hasActiveFilters,
            label: Text('${_filterState.activeFilterCount}'),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtry',
              onPressed: _showFilters,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pasek wyszukiwania
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj leku...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filterState = _filterState.copyWith(
                              searchQuery: '',
                            );
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(searchQuery: value);
                });
              },
            ),
          ),

          // Licznik leków + aktywne filtry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredMedicines.length} ${_getPolishPlural(_filteredMedicines.length)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_filterState.hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Wyczyść filtry'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

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
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      return Dismissible(
                        key: Key(medicine.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: theme.colorScheme.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmDelete(medicine),
                        onDismissed: (_) => _deleteMedicine(medicine),
                        child: MedicineCard(
                          medicine: medicine,
                          onTap: () => _showMedicineDetails(medicine),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FiltersSheet(
        initialState: _filterState,
        availableTags: _allTags,
        onApply: (newState) {
          setState(() {
            _filterState = newState;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filterState = const FilterState();
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
                  backgroundColor: Theme.of(context).colorScheme.error,
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nazwa + przyciski akcji
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.nazwa ?? 'Nieznany lek',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Edytuj',
                    onPressed: () async {
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
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Usuń',
                    onPressed: () async {
                      Navigator.pop(context);
                      if (await _confirmDelete(medicine)) {
                        _deleteMedicine(medicine);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Opis
              Text(medicine.opis, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),

              // Wskazania
              if (medicine.wskazania.isNotEmpty) ...[
                Text(
                  'Wskazania:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...medicine.wskazania.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(w)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tagi
              if (medicine.tagi.isNotEmpty) ...[
                Text(
                  'Tagi:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: medicine.tagi.map((tag) {
                    final isFiltered = _filterState.selectedTags.contains(tag);
                    return ActionChip(
                      label: Text(tag),
                      avatar: isFiltered
                          ? const Icon(Icons.check, size: 16)
                          : null,
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          final newTags = Set<String>.from(
                            _filterState.selectedTags,
                          );
                          if (isFiltered) {
                            newTags.remove(tag);
                          } else {
                            newTags.add(tag);
                          }
                          _filterState = _filterState.copyWith(
                            selectedTags: newTags,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.medication_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'Brak wyników' : 'Twoja apteczka jest pusta',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Zmień filtry aby zobaczyć leki.'
                  : 'Dodaj leki aby śledzić terminy ważności i szybko znajdować potrzebne preparaty.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!hasFilters)
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj przykładowe leki'),
              ),
          ],
        ),
      ),
    );
  }
}
