import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/label.dart';
import '../services/storage_service.dart';

/// Widget do wyboru etykiet dla pojedynczego leku
class LabelSelector extends StatefulWidget {
  final StorageService storageService;
  final List<String> selectedLabelIds;
  final Function(List<String>) onChanged;
  final VoidCallback? onLabelsUpdated;

  /// Jeśli true, dropdown jest otwarty (kontrolowane z zewnątrz)
  final bool isOpen;

  /// Callback do zamknięcia/otwarcia dropdowna z zewnątrz
  final VoidCallback? onToggle;

  /// Callback wywoływany po kliknięciu etykiety (do filtrowania)
  final Function(String)? onLabelTap;

  const LabelSelector({
    super.key,
    required this.storageService,
    required this.selectedLabelIds,
    required this.onChanged,
    this.onLabelsUpdated,
    this.isOpen = false,
    this.onToggle,
    this.onLabelTap,
  });

  @override
  State<LabelSelector> createState() => _LabelSelectorState();
}

class _LabelSelectorState extends State<LabelSelector> {
  List<UserLabel> _allLabels = [];
  bool _isCreating = false;
  final _newLabelController = TextEditingController();
  LabelColor _selectedColor = LabelColor.blue;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  @override
  void dispose() {
    _newLabelController.dispose();
    super.dispose();
  }

  void _loadLabels() {
    setState(() {
      _allLabels = widget.storageService.getLabels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabels = widget.storageService.getLabelsByIds(
      widget.selectedLabelIds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wyświetl przypisane etykiety (klikalne do filtrowania, bez X)
        if (selectedLabels.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: selectedLabels.map((label) {
              final colorInfo = labelColors[label.color]!;
              return GestureDetector(
                onTap: () => widget.onLabelTap?.call(label.id),
                child: Chip(
                  label: Text(label.name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Color(
                    colorInfo.hexValue,
                  ).withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Dropdown z etykietami (kontrolowany przez widget.isOpen)
        if (widget.isOpen) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lista istniejących etykiet
                if (_allLabels.isEmpty && !_isCreating)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Brak etykiet. Utwórz pierwszą!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (!_isCreating) ...[
                  ..._allLabels.map((label) {
                    final isSelected = widget.selectedLabelIds.contains(
                      label.id,
                    );
                    final colorInfo = labelColors[label.color]!;
                    final canSelect =
                        isSelected ||
                        widget.selectedLabelIds.length < maxLabelsPerMedicine;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: canSelect
                          ? (_) => _toggleLabel(label.id)
                          : null,
                      title: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(colorInfo.hexValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(label.name)),
                        ],
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteLabel(label),
                        tooltip: 'Usuń etykietę',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }),

                  if (widget.selectedLabelIds.length >= maxLabelsPerMedicine)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Maksymalnie $maxLabelsPerMedicine etykiet na lek',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                // Formularz tworzenia nowej etykiety
                if (_isCreating) ...[
                  Text(
                    'Nowa etykieta',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newLabelController,
                    decoration: InputDecoration(
                      hintText: 'Nazwa etykiety',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LabelColor.values.map((color) {
                      final colorInfo = labelColors[color]!;
                      final isSelected = _selectedColor == color;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorInfo.hexValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isCreating = false;
                              _newLabelController.clear();
                            });
                          },
                          child: const Text('Anuluj'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _createLabel,
                          child: const Text('Utwórz'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Divider(),
                  TextButton.icon(
                    onPressed: _allLabels.length >= maxLabelsGlobal
                        ? null
                        : () => setState(() => _isCreating = true),
                    icon: const Icon(Icons.add),
                    label: Text(
                      _allLabels.length >= maxLabelsGlobal
                          ? 'Osiągnięto limit ($maxLabelsGlobal)'
                          : 'Utwórz nową etykietę',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _toggleLabel(String labelId) {
    final newSelection = List<String>.from(widget.selectedLabelIds);
    if (newSelection.contains(labelId)) {
      newSelection.remove(labelId);
    } else if (newSelection.length < maxLabelsPerMedicine) {
      newSelection.add(labelId);
    }
    widget.onChanged(newSelection);
  }

  Future<void> _createLabel() async {
    final name = _newLabelController.text.trim();
    if (name.isEmpty) return;

    final newLabel = UserLabel(
      id: const Uuid().v4(),
      name: name,
      color: _selectedColor,
    );

    await widget.storageService.saveLabel(newLabel);
    _newLabelController.clear();

    setState(() {
      _isCreating = false;
      _loadLabels();
    });

    widget.onLabelsUpdated?.call();
  }

  Future<void> _deleteLabel(UserLabel label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń etykietę?'),
        content: Text(
          'Czy na pewno chcesz usunąć etykietę "${label.name}"? '
          'Zostanie ona usunięta ze wszystkich leków.',
        ),
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
    );

    if (confirmed == true) {
      await widget.storageService.deleteLabel(label.id);

      // Usuń z aktualnego wyboru
      if (widget.selectedLabelIds.contains(label.id)) {
        final newSelection = widget.selectedLabelIds
            .where((id) => id != label.id)
            .toList();
        widget.onChanged(newSelection);
      }

      _loadLabels();
      widget.onLabelsUpdated?.call();
    }
  }
}
