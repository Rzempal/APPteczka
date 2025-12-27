import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

/// Widget do skanowania leków przez Gemini Vision
class GeminiScanner extends StatefulWidget {
  final Function(GeminiScanResult) onResult;
  final VoidCallback? onImportComplete;

  const GeminiScanner({
    super.key,
    required this.onResult,
    this.onImportComplete,
  });

  @override
  State<GeminiScanner> createState() => _GeminiScannerState();
}

class _GeminiScannerState extends State<GeminiScanner> {
  final _geminiService = GeminiService();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isScanning = false;
  String? _error;
  GeminiScanResult? _result;

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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini AI Vision',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Zrób zdjęcie leków - AI rozpozna je automatycznie',
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

            // Podgląd zdjęcia lub placeholder
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        onPressed: _isScanning ? null : _clearImage,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_isScanning)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black38,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Analizuję zdjęcie...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Błąd
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Wynik skanowania
            if (_result != null && _result!.leki.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rozpoznano ${_result!.leki.length} leków',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_result!.leki
                        .take(3)
                        .map(
                          (lek) => Padding(
                            padding: const EdgeInsets.only(left: 32, bottom: 4),
                            child: Text(
                              '• ${lek.nazwa ?? 'Nieznany lek'}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )),
                    if (_result!.leki.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          '... i ${_result!.leki.length - 3} więcej',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  widget.onResult(_result!);
                  widget.onImportComplete?.call();
                  _clearAll();
                },
                icon: const Icon(Icons.download),
                label: Text('Importuj ${_result!.leki.length} leków'),
              ),
            ] else ...[
              // Przyciski wyboru zdjęcia
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Aparat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ),
                ],
              ),

              if (_selectedImage != null && !_isScanning) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _scanImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Skanuj zdjęcie'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _error = null;
          _result = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Nie udało się wybrać zdjęcia: $e';
      });
    }
  }

  Future<void> _scanImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final result = await _geminiService.scanImage(_selectedImage!);

      if (result.leki.isEmpty) {
        setState(() {
          _error = 'Nie rozpoznano żadnych leków. Spróbuj z lepszym zdjęciem.';
        });
      } else {
        setState(() {
          _result = result;
        });
      }
    } on GeminiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Błąd skanowania: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _error = null;
    });
  }

  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _error = null;
    });
  }
}
