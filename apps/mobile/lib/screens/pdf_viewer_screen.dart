import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic/neumorphic.dart';

/// Uniwersalny viewer PDF:
/// - Obsługuje ulotki (URL) - z cache'owaniem
/// - Obsługuje eksport (File) - z opcjami zapisu/druku/udostępniania
class PdfViewerScreen extends StatefulWidget {
  final String? url;
  final File? file;
  final String title;
  final String? medicineId;

  const PdfViewerScreen({
    super.key,
    this.url,
    this.file,
    required this.title,
    this.medicineId,
  }) : assert(url != null || file != null, 'URL or File must be provided');

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfCacheService _cacheService = PdfCacheService();

  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  File? _currentFile;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  /// Ładuje PDF z pliku lub URL
  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.file != null) {
        // Tryb lokalny (Eksport)
        _currentFile = widget.file;
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // Animacja wejścia
      } else if (widget.url != null && widget.medicineId != null) {
        // Tryb zdalny (Ulotka)
        _currentFile = await _cacheService.getPdfFile(
          widget.url!,
          widget.medicineId!,
        );
      }

      if (_currentFile != null && await _currentFile!.exists()) {
        final document = await PdfDocument.openFile(_currentFile!.path);
        if (mounted) {
          setState(() {
            _pdfController = PdfControllerPinch(
              document: Future.value(document),
            );
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Nie udało się załadować pliku PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.file != null
              ? 'Błąd odczytu pliku: $e'
              : 'Nie można pobrać ulotki. Sprawdź połączenie z internetem.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    if (widget.url != null) {
      final uri = Uri.parse(widget.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Zapisuje plik we wskazanej lokalizacji (Download)
  Future<void> _savePdf() async {
    if (_currentFile == null) return;

    try {
      // Wybór folderu przez użytkownika
      String? outputDir = await FilePicker.platform.getDirectoryPath();

      if (outputDir != null) {
        final fileName = _currentFile!.path.split('/').last;
        final newPath = '$outputDir/$fileName';

        await _currentFile!.copy(newPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zapisano w: $outputDir'),
              backgroundColor: Colors.green, // Sukces
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisu: $e'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_currentFile == null) return;

    try {
      final bytes = await _currentFile!.readAsBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: _currentFile!.path.split('/').last,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd udostępniania: $e'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_currentFile == null) return;

    try {
      final bytes = await _currentFile!.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: widget.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd drukowania: $e'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocalFile = widget.file != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: isLocalFile
              ? const Icon(LucideIcons.arrowLeft)
              : const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        actions: isLocalFile
            ? [
                // Tryb Eksportu: Zapisz, Drukuj, Udostępnij
                IconButton(
                  icon: const Icon(LucideIcons.download),
                  tooltip: 'Zapisz',
                  onPressed: _isLoading ? null : _savePdf,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.printer),
                  tooltip: 'Drukuj',
                  onPressed: _isLoading ? null : _printPdf,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2),
                  tooltip: 'Udostępnij',
                  onPressed: _isLoading ? null : _sharePdf,
                ),
              ]
            : [
                // Tryb Ulotki: Otwórz w przeglądarce
                IconButton(
                  icon: const Icon(LucideIcons.externalLink),
                  tooltip: 'Otwórz w Rejestrze MZ',
                  onPressed: _openInBrowser,
                ),
              ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Wczytywanie dokumentu...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileWarning,
                size: 64,
                color: AppColors.expiringSoon,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (widget.url != null) ...[
                NeuButton(
                  onPressed: _openInBrowser,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.externalLink,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Otwórz w przeglądarce'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: _loadPdf,
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfController != null) {
      return PdfViewPinch(
        controller: _pdfController!,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(child: Text('Błąd: $error')),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
