import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/gemini_service.dart';
import '../services/date_ocr_service.dart';
import '../theme/app_theme.dart';

/// Widget do skanowania leku w trybie 2-zdjęciowym (front + data)
class TwoPhotoScanner extends StatefulWidget {
  final Function(ScannedMedicine) onResult;
  final VoidCallback? onComplete;
  final Function(String?)? onError;

  const TwoPhotoScanner({
    super.key,
    required this.onResult,
    this.onComplete,
    this.onError,
  });

  @override
  State<TwoPhotoScanner> createState() => _TwoPhotoScannerState();
}

class _TwoPhotoScannerState extends State<TwoPhotoScanner> {
  final _geminiService = GeminiService();
  final _dateOcrService = DateOcrService();
  final _imagePicker = ImagePicker();

  // Krok 1: Zdjęcie frontu
  File? _frontImage;
  bool _isScanningFront = false;
  ScannedMedicine? _recognizedMedicine;

  // Krok 2: Zdjęcie daty
  File? _dateImage;
  bool _isScanningDate = false;
  String? _recognizedDate;

  String? _error;
  int _currentStep = 1; // 1 = front, 2 = data, 3 = ready

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.images,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tryb 2 zdjęcia',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Zdjęcie frontu + zdjęcie daty ważności',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stepper progress
            _buildStepIndicator(theme),

            const SizedBox(height: 16),

            // Błąd
            if (_error != null) ...[
              _buildErrorCard(theme),
              const SizedBox(height: 12),
            ],

            // Krok 1: Zdjęcie frontu
            if (_currentStep == 1) _buildFrontStep(theme),

            // Krok 2: Zdjęcie daty
            if (_currentStep == 2) _buildDateStep(theme),

