// barcode_scanner.dart v1.7.0 - Skaner kodow kreskowych EAN z batch processing
// Widget do skanowania lekow z Rejestru Produktow Leczniczych
// v1.7.0 - Lepsze akcentowanie pomylek usera (czerwony monit, dialog wyboru, AI highlights)

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import '../models/medicine.dart';
import '../services/rpl_service.dart';
import '../theme/app_theme.dart';
import '../utils/gs1_parser.dart';
import 'neumorphic/neumorphic.dart';

/// Zeskanowany lek z kodem EAN i opcjonalna data waznosci
class ScannedDrug {
  final String ean;
  final RplDrugInfo? drugInfo; // Nullable - moze nie byc w RPL
  String? expiryDate;
  String? tempImagePath; // Sciezka do snapshotu daty waznosci
  String? tempProductImagePath; // Sciezka do snapshotu nazwy produktu

  // Dane z OCR (gdy brak w RPL)
  String? scannedName;
  String? scannedDescription;
  List<String>? scannedTags;

  ScannedDrug({
    required this.ean,
    this.drugInfo,
    this.expiryDate,
    this.tempImagePath,
    this.tempProductImagePath,
    this.scannedName,
    this.scannedDescription,
    this.scannedTags,
  });

  /// Nazwa produktu (z RPL lub OCR)
  String get displayName =>
      drugInfo?.fullName ?? scannedName ?? 'Nieznany produkt';

  /// Czy produkt jest z RPL
  bool get isFromRpl => drugInfo != null;

  /// Ilość sztuk z opakowania (cache)
  int? get pieceCount => drugInfo != null ? _parsePackaging() : null;

  /// Konwertuje do modelu Medicine
  Medicine toMedicine(String id) {
    final pieceCount = _parsePackaging();

    return Medicine(
      id: id,
      nazwa: displayName,
      opis: scannedDescription ?? drugInfo?.description ?? '',
      wskazania: [],
      tagi: scannedTags ?? (drugInfo != null ? _generateTags() : <String>[]),
      packages: expiryDate != null
          ? [MedicinePackage(expiryDate: expiryDate!, pieceCount: pieceCount)]
          : [],
      dataDodania: DateTime.now().toIso8601String(),
      leafletUrl: drugInfo?.leafletUrl,
    );
  }

