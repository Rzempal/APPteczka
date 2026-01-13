import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';

/// Bottom sheet do szybkiego uzupełniania dat ważności dla wielu leków
class BatchDateInputSheet extends StatefulWidget {
  final List<Medicine> medicines;
  final StorageService storageService;
  final VoidCallback onComplete;

  const BatchDateInputSheet({
    super.key,
    required this.medicines,
    required this.storageService,
    required this.onComplete,
  });

  /// Pokazuje sheet tylko jeśli są leki bez daty
  static void showIfNeeded({
    required BuildContext context,
    required List<Medicine> medicines,
    required StorageService storageService,
    required VoidCallback onComplete,
  }) {
    final medicinesWithoutDate = medicines
        .where((m) => m.terminWaznosci == null || m.terminWaznosci!.isEmpty)
        .toList();

    if (medicinesWithoutDate.isEmpty) {
      onComplete();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => BatchDateInputSheet(
        medicines: medicinesWithoutDate,
        storageService: storageService,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<BatchDateInputSheet> createState() => _BatchDateInputSheetState();
}

class _BatchDateInputSheetState extends State<BatchDateInputSheet> {
  late Map<String, DateTime?> _dates;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dates = {for (var m in widget.medicines) m.id: null};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
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
                children: [
                  Icon(
                    LucideIcons.calendarPlus,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uzupełnij daty ważności',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.medicines.length} leków bez daty',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Lista leków
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: widget.medicines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final medicine = widget.medicines[index];
                  return _buildMedicineRow(medicine, isDark);
                },
              ),
            ),

            // Przyciski akcji
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: const Text('Pomiń'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveAll,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.save, size: 16),
                      label: const Text('Zapisz wszystkie'),
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

  Widget _buildMedicineRow(Medicine medicine, bool isDark) {
    final selectedDate = _dates[medicine.id];
    final hasDate = selectedDate != null;

    return Container(
      decoration: NeuDecoration.flat(isDark: isDark, radius: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Nazwa leku
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.nazwa ?? 'Nieznany lek',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (medicine.opis.isNotEmpty)
                  Text(
                    medicine.opis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Date picker button
          NeuButton(
            onPressed: () => _selectDate(medicine.id),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasDate ? LucideIcons.calendarCheck : LucideIcons.calendar,
                  size: 16,
                  color: hasDate
                      ? AppColors.valid
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  hasDate
                      ? '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                      : 'MM/YYYY',
                  style: TextStyle(
                    color: hasDate
                        ? AppColors.valid
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(String medicineId) async {
    // Pobierz aktualną datę jeśli była ustawiona
    final currentDate = _dates[medicineId];
    final now = DateTime.now();

    // Pokaż custom dialog z dropdownami MM/YYYY
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialMonth: currentDate?.month ?? now.month,
        initialYear: currentDate?.year ?? now.year + 1,
      ),
    );

    if (result != null) {
      setState(() {
        _dates[medicineId] = result;
      });
    }
  }

  void _skip() {
    Navigator.of(context).pop();
    widget.onComplete();
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      int updated = 0;
      for (final medicine in widget.medicines) {
        final date = _dates[medicine.id];
        if (date != null) {
          // Aktualizuj packages zamiast legacy terminWaznosci
          // Zachowaj pieceCount z pierwszego package jeśli istnieje
          final dateStr = date.toIso8601String().split('T')[0];
          final existingPieceCount = medicine.packages.isNotEmpty
              ? medicine.packages.first.pieceCount
              : null;
          final updatedPackages = [
            MedicinePackage(
              expiryDate: dateStr,
              pieceCount: existingPieceCount,
            ),
          ];
          final updatedMedicine = medicine.copyWith(packages: updatedPackages);
          await widget.storageService.saveMedicine(updatedMedicine);
          updated++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        if (updated > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zaktualizowano daty dla $updated leków'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        widget.onComplete();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Dialog z dropdownami MM/YYYY do wyboru daty ważności
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const _MonthYearPickerDialog({
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedMonth;
  late int _selectedYear;

  // Zakres lat: od teraz do +10 lat
  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;

    final currentYear = DateTime.now().year;
    _years = List.generate(11, (i) => currentYear + i);

    // Upewnij się że initial year jest w zakresie
    if (!_years.contains(_selectedYear)) {
      _selectedYear = _years.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj termin ważności'),
      content: Row(
        children: [
          // Dropdown miesiąc
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Miesiąc',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(12, (i) => i + 1).map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(month.toString().padLeft(2, '0')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Dropdown rok
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rok',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYear = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Anuluj', style: TextStyle(color: AppColors.primary)),
        ),
        FilledButton(
          onPressed: () {
            // Zwróć ostatni dzień wybranego miesiąca
            final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
            Navigator.of(context).pop(lastDay);
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
