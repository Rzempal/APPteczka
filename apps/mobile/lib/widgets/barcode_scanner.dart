// barcode_scanner.dart v1.0.0 - Skaner kodow kreskowych EAN z ciagalym skanowaniem
// Widget do skanowania lekow z Rejestru Produktow Leczniczych

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/medicine.dart';
import '../services/rpl_service.dart';
import '../services/date_ocr_service.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';

/// Zeskanowany lek z kodem EAN i opcjonalna data waznosci
class ScannedDrug {
  final String ean;
  final RplDrugInfo drugInfo;
  String? expiryDate;

  ScannedDrug({
    required this.ean,
    required this.drugInfo,
    this.expiryDate,
  });

  /// Konwertuje do modelu Medicine
  Medicine toMedicine(String id) {
    return Medicine(
      id: id,
      nazwa: drugInfo.fullName,
      opis: drugInfo.description,
      wskazania: [],
      tagi: _generateTags(),
      terminWaznosci: expiryDate,
      dataDodania: DateTime.now().toIso8601String(),
      leafletUrl: drugInfo.leafletUrl,
    );
  }

  List<String> _generateTags() {
    final tags = <String>[];
    if (drugInfo.form.isNotEmpty) {
      // Mapuj formy farmaceutyczne na tagi
      final formLower = drugInfo.form.toLowerCase();
      if (formLower.contains('tabletk')) tags.add('tabletki');
      if (formLower.contains('kaps')) tags.add('kapsulki');
      if (formLower.contains('syrop')) tags.add('syrop');
      if (formLower.contains('masc') || formLower.contains('krem')) {
        tags.add('masc');
      }
      if (formLower.contains('zastrzyk') || formLower.contains('iniekcj')) {
        tags.add('zastrzyki');
      }
    }
    return tags;
  }
}

/// Tryb skanera
enum ScannerMode {
  /// Skanowanie kodu EAN
  ean,

  /// Skanowanie daty waznosci (OCR)
  expiryDate,
}

/// Widget skanera kodow kreskowych z ciagalym skanowaniem
class BarcodeScannerWidget extends StatefulWidget {
  /// Callback po zakonczeniu skanowania z lista lekow
  final void Function(List<ScannedDrug> drugs)? onComplete;

  /// Callback bledu
  final void Function(String? error)? onError;

