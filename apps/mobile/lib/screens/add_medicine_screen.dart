import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';

/// Ekran dodawania leku - ręcznie lub przez prompt AI
class AddMedicineScreen extends StatefulWidget {
  final StorageService storageService;

  const AddMedicineScreen({super.key, required this.storageService});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nazwaController = TextEditingController();
  final _opisController = TextEditingController();
  final _wskazaniaController = TextEditingController();
  final _tagiController = TextEditingController();
  DateTime? _terminWaznosci;
  bool _isSaving = false;

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
      appBar: AppBar(title: const Text('➕ Dodaj lek')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instrukcja
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Wskazówka',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Możesz też użyć AI (ChatGPT/Gemini) do rozpoznania leków ze zdjęcia. Skopiuj prompt poniżej.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _copyAiPrompt,
                        icon: const Icon(Icons.copy),
                        label: const Text('Kopiuj prompt AI'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Formularz
              Text(
                'Dane leku',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Nazwa
              TextFormField(
                controller: _nazwaController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa leku *',
                  hintText: 'np. Paracetamol 500mg',
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
                  hintText: 'Krótki opis działania leku',
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
                  hintText: 'ból głowy, gorączka, ból mięśni',
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
                  hintText: 'przeciwbólowy, lek OTC',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Termin ważności
              ListTile(
                contentPadding: EdgeInsets.zero,
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

              const SizedBox(height: 32),

              // Przycisk zapisu
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveMedicine,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Zapisz lek'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
      final medicine = Medicine(
        id: const Uuid().v4(),
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
        dataDodania: DateTime.now().toIso8601String(),
      );

      await widget.storageService.saveMedicine(medicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano: ${medicine.nazwa}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Zwróć true = dodano lek
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _copyAiPrompt() {
    const prompt = '''Rozpoznaj leki ze zdjęcia i zwróć w formacie JSON:

{
  "leki": [
    {
      "nazwa": "Dokładna nazwa leku z opakowania",
      "opis": "Krótki opis działania (max 100 znaków)",
      "wskazania": ["wskazanie 1", "wskazanie 2"],
      "tagi": ["ból", "przeciwgorączkowy", "lek OTC"]
    }
  ]
}

Dozwolone tagi: ból, ból głowy, gorączka, kaszel, katar, alergia, nudności, biegunka, przeciwbólowy, przeciwgorączkowy, przeciwzapalny, lek OTC, lek Rx, suplement, dla dorosłych, dla dzieci.''';

    Clipboard.setData(const ClipboardData(text: prompt));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Prompt skopiowany! Wklej go do ChatGPT/Gemini ze zdjęciem leków.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }
}
