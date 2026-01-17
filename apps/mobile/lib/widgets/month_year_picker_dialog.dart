import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dialog z dropdownami MM/YYYY do wyboru daty ważności
/// Reużywalny komponent używany w batch_date_input_sheet i barcode_scanner
class MonthYearPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const MonthYearPickerDialog({
    super.key,
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
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
                  initialValue: _selectedMonth,
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
                  initialValue: _selectedYear,
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
