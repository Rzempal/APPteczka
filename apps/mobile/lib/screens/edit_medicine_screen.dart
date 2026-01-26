import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../utils/pharmaceutical_form_helper.dart';

/// Ekran edycji leku
class EditMedicineScreen extends StatefulWidget {
  final StorageService storageService;
  final Medicine medicine;

  const EditMedicineScreen({
    super.key,
    required this.storageService,
    required this.medicine,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nazwaController;
  late TextEditingController _opisController;
  late TextEditingController _wskazaniaController;
  late TextEditingController _tagiController;
  DateTime? _terminWaznosci;
  String? _selectedForm;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nazwaController = TextEditingController(text: widget.medicine.nazwa ?? '');
    _opisController = TextEditingController(text: widget.medicine.opis);
    _wskazaniaController = TextEditingController(
      text: widget.medicine.wskazania.join(', '),
    );
    _tagiController = TextEditingController(
      text: widget.medicine.tagi.join(', '),
    );
    if (widget.medicine.terminWaznosci != null) {
      _terminWaznosci = DateTime.tryParse(widget.medicine.terminWaznosci!);
    }
    _selectedForm = widget.medicine.pharmaceuticalForm;
  }

  @override
  void dispose() {
    _nazwaController.dispose();
    _opisController.dispose();
    _wskazaniaController.dispose();
    _tagiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Edytuj lek'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nazwa
              TextFormField(
                controller: _nazwaController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa leku *',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Podaj nazwę leku';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Opis
              TextFormField(
                controller: _opisController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis działania *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Podaj opis leku';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Wskazania
              TextFormField(
                controller: _wskazaniaController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Wskazania (oddzielone przecinkami)',
                  prefixIcon: Icon(Icons.checklist),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              // Tagi
              TextFormField(
                controller: _tagiController,
                decoration: const InputDecoration(
                  labelText: 'Tagi (oddzielone przecinkami)',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Postać farmaceutyczna
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        PharmaceuticalFormHelper.getIcon(_selectedForm),
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value:
                              PharmaceuticalFormHelper.predefinedForms.contains(
                                _selectedForm?.toLowerCase(),
                              )
                              ? _selectedForm?.toLowerCase()
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Postać farmaceutyczna',
                            border: OutlineInputBorder(),
                          ),
                          hint: Text(_selectedForm ?? 'Wybierz postać'),
                          items: PharmaceuticalFormHelper.predefinedForms
                              .map(
                                (form) => DropdownMenuItem(
                                  value: form,
                                  child: Row(
                                    children: [
                                      Icon(
                                        PharmaceuticalFormHelper.getIcon(form),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(form),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedForm = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Termin ważności
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Termin ważności'),
                  subtitle: Text(
                    _terminWaznosci != null
                        ? '${_terminWaznosci!.day.toString().padLeft(2, '0')}.${_terminWaznosci!.month.toString().padLeft(2, '0')}.${_terminWaznosci!.year}'
                        : 'Nie ustawiono',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_terminWaznosci != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _terminWaznosci = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Przyciski
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveMedicine,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Zapisz zmiany'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _terminWaznosci ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() {
        _terminWaznosci = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedMedicine = widget.medicine.copyWith(
        nazwa: _nazwaController.text.trim(),
        opis: _opisController.text.trim(),
        wskazania: _wskazaniaController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        tagi: _tagiController.text
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList(),
        terminWaznosci: _terminWaznosci?.toIso8601String().split('T')[0],
        pharmaceuticalForm: _selectedForm,
      );

      await widget.storageService.saveMedicine(updatedMedicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zapisano: ${updatedMedicine.nazwa}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń lek?'),
        content: Text('Czy na pewno chcesz usunąć "${widget.medicine.nazwa}"?'),
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
      await widget.storageService.deleteMedicine(widget.medicine.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usunięto: ${widget.medicine.nazwa}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }
}
