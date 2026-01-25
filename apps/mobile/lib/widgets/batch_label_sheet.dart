import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/label.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';

/// Bottom sheet do masowej edycji etykiet wielu leków
/// Tryb: dodawanie/usuwanie (merge) - nie nadpisuje istniejących
class BatchLabelSheet extends StatefulWidget {
  final StorageService storageService;
  final List<Medicine> selectedMedicines;
  final VoidCallback? onComplete;

  const BatchLabelSheet({
    super.key,
    required this.storageService,
    required this.selectedMedicines,
    this.onComplete,
  });

  /// Pokazuje bottom sheet do batch edycji etykiet
  static Future<void> show({
    required BuildContext context,
    required StorageService storageService,
    required List<Medicine> selectedMedicines,
    VoidCallback? onComplete,
  }) {
    return AppBottomSheet.show(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return BatchLabelSheet(
          storageService: storageService,
          selectedMedicines: selectedMedicines,
          onComplete: onComplete,
        );
      },
    );
  }

  @override
  State<BatchLabelSheet> createState() => _BatchLabelSheetState();
}

class _BatchLabelSheetState extends State<BatchLabelSheet> {
  late List<UserLabel> _allLabels;

  // Stan etykiet: null = mixed, true = wszystkie mają, false = żaden nie ma
  final Map<String, bool?> _labelStates = {};

  // Zmiany do zastosowania: true = dodaj, false = usuń
  final Map<String, bool> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _allLabels = widget.storageService.getLabels();
    _calculateInitialStates();
  }

  void _calculateInitialStates() {
    for (final label in _allLabels) {
      int hasCount = 0;
      for (final medicine in widget.selectedMedicines) {
        if (medicine.labels.contains(label.id)) {
          hasCount++;
        }
      }

      if (hasCount == widget.selectedMedicines.length) {
        _labelStates[label.id] = true; // Wszystkie mają
      } else if (hasCount == 0) {
        _labelStates[label.id] = false; // Żaden nie ma
      } else {
        _labelStates[label.id] = null; // Mixed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.tags,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Etykiety dla ${widget.selectedMedicines.length} leków',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista etykiet
          Expanded(
            child: _allLabels.isEmpty
                ? Center(
                    child: Text(
                      'Brak etykiet. Utwórz etykiety w edycji leku.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _allLabels.length,
                    itemBuilder: (context, index) {
                      final label = _allLabels[index];
                      return _buildLabelTile(label, theme, isDark);
                    },
                  ),
          ),

          // Footer z przyciskami
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anuluj'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _pendingChanges.isEmpty ? null : _applyChanges,
                  child: Text(
                    _pendingChanges.isEmpty
                        ? 'Zastosuj'
                        : 'Zastosuj (${_pendingChanges.length})',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelTile(UserLabel label, ThemeData theme, bool isDark) {
    final colorInfo = labelColors[label.color]!;
    final bgColor = Color(colorInfo.hexValue);

    // Aktualny stan (uwzględniając pending changes)
    final currentState = _pendingChanges.containsKey(label.id)
        ? _pendingChanges[label.id]
        : _labelStates[label.id];

    // Ikona checkboxa: ✓ / - / puste
    Widget checkIcon;
    if (currentState == true) {
      checkIcon = Icon(
        LucideIcons.check,
        size: 18,
        color: theme.colorScheme.primary,
      );
    } else if (currentState == null) {
      checkIcon = Icon(
        LucideIcons.minus,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      );
    } else {
      checkIcon = const SizedBox(width: 18, height: 18);
    }

    return ListTile(
      onTap: () => _toggleLabel(label.id),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bgColor, width: 2),
        ),
        child: Center(child: checkIcon),
      ),
      title: Text(
        label.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: _pendingChanges.containsKey(label.id)
          ? Icon(
              _pendingChanges[label.id]! ? LucideIcons.plus : LucideIcons.minus,
              size: 16,
              color: _pendingChanges[label.id]!
                  ? AppColors.accent
                  : AppColors.expired,
            )
          : null,
    );
  }

  void _toggleLabel(String labelId) {
    setState(() {
      final originalState = _labelStates[labelId];
      final currentPending = _pendingChanges[labelId];

      if (currentPending == null) {
        // Pierwszy klik - ustaw przeciwny do original
        if (originalState == true || originalState == null) {
          _pendingChanges[labelId] = false; // Usuń
        } else {
          _pendingChanges[labelId] = true; // Dodaj
        }
      } else if (currentPending == false) {
        // Był "usuń" -> zmień na "dodaj"
        _pendingChanges[labelId] = true;
      } else {
        // Był "dodaj" -> usuń zmianę (powrót do original)
        _pendingChanges.remove(labelId);
      }
    });
  }

  Future<void> _applyChanges() async {
    for (final medicine in widget.selectedMedicines) {
      List<String> newLabels = List.from(medicine.labels);

      for (final entry in _pendingChanges.entries) {
        if (entry.value) {
          // Dodaj etykietę
          if (!newLabels.contains(entry.key)) {
            newLabels.add(entry.key);
          }
        } else {
          // Usuń etykietę
          newLabels.remove(entry.key);
        }
      }

      // Ogranicz do maksymalnej liczby etykiet (3)
      if (newLabels.length > maxLabelsPerMedicine) {
        newLabels = newLabels.take(maxLabelsPerMedicine).toList();
      }

      final updated = medicine.copyWith(labels: newLabels);
      await widget.storageService.saveMedicine(updated);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onComplete?.call();
    }
  }
}