  const BarcodeScannerWidget({
    super.key,
    this.onComplete,
    this.onError,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with WidgetsBindingObserver {
  // Kontroler skanera
  MobileScannerController? _controller;

  // Serwisy
  final RplService _rplService = RplService();
  final DateOcrService _dateOcrService = DateOcrService();
  final ImagePicker _imagePicker = ImagePicker();

  // Stan
  ScannerMode _mode = ScannerMode.ean;
  final List<ScannedDrug> _scannedDrugs = [];
  final Set<String> _scannedEans = {}; // Unika duplikatow
  bool _isProcessing = false;
  String? _lastError;
  ScannedDrug? _currentDrug; // Lek oczekujacy na date waznosci
  bool _isScannerActive = false;

  // Animacja sukcesu
  bool _showSuccess = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller?.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller?.stop();
        break;
    }
  }

  void _initScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    setState(() => _isScannerActive = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Instrukcje i licznik
        _buildHeader(theme, isDark),

        const SizedBox(height: 16),

        // Widok skanera lub przycisk uruchomienia
        if (_isScannerActive)
          _buildScannerView(theme, isDark)
        else
          _buildStartButton(theme, isDark),

        const SizedBox(height: 16),

        // Lista zeskanowanych lekow
        if (_scannedDrugs.isNotEmpty) ...[
          _buildScannedList(theme, isDark),
          const SizedBox(height: 16),
        ],

        // Przycisk zakonczenia
        if (_scannedDrugs.isNotEmpty) _buildFinishButton(theme, isDark),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _mode == ScannerMode.ean
                ? LucideIcons.barcode
                : LucideIcons.calendar,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mode == ScannerMode.ean
                      ? 'Zeskanuj kod kreskowy'
                      : 'Zeskanuj date waznosci',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _mode == ScannerMode.ean
                      ? 'Skieruj aparat na kod EAN opakowania'
                      : 'Zrob zdjecie daty waznosci lub wprowadz recznie',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_scannedDrugs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_scannedDrugs.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(ThemeData theme, bool isDark) {
    return NeuButton(
      onPressed: () {
        _initScanner();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Uruchom skaner',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(ThemeData theme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            // Widok kamery
            if (_controller != null)
              MobileScanner(
                controller: _controller!,
                onDetect: _onBarcodeDetected,
              ),

            // Overlay z ramka celownika
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  borderColor: _mode == ScannerMode.ean
                      ? theme.colorScheme.primary
                      : Colors.orange,
                  borderWidth: 3,
                ),
              ),
            ),

            // Animacja sukcesu
            if (_showSuccess)
              Positioned.fill(
                child: Container(
                  color: Colors.green.withAlpha(180),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _successMessage ?? 'Rozpoznano!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Wskaznik ladowania
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),

            // Blad
            if (_lastError != null && !_isProcessing)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lastError!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Przyciski kontrolne
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  // Latarka
                  _buildControlButton(
                    icon: LucideIcons.flashlight,
                    onTap: () => _controller?.toggleTorch(),
                  ),
                  const SizedBox(width: 8),
                  // Przelacz kamere
                  _buildControlButton(
                    icon: LucideIcons.switchCamera,
                    onTap: () => _controller?.switchCamera(),
                  ),
                ],
              ),
            ),