            // Krok 3: Podsumowanie
            if (_currentStep == 3) _buildSummaryStep(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      children: [
        _buildStepCircle(1, 'Front', theme),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep > 1 ? AppColors.primary : theme.dividerColor,
          ),
        ),
        _buildStepCircle(2, 'Data', theme),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep > 2 ? AppColors.primary : theme.dividerColor,
          ),
        ),
        _buildStepCircle(3, 'Gotowe', theme),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, ThemeData theme) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : theme.dividerColor,
            border: isCurrent
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFrontStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Krok 1: Zdjęcie frontu opakowania',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zrób zdjęcie przodu opakowania z widoczną nazwą leku',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        if (_frontImage != null) ...[
          _buildImagePreview(
            _frontImage!,
            _isScanningFront,
            'Rozpoznaję nazwę...',
          ),
          const SizedBox(height: 12),
        ],

        if (_recognizedMedicine != null) ...[
          _buildSuccessCard(
            theme,
            _recognizedMedicine!.nazwa ?? 'Nieznany lek',
            'Nazwa rozpoznana',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() => _currentStep = 2),
            icon: const Icon(LucideIcons.arrowRight, size: 16),
            label: const Text('Dalej - zdjęcie daty'),
          ),
        ] else ...[
          _buildImagePickerButtons(
            isScanning: _isScanningFront,
            onPick: _pickFrontImage,
          ),
          if (_frontImage != null && !_isScanningFront) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _scanFront,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Rozpoznaj nazwę'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDateStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info o rozpoznanym leku
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.pill, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _recognizedMedicine?.nazwa ?? 'Nieznany lek',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _currentStep = 1;
                  _recognizedMedicine = null;
                  _frontImage = null;
                }),
                child: const Text('Zmień'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Krok 2: Zdjęcie daty ważności',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zrób zdjęcie daty ważności (EXP, Ważny do...)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        if (_dateImage != null) ...[
          _buildImagePreview(
            _dateImage!,
            _isScanningDate,
            'Rozpoznaję datę...',
          ),
          const SizedBox(height: 12),
        ],

        if (_recognizedDate != null) ...[
          _buildSuccessCard(
            theme,
            _formatDate(_recognizedDate!),
            'Data rozpoznana',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() => _currentStep = 3),
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('Dalej - podsumowanie'),
          ),
        ] else ...[
          _buildImagePickerButtons(
            isScanning: _isScanningDate,
            onPick: _pickDateImage,
          ),
          if (_dateImage != null && !_isScanningDate) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _scanDate,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Rozpoznaj datę'),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _currentStep = 3),
            child: const Text('Pomiń (bez daty)'),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Podsumowanie',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                theme,
                LucideIcons.pill,
                'Nazwa',
                _recognizedMedicine?.nazwa ?? 'Nieznany lek',
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                theme,
                LucideIcons.calendar,
                'Data ważności',
                _recognizedDate != null
                    ? _formatDate(_recognizedDate!)
                    : 'Nie ustawiono',
              ),
              if (_recognizedMedicine?.opis.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildSummaryRow(
                  theme,
                  LucideIcons.fileText,
                  'Opis',
                  _recognizedMedicine!.opis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _importMedicine,
          icon: const Icon(LucideIcons.download, size: 16),
          label: const Text('Importuj lek'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _clearAll, child: const Text('Anuluj')),
      ],
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(File image, bool isScanning, String scanningText) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.file(
            image,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        scanningText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButtons({
    required bool isScanning,
    required Function(ImageSource) onPick,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isScanning ? null : () => onPick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Aparat'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isScanning ? null : () => onPick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Galeria'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard(ThemeData theme, String text, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.valid.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.valid.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleCheck, size: 20, color: AppColors.valid),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.valid,
                  ),
                ),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Actions ====================

  Future<void> _pickFrontImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _frontImage = File(pickedFile.path);
          _error = null;
          _recognizedMedicine = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Nie udało się wybrać zdjęcia: $e');
      widget.onError?.call(_error);
    }
  }

  Future<void> _pickDateImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _dateImage = File(pickedFile.path);
          _error = null;
          _recognizedDate = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Nie udało się wybrać zdjęcia: $e');
    }
  }

  Future<void> _scanFront() async {
    if (_frontImage == null) return;

    setState(() {
      _isScanningFront = true;
      _error = null;
    });

    try {
      final result = await _geminiService.scanImage(_frontImage!);

      if (result.leki.isEmpty) {
        setState(() {
          _error = 'Nie rozpoznano leku. Spróbuj z lepszym zdjęciem.';
        });
        widget.onError?.call(_error);
      } else {
        // Bierzemy pierwszy rozpoznany lek
        setState(() {
          _recognizedMedicine = result.leki.first;
        });
        widget.onError?.call(null); // Clear error on success
      }
    } on GeminiException catch (e) {
      setState(() => _error = e.message);
      widget.onError?.call(_error);
    } catch (e) {
      setState(() => _error = 'Błąd skanowania: $e');
      widget.onError?.call(_error);
    } finally {
      setState(() => _isScanningFront = false);
    }
  }

  Future<void> _scanDate() async {
    if (_dateImage == null) return;

    setState(() {
      _isScanningDate = true;
      _error = null;
    });

    try {
      final result = await _dateOcrService.recognizeDate(_dateImage!);

      if (result.terminWaznosci == null) {
        setState(() {
          _error = 'Nie rozpoznano daty. Spróbuj z lepszym zdjęciem.';
        });
        widget.onError?.call(_error);
      } else {
        setState(() {
          _recognizedDate = result.terminWaznosci;
        });
        widget.onError?.call(null); // Clear error on success
      }
    } on DateOcrException catch (e) {
      setState(() => _error = e.message);
      widget.onError?.call(_error);
    } catch (e) {
      setState(() => _error = 'Błąd skanowania: $e');
      widget.onError?.call(_error);
    } finally {
      setState(() => _isScanningDate = false);
    }
  }

  void _importMedicine() {
    if (_recognizedMedicine == null) return;

    // Tworzymy nowy ScannedMedicine z datą
    final medicineWithDate = ScannedMedicine(
      nazwa: _recognizedMedicine!.nazwa,
      opis: _recognizedMedicine!.opis,
      wskazania: _recognizedMedicine!.wskazania,
      tagi: _recognizedMedicine!.tagi,
      terminWaznosci: _recognizedDate,
    );

    widget.onResult(medicineWithDate);
    widget.onComplete?.call();
    _clearAll();
  }

  void _clearAll() {
    setState(() {
      _frontImage = null;
      _dateImage = null;
      _recognizedMedicine = null;
      _recognizedDate = null;
      _error = null;
      _currentStep = 1;
    });
    widget.onError?.call(null);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
