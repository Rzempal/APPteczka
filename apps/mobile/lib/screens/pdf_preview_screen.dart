import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic/neumorphic.dart';

/// Ekran podglądu wygenerowanego pliku PDF
class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.pdfFile,
    this.title = 'Podgląd PDF',
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;

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
    // Krótkie opóźnienie dla płynności animacji wejścia
    await Future.delayed(const Duration(milliseconds: 300));

    if (await widget.pdfFile.exists()) {
      if (mounted) {
        setState(() {
          _pdfController = PdfControllerPinch(
            document: PdfDocument.openFile(widget.pdfFile.path),
          );
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd: Plik PDF nie istnieje')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await widget.pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: widget.pdfFile.path.split('/').last,
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
    try {
      final bytes = await widget.pdfFile.readAsBytes();
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Drukuj
          IconButton(
            icon: const Icon(LucideIcons.printer),
            tooltip: 'Drukuj',
            onPressed: _isLoading ? null : _printPdf,
          ),
          // Udostępnij / Pobierz
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'Udostępnij / Pobierz',
            onPressed: _isLoading ? null : _sharePdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfController == null
          ? const Center(child: Text('Nie udało się załadować podglądu'))
          : PdfViewPinch(
              controller: _pdfController!,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) => Center(child: Text('Błąd: $error')),
              ),
            ),
    );
  }
}