  /// Generuje tagi na podstawie danych z API RPL
  List<String> _generateTags() {
    if (drugInfo == null) return [];
    final info = drugInfo!;
    final tags = <String>{};

    // 1. Status recepty (accessibilityCategory)
    final category = info.accessibilityCategory?.toUpperCase();
    if (category != null) {
      if (category == 'OTC') {
        tags.add('bez recepty');
      } else if (category == 'RP' || category == 'RPZ') {
        tags.add('na receptę');
      }
    }

    // 2. Postac farmaceutyczna
    if (info.form.isNotEmpty) {
      final formLower = info.form.toLowerCase();
      if (formLower.contains('tabletk')) {
        tags.add('tabletki');
      } else if (formLower.contains('kaps')) {
        tags.add('kapsułki');
      } else if (formLower.contains('syrop')) {
        tags.add('syrop');
      } else if (formLower.contains('masc') || formLower.contains('krem')) {
        tags.add('maść');
      } else if (formLower.contains('zastrzyk') ||
          formLower.contains('iniekcj')) {
        tags.add('zastrzyki');
      } else if (formLower.contains('krople')) {
        tags.add('krople');
      } else if (formLower.contains('aerozol') || formLower.contains('spray')) {
        tags.add('aerozol');
      } else if (formLower.contains('czopk')) {
        tags.add('czopki');
      } else if (formLower.contains('plast')) {
        tags.add('plastry');
      } else if (formLower.contains('zawies') ||
          formLower.contains('proszek')) {
        tags.add('proszek/zawiesina');
      }
    }

    // 3. Substancje czynne (dzielimy po " + ")
    if (info.activeSubstance.isNotEmpty) {
      final substances = info.activeSubstance
          .split(RegExp(r'\s*\+\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      tags.addAll(substances);
    }

    return tags.toList();
  }

  /// Parsuje packaging na ilosc sztuk
  /// Np. "28 tabl. (2 x 14)" -> 28, "1 butelka 120 ml" -> 120
  int? _parsePackaging() {
    final packaging = drugInfo?.packaging;
    if (packaging == null || packaging.isEmpty) return null;

    final lower = packaging.toLowerCase();

    // Wzorzec 1: "28 tabl.", "30 kaps.", "10 amp."
    final countMatch = RegExp(
      r'^(\d+)\s*(tabl|kaps|amp|sasz|czop|plast)',
    ).firstMatch(lower);
    if (countMatch != null) {
      return int.tryParse(countMatch.group(1)!);
    }

    // Wzorzec 2: "1 butelka 120 ml", "1 tuba 30 g" - bierzemy objetosc/mase
    final volumeMatch = RegExp(r'(\d+)\s*(ml|g)\b').firstMatch(lower);
    if (volumeMatch != null) {
      return int.tryParse(volumeMatch.group(1)!);
    }

    // Wzorzec 3: po prostu pierwsza liczba
    final firstNumber = RegExp(r'(\d+)').firstMatch(lower);
    if (firstNumber != null) {
      return int.tryParse(firstNumber.group(1)!);
    }

    return null;
  }
}

/// Tryb skanera
enum ScannerMode {
  /// Skanowanie kodu EAN
  ean,

  /// Zdjecie nazwy produktu (gdy brak w RPL)
  productPhoto,

  /// Skanowanie daty waznosci (OCR)
  expiryDate,
}

/// Widget skanera kodow kreskowych z ciagalym skanowaniem
class BarcodeScannerWidget extends StatefulWidget {
  /// Callback po zakonczeniu skanowania z lista lekow
  final void Function(List<ScannedDrug> drugs)? onComplete;

  /// Callback bledu
  final void Function(String? error)? onError;

  const BarcodeScannerWidget({super.key, this.onComplete, this.onError});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with WidgetsBindingObserver {
  // Kontroler skanera
  MobileScannerController? _controller;

  // Klucz do RepaintBoundary dla snapshotu
  final GlobalKey _scannerKey = GlobalKey();

  // Serwisy
  final RplService _rplService = RplService();

  // Stan
  ScannerMode _mode = ScannerMode.ean;
  final List<ScannedDrug> _scannedDrugs = [];
  final Set<String> _scannedEans = {}; // Unika duplikatow
  bool _isProcessing = false;
  String? _lastError;
  ScannedDrug? _currentDrug; // Lek oczekujacy na date waznosci
  bool _isScannerActive = false;
  bool _isAiMode = false; // Czy user wybral AI rozpoznawanie

  // Animacja sukcesu
  bool _showSuccess = false;
  String? _successMessage;

  // Animacja bledu "Nie rozpoznano"
  bool _showNotRecognized = false;

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
    // Dynamiczne tresci headera w zaleznosci od stanu
    String title;
    String subtitle;
    IconData icon;
    Color? iconColor;

    if (_mode == ScannerMode.ean) {
      if (_isProcessing) {
        icon = LucideIcons.search;
        iconColor = Colors.orange;
        title = 'Szukam w bazie RPL...';
        subtitle = 'Sprawdzam kod EAN';
      } else {
        icon = LucideIcons.barcode;
        iconColor = theme.colorScheme.primary;
        title = _isScannerActive
            ? 'Zeskanuj kod kreskowy'
            : 'Uruchom skaner by rozpocząć';
        subtitle = 'Skieruj aparat na kod kreskowy na opakowaniu';
      }
    } else if (_mode == ScannerMode.productPhoto) {
      // Tryb zdjecia nazwy produktu (gdy brak w RPL)
      icon = LucideIcons.scanText;
      iconColor = Colors.purple;
      title = 'Produkt nierozpoznany';
      subtitle = 'Zrób zdjęcie nazwy produktu';
    } else {
      // Tryb daty waznosci - pokaz nazwe leku
      icon = LucideIcons.camera;
      iconColor = Colors.orange;
      title = _currentDrug?.displayName ?? 'Dodaj datę ważności';
      subtitle = 'Zrób zdjęcie daty ważności lub Pomiń';
    }

    return NeuInsetContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
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
          Icon(LucideIcons.scanLine, color: theme.colorScheme.primary),
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
            // Widok kamery (owiniety w RepaintBoundary dla snapshotu)
            if (_controller != null)
              RepaintBoundary(
                key: _scannerKey,
                child: MobileScanner(
                  controller: _controller!,
                  onDetect: _onBarcodeDetected,
                ),
              ),

            // Overlay z ramka celownika
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  borderColor: _mode == ScannerMode.ean
                      ? theme.colorScheme.primary
                      : _mode == ScannerMode.productPhoto && _isAiMode
                          ? (isDark
                              ? AppColors.aiAccentDark
                              : AppColors.aiAccentLight)
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

            // Animacja "Nie rozpoznano"
            if (_showNotRecognized)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withAlpha(180),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.circleX,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '❌ Nie rozpoznano',
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

            // Blad (top-center)
            if (_lastError != null && !_isProcessing)
              Positioned(
                top: 16,
                left: 60,
                right: 60,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lastError!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Latarka (top-left)
            Positioned(
              top: 16,
              left: 16,
              child: _buildControlButton(
                icon: LucideIcons.flashlight,
                onTap: () => _controller?.toggleTorch(),
              ),
            ),

            // Przełącz kamerę (top-right)
            Positioned(
              top: 16,
              right: 16,
              child: _buildControlButton(
                icon: LucideIcons.switchCamera,
                onTap: () => _controller?.switchCamera(),
              ),
            ),

            // Tryb EAN - przycisk "Brak kodu / kod nieczytelny" (bottom-center)
            if (_mode == ScannerMode.ean)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildControlButton(
                    icon: LucideIcons.antenna,
                    label: 'Brak kodu / kod nieczytelny',
                    onTap: _skipBarcodeScan,
                  ),
                ),
              ),

            // Tryb daty - przycisk Pomiń (bottom-left)
            if (_mode == ScannerMode.expiryDate)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildControlButton(
                  icon: LucideIcons.arrowBigRightDash,
                  label: 'Pomiń',
                  onTap: _skipExpiryDate,
                ),
              ),

            // Tryb daty - przycisk Zrób zdjęcie (bottom-right)
            if (_mode == ScannerMode.expiryDate)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _captureExpiryDatePhoto,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.calendarPlus,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            children: [
                              TextSpan(text: 'Zrób zdjęcie '),
                              TextSpan(
                                text: 'daty ważności',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tryb productPhoto - przycisk Pomiń (bottom-left)
            if (_mode == ScannerMode.productPhoto)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildControlButton(
                  icon: LucideIcons.arrowBigRightDash,
                  label: 'Pomiń',
                  onTap: _skipProductPhoto,
                ),
              ),

            // Tryb productPhoto - przycisk Zrób zdjęcie (bottom-right)
            if (_mode == ScannerMode.productPhoto)
              Positioned(
                bottom: 16,
                right: 16,
                child: _isAiMode
                    ? GestureDetector(
                        onTap: _captureProductPhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                color: isDark
                                    ? AppColors.aiAccentDark
                                    : AppColors.aiAccentLight,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  children: [
                                    const TextSpan(text: 'Zrób zdjęcie '),
                                    TextSpan(
                                      text: 'nazwy',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.aiAccentDark
                                            : AppColors.aiAccentLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildControlButton(
                        icon: LucideIcons.camera,
                        label: 'Zrób zdjęcie',
                        onTap: _captureProductPhoto,
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
    final pieceCount = drug.pieceCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            drug.isFromRpl ? LucideIcons.pill : LucideIcons.box,
            size: 16,
            color: drug.isFromRpl ? theme.colorScheme.primary : Colors.purple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.displayName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Pokaz ilosc sztuk jesli dostepna lub info o OCR
                if (pieceCount != null)
                  Text(
                    '$pieceCount szt.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (!drug.isFromRpl)
                  Text(
                    'OCR',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.purple,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
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
          else if (drug.tempImagePath != null)
            Icon(
              LucideIcons.imagePlus,
              size: 16,
              color: theme.colorScheme.primary,
            )
          else
            Icon(LucideIcons.circleAlert, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildFinishButton(ThemeData theme, bool isDark) {
    final aiColor = isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

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
                Icon(LucideIcons.sparkles, color: aiColor),
                const SizedBox(width: 8),
                Text(
                  'Zakończ i przetwórz (${_scannedDrugs.length})',
                  style: TextStyle(color: aiColor, fontWeight: FontWeight.w600),
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
        // Probuj sparsowac jako GS1 Data Matrix (QR/2D)
        final gs1Data = Gs1Parser.parse(code);
        if (gs1Data != null && gs1Data.isValid) {
          // Kod 2D z EAN (i potencjalnie data waznosci)
          await _processGs1(gs1Data);
        } else {
          // Zwykly kod EAN-13/EAN-8
          await _processEan(code);
        }
      }
      // W trybie daty nie uzywamy skanera kodow - uzywamy OCR zdjecia
      break;
    }
  }

  /// Przetwarza kod GS1 Data Matrix (QR/2D) z wbudowana data waznosci
  Future<void> _processGs1(Gs1Data gs1Data) async {
    final ean = gs1Data.ean!;

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
        _showError(
          'Nie znaleziono leku w bazie RPL.\nKod: $ean\nMozesz dodac lek reczenie.',
        );
        return;
      }

      // Sukces - haptic feedback
      HapticFeedback.mediumImpact();

      final drug = ScannedDrug(
        ean: ean,
        drugInfo: drugInfo,
        expiryDate: gs1Data.expiryDate, // Data z kodu 2D!
      );
      _scannedEans.add(ean);

      // Komunikat z nazwa, iloscia sztuk i data
      String message = drugInfo.fullName;
      if (drug.pieceCount != null) {
        message += '\n${drug.pieceCount} szt.';
      }
      if (gs1Data.hasExpiryDate) {
        message += '\n📅 ${_formatDate(gs1Data.expiryDate!)}';
      }

      setState(() {
        _showSuccess = true;
        _successMessage = message;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      setState(() {
        _showSuccess = false;
        _successMessage = null;
      });

      // Jesli mamy date z kodu - POMINIJ krok zdjecia!
      if (gs1Data.hasExpiryDate) {
        _scannedDrugs.add(drug);
        // Zostajemy w trybie EAN - gotowi na kolejny kod
        setState(() {});
      } else {
        // Brak daty w kodzie - standardowy flow ze zdjeciem
        setState(() {
          _currentDrug = drug;
          _mode = ScannerMode.expiryDate;
        });
      }
    } on RplException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Błąd: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
        // Produkt nie znaleziony w RPL - pokaz czerwony overlay i dialog
        HapticFeedback.heavyImpact();
        _scannedEans.add(ean);

        setState(() {
          _currentDrug = ScannedDrug(ean: ean);
          _showNotRecognized = true;
          _isProcessing = false;
        });

        // Pokaz czerwony overlay przez chwile
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        setState(() => _showNotRecognized = false);

        // Pokaz dialog wyboru
        _showCodeNotRecognizedDialog(ean);
        return;
      }

      // Sukces - haptic feedback
      HapticFeedback.mediumImpact();

      final drug = ScannedDrug(ean: ean, drugInfo: drugInfo);
      _scannedEans.add(ean);

      // Komunikat z nazwa i iloscia sztuk
      String message = drugInfo.fullName;
      if (drug.pieceCount != null) {
        message += '\n${drug.pieceCount} szt.';
      }

      setState(() {
        _currentDrug = drug;
        _showSuccess = true;
        _successMessage = message;
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
      _showError('Błąd: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Pokazuje dialog wyboru gdy kod nie zostal rozpoznany
  void _showCodeNotRecognizedDialog(String ean) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final aiColor =
            isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight;

        return AlertDialog(
          icon: const Icon(
            LucideIcons.circleAlert,
            color: Colors.red,
            size: 48,
          ),
          title: const Text('Nie rozpoznano kodu'),
          content: Text(
            'Nie znaleziono leku w bazie RPL.\n\nCo chcesz zrobić?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            // Opcja 1: Skanuj ponownie
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Usun kod z zestawu, zeby moc skanowac ponownie
                setState(() {
                  _scannedEans.remove(ean);
                  _currentDrug = null;
                  _mode = ScannerMode.ean;
                  _isAiMode = false;
                });
              },
              icon: const Icon(LucideIcons.scanBarcode),
              label: const Text('Zeskanuj kod jeszcze raz'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            // Opcja 2: AI rozpoznawanie
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _mode = ScannerMode.productPhoto;
                  _isAiMode = true;
                });
              },
              icon: Icon(LucideIcons.sparkles, color: aiColor),
              label: Text(
                'Pozwól AI rozpoznać lek',
                style: TextStyle(color: aiColor),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: aiColor.withAlpha(40),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  /// Robi snapshot z widoku kamery (bez opuszczania UI)
  Future<File?> _takeSnapshot() async {
    try {
      final boundary =
          _scannerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Przechwytujemy klatke z wysokim pixelRatio dla lepszej jakosci OCR
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Zapisz do pliku tymczasowego
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/snapshot_$timestamp.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      _showError('Błąd zdjęcia: $e');
      return null;
    }
  }

  /// Robi snapshot daty waznosci (batch mode - OCR pozniej)
  Future<void> _captureExpiryDatePhoto() async {
    if (_currentDrug == null) return;

    // Snapshot z widoku kamery (bez opuszczania UI)
    final snapshotFile = await _takeSnapshot();

    if (snapshotFile != null) {
      // Zapisz sciezke do snapshotu - OCR zostanie wykonany przy zakonczeniu
      _currentDrug!.tempImagePath = snapshotFile.path;
      HapticFeedback.mediumImpact();

      // Animacja "Zapisano"
      setState(() {
        _showSuccess = true;
        _successMessage = 'Zapisano zdjecie';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() {
        _showSuccess = false;
        _successMessage = null;
      });
    }

    // Od razu wracamy do skanowania EAN (batch mode)
    _finishCurrentDrug();
  }

  /// Robi snapshot nazwy produktu (batch mode - OCR pozniej)
  Future<void> _captureProductPhoto() async {
    if (_currentDrug == null) return;

    // Snapshot z widoku kamery
    final snapshotFile = await _takeSnapshot();

    if (snapshotFile != null) {
      // Zapisz sciezke do snapshotu nazwy - OCR zostanie wykonany przy zakonczeniu
      _currentDrug!.tempProductImagePath = snapshotFile.path;
      HapticFeedback.mediumImpact();

      // Animacja "Zapisano"
      setState(() {
        _showSuccess = true;
        _successMessage = 'Zapisano zdjecie nazwy';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() {
        _showSuccess = false;
        _successMessage = null;
      });
    }

    // Przejdz do zdjecia daty waznosci
    setState(() => _mode = ScannerMode.expiryDate);
  }

  /// Wymusza przejście do trybu zdjęcia nazwy gdy kod jest nieczytelny
  Future<void> _skipBarcodeScan() async {
    // Generuj unikalny manual EAN
    final manualEan = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';

    // Pokaz ten sam czerwony overlay i dialog co dla nierozpoznanego kodu
    HapticFeedback.heavyImpact();
    _scannedEans.add(manualEan);

    setState(() {
      _currentDrug = ScannedDrug(ean: manualEan);
      _showNotRecognized = true;
      _lastError = null;
    });

    // Pokaz czerwony overlay przez chwile
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => _showNotRecognized = false);

    // Pokaz dialog wyboru
    _showCodeNotRecognizedDialog(manualEan);
  }

  /// Pomija zdjecie nazwy produktu (batch mode)
  void _skipProductPhoto() {
    if (_currentDrug == null) return;
    // Przejdz do zdjecia daty waznosci (bez snapu nazwy)
    setState(() => _mode = ScannerMode.expiryDate);
  }

  //   void _showManualDateInput() {
  //     final controller = TextEditingController();

  //     showModalBottomSheet(
  //       context: context,
  //       isScrollControlled: true,
  //       builder: (context) => Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(context).viewInsets.bottom,
  //           left: 24,
  //           right: 24,
  //           top: 24,
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Text(
  //               'Wprowadź datę ważności',
  //               style: Theme.of(context).textTheme.titleLarge,
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               _currentDrug?.displayName ?? '',
  //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                 color: Theme.of(context).colorScheme.onSurfaceVariant,
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: controller,
  //               keyboardType: TextInputType.datetime,
  //               decoration: const InputDecoration(
  //                 labelText: 'Data ważności (MM/YYYY)',
  //                 hintText: '03/2027',
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(LucideIcons.calendar),
  //               ),
  //               autofocus: true,
  //             ),
  //             const SizedBox(height: 16),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton(
  //                     onPressed: () {
  //                       Navigator.pop(context);
  //                       _skipExpiryDate();
  //                     },
  //                     child: const Text('Pomiń'),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: FilledButton(
  //                     onPressed: () {
  //                       final date = _parseManualDate(controller.text);
  //                       if (date != null) {
  //                         _currentDrug!.expiryDate = date;
  //                         Navigator.pop(context);
  //                         _finishCurrentDrug();
  //                       }
  //                     },
  //                     child: const Text('Zapisz'),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 24),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   String? _parseManualDate(String input) {
  //     // Format: MM/YYYY lub MM-YYYY lub MMYYYY
  //     final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
  //     if (cleaned.length < 6) return null;

  //     final month = int.tryParse(cleaned.substring(0, 2));
  //     final year = int.tryParse(cleaned.substring(2, 6));

  //     if (month == null || year == null) return null;
  //     if (month < 1 || month > 12) return null;
  //     if (year < 2020 || year > 2050) return null;

  //     // Zwroc ostatni dzien miesiaca w formacie ISO
  //     final lastDay = DateTime(year, month + 1, 0).day;
  //     return '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
  //   }

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
      _isAiMode = false; // Reset trybu AI
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
