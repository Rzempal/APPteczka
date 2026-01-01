import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic/neumorphic.dart';

/// Pełnoekranowy viewer PDF z opcjami
class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String medicineId;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.medicineId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfCacheService _cacheService = PdfCacheService();

  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;

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

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = await _cacheService.getPdfFile(
        widget.url,
        widget.medicineId,
      );

      if (file != null && await file.exists()) {
        final document = await PdfDocument.openFile(file.path);
        if (mounted) {
          setState(() {
            _pdfController = PdfControllerPinch(
              document: Future.value(document),
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Nie można pobrać ulotki. Sprawdź połączenie z internetem.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Błąd wczytywania PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
            Text('Ładowanie ulotki...'),
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