            // Tryb daty - przycisk recznego wprowadzania
            if (_mode == ScannerMode.expiryDate)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildControlButton(
                  icon: LucideIcons.pencil,
                  label: 'Recznie',
                  onTap: _showManualDateInput,
                ),
              ),

            // Tryb daty - przycisk zdjecia
            if (_mode == ScannerMode.expiryDate)
              Positioned(
                bottom: 60,
                left: 16,
                child: _buildControlButton(
                  icon: LucideIcons.camera,
                  label: 'Zdjecie',
                  onTap: _captureExpiryDatePhoto,
                ),
              ),

            // Tryb daty - przycisk pomin
            if (_mode == ScannerMode.expiryDate)
              Positioned(
                top: 16,
                right: 16,
                child: _buildControlButton(
                  icon: LucideIcons.skipForward,
                  label: 'Pomin',
                  onTap: _skipExpiryDate,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannedList(ThemeData theme, bool isDark) {
    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zeskanowane leki (${_scannedDrugs.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Lista lekow (max 5 widocznych)
          ...(_scannedDrugs.length > 5
                  ? _scannedDrugs.sublist(_scannedDrugs.length - 5)
                  : _scannedDrugs)
              .map((drug) => _buildDrugItem(drug, theme, isDark)),
          if (_scannedDrugs.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... i ${_scannedDrugs.length - 5} wiecej',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrugItem(ScannedDrug drug, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.pill,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              drug.drugInfo.fullName,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (drug.expiryDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatDate(drug.expiryDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            )
          else
            Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildFinishButton(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: NeuButton(
            onPressed: () {
              _controller?.stop();
              setState(() => _isScannerActive = false);
              widget.onComplete?.call(_scannedDrugs);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.check, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Zakoncz skanowanie (${_scannedDrugs.length})',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== LOGIKA SKANOWANIA ====================

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;

      if (_mode == ScannerMode.ean) {
        await _processEan(code);
      }
      // W trybie daty nie uzywamy skanera kodow - uzywamy OCR zdjecia
      break;
    }
  }

  Future<void> _processEan(String ean) async {
    // Sprawdz czy juz zeskanowano
    if (_scannedEans.contains(ean)) {
      _showError('Juz zeskanowano ten kod');
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastError = null;
    });

    try {
      final drugInfo = await _rplService.fetchDrugByEan(ean);

      if (drugInfo == null) {
        _showError('Nie znaleziono leku o kodzie $ean');
        return;
      }

      // Sukces - haptic feedback
      HapticFeedback.mediumImpact();

      final drug = ScannedDrug(ean: ean, drugInfo: drugInfo);
      _scannedEans.add(ean);

      setState(() {
        _currentDrug = drug;
        _showSuccess = true;
        _successMessage = drugInfo.fullName;
      });

      // Pokaz sukces przez chwile
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      setState(() {
        _showSuccess = false;
        _successMessage = null;
        // Przelacz na tryb daty
        _mode = ScannerMode.expiryDate;
      });
    } on RplException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Blad: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _captureExpiryDatePhoto() async {
    if (_currentDrug == null) return;

    setState(() => _isProcessing = true);

    try {
      // Zrob zdjecie
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // OCR daty
      final result = await _dateOcrService.recognizeDate(File(image.path));

      if (result.terminWaznosci != null) {
        HapticFeedback.mediumImpact();
        _currentDrug!.expiryDate = result.terminWaznosci;
        _finishCurrentDrug();
      } else {
        // Nie rozpoznano - pokaz dialog recznego wprowadzania
        if (mounted) {
          _showManualDateInput();
        }
      }
    } on DateOcrException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Blad OCR: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualDateInput() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wprowadz date waznosci',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _currentDrug?.drugInfo.fullName ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Data waznosci (MM/YYYY)',
                hintText: '03/2027',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.calendar),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _skipExpiryDate();
                    },
                    child: const Text('Pomin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final date = _parseManualDate(controller.text);
                      if (date != null) {
                        _currentDrug!.expiryDate = date;
                        Navigator.pop(context);
                        _finishCurrentDrug();
                      }
                    },
                    child: const Text('Zapisz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String? _parseManualDate(String input) {
    // Format: MM/YYYY lub MM-YYYY lub MMYYYY
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 6) return null;

    final month = int.tryParse(cleaned.substring(0, 2));
    final year = int.tryParse(cleaned.substring(2, 6));

    if (month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (year < 2020 || year > 2050) return null;

    // Zwroc ostatni dzien miesiaca w formacie ISO
    final lastDay = DateTime(year, month + 1, 0).day;
    return '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
  }

  void _skipExpiryDate() {
    if (_currentDrug != null) {
      _finishCurrentDrug();
    }
  }

  void _finishCurrentDrug() {
    if (_currentDrug == null) return;

    setState(() {
      _scannedDrugs.add(_currentDrug!);
      _currentDrug = null;
      _mode = ScannerMode.ean; // Wroc do skanowania EAN
    });
  }

  void _showError(String message) {
    setState(() => _lastError = message);
    HapticFeedback.heavyImpact();

    // Usun blad po 3 sekundach
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _lastError == message) {
        setState(() => _lastError = null);
      }
    });
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

/// Painter dla overlay skanera z ramka celownika
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Ramka w centrum
    final frameWidth = size.width * 0.7;
    final frameHeight = size.height * 0.5;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Przyciemnij obszar poza ramka
    final overlayPaint = Paint()..color = Colors.black38;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Narysuj ramke
    canvas.drawRRect(rrect, paint);

    // Narozniki (grubsze linie)
    final cornerLength = 24.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2
      ..strokeCap = StrokeCap.round;

    // Lewy gorny
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Prawy gorny
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength, top),
      Offset(left + frameWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth, top + cornerLength),
      cornerPaint,
    );

    // Lewy dolny
    canvas.drawLine(
      Offset(left, top + frameHeight - cornerLength),
      Offset(left, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + frameHeight),
      Offset(left + cornerLength, top + frameHeight),
      cornerPaint,
    );

    // Prawy dolny
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight - cornerLength),
      Offset(left + frameWidth, top + frameHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
