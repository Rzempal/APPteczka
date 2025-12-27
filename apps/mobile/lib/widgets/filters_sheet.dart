import 'package:flutter/material.dart';
import '../models/medicine.dart';

/// Typy filtrów terminu ważności
enum ExpiryFilter {
  all('Wszystkie', Icons.all_inclusive),
  expired('Przeterminowane', Icons.error),
  expiringSoon('Kończą się', Icons.warning),
  valid('Ważne', Icons.check_circle);

  final String label;
  final IconData icon;
  const ExpiryFilter(this.label, this.icon);
}

/// Stan filtrów
class FilterState {
  final Set<String> selectedTags;
  final ExpiryFilter expiryFilter;
  final String searchQuery;

  const FilterState({
    this.selectedTags = const {},
    this.expiryFilter = ExpiryFilter.all,
    this.searchQuery = '',
  });

  FilterState copyWith({
    Set<String>? selectedTags,
    ExpiryFilter? expiryFilter,
    String? searchQuery,
  }) {
    return FilterState(
      selectedTags: selectedTags ?? this.selectedTags,
      expiryFilter: expiryFilter ?? this.expiryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      selectedTags.isNotEmpty || expiryFilter != ExpiryFilter.all;

  int get activeFilterCount =>
      selectedTags.length + (expiryFilter != ExpiryFilter.all ? 1 : 0);
}

/// Panel filtrów jako bottom sheet
class FiltersSheet extends StatefulWidget {
  final FilterState initialState;
  final List<String> availableTags;
  final ValueChanged<FilterState> onApply;

  const FiltersSheet({
    super.key,
    required this.initialState,
    required this.availableTags,
    required this.onApply,
  });

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late Set<String> _selectedTags;
  late ExpiryFilter _expiryFilter;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.initialState.selectedTags);
    _expiryFilter = widget.initialState.expiryFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filtry',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: _clearAll, child: const Text('Wyczyść')),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Termin ważności
                Text(
                  'Termin ważności',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpiryFilter.values.map((filter) {
                    final selected = _expiryFilter == filter;
                    return FilterChip(
                      selected: selected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter.icon,
                            size: 16,
                            color: selected
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(filter.label),
                        ],
                      ),
                      onSelected: (_) {
                        setState(() {
                          _expiryFilter = filter;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Tagi
                Text(
                  'Tagi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.availableTags.isEmpty)
                  Text(
                    'Brak tagów do filtrowania',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return FilterChip(
                        selected: selected,
                        label: Text(tag),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(
                      FilterState(
                        selectedTags: _selectedTags,
                        expiryFilter: _expiryFilter,
                        searchQuery: widget.initialState.searchQuery,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Zastosuj filtry'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _selectedTags.clear();
      _expiryFilter = ExpiryFilter.all;
    });
  }
}

/// Funkcja filtrująca leki
List<Medicine> applyFilters(List<Medicine> medicines, FilterState filters) {
  return medicines.where((m) {
    // Search query
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      final matchesSearch =
          (m.nazwa?.toLowerCase().contains(query) ?? false) ||
          m.opis.toLowerCase().contains(query) ||
          m.tagi.any((t) => t.toLowerCase().contains(query));
      if (!matchesSearch) return false;
    }

    // Expiry filter
    if (filters.expiryFilter != ExpiryFilter.all) {
      final status = m.expiryStatus;
      switch (filters.expiryFilter) {
        case ExpiryFilter.expired:
          if (status != ExpiryStatus.expired) return false;
          break;
        case ExpiryFilter.expiringSoon:
          if (status != ExpiryStatus.expiringSoon) return false;
          break;
        case ExpiryFilter.valid:
          if (status != ExpiryStatus.valid) return false;
          break;
        case ExpiryFilter.all:
          break;
      }
    }

    // Tags filter
    if (filters.selectedTags.isNotEmpty) {
      final hasMatchingTag = m.tagi.any(
        (t) => filters.selectedTags.contains(t),
      );
      if (!hasMatchingTag) return false;
    }

    return true;
  }).toList();
}
