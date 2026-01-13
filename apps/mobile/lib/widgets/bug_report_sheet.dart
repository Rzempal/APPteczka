import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/bug_report_service.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neu_button.dart';

/// Bottom sheet do zgłaszania błędów z quick actions
class BugReportSheet extends StatefulWidget {
  final String? errorMessage;
  final Uint8List? screenshot;
  final ReportCategory? initialCategory;

  const BugReportSheet({
    super.key,
    this.errorMessage,
    this.screenshot,
    this.initialCategory,
  });

  /// Pokazuje sheet do zgłaszania błędu
  static Future<void> show(
    BuildContext context, {
    String? error,
    Uint8List? screenshot,
    ReportCategory? category,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BugReportSheet(
        errorMessage: error,
        screenshot: screenshot,
        initialCategory: category,
      ),
    );
  }

  @override
  State<BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<BugReportSheet> {
  final _textController = TextEditingController();
  final _emailController = TextEditingController();
  final _topicController = TextEditingController();
  ReportCategory _selectedCategory = ReportCategory.bug;
  bool _includeLogs = true;
  bool _includeScreenshot = true;
  bool _isSending = false;
  final List<Uint8List> _attachedImages =
      []; // Lista obrazów (screenshot + galeria)
  String _appVersion = ''; // Wersja aplikacji

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? ReportCategory.bug;
    // Pobierz wersję aplikacji
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await BugReportService.instance.getAppVersion();
    if (mounted) setState(() => _appVersion = version);
  }

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  String get _hintText {
    switch (_selectedCategory) {
      case ReportCategory.bug:
        return 'Co robiłeś gdy wystąpił błąd?';
      case ReportCategory.suggestion:
        return 'Opisz swój pomysł...';
      case ReportCategory.question:
        return 'Czego nie rozumiesz?';
    }
  }

  /// Wybór obrazu z galerii urządzenia
  Future<void> _pickFromGallery() async {
    if (_attachedImages.length >= 5) {
      _showLimitError();
      return;
    }

    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          if (_attachedImages.length < 5) {
            final bytes = await image.readAsBytes();
            setState(() {
              _attachedImages.add(bytes);
            });
          }
        }
      }
    } catch (e) {
      BugReportService.instance.log('Gallery pick error: $e');
    }
  }

  void _showLimitError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Możesz dodać maksymalnie 5 zdjęć.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendReport() async {
    if (_textController.text.trim().isEmpty &&
        _topicController.text.trim().isEmpty &&
        _attachedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dodaj opis lub zdjęcie, aby wysłać raport.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final result = await BugReportService.instance.sendReport(
      text: _textController.text.trim(),
      topic: _topicController.text.trim(),
      errorMessage: widget.errorMessage,
      category: _selectedCategory,
      replyEmail: _selectedCategory == ReportCategory.question
          ? _emailController.text.trim()
          : null,
      includeLogs: _includeLogs,
      screenshots: _includeScreenshot ? _attachedImages : null,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Raport wysłany. Dziękujemy!'
              : 'Błąd: ${result.error}',
        ),
        backgroundColor: result.success
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expired.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.messageCircleWarning,
                      color: AppColors.expired,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zgłoś problem',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pomóż nam ulepszyć aplikację',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_appVersion.isNotEmpty)
                          Text(
                            'Wersja: $_appVersion',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === KATEGORIA ===
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Wybierz kategorię:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ReportCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: category != ReportCategory.values.last ? 8 : 0,
                      ),
                      child: _CategoryChip(
                        category: category,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // === TEMAT ===
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: 'Temat',
                  hintText: 'np. Dodawanie leku, Skanowanie, Etykiety...',
                  prefixIcon: const Icon(LucideIcons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Error message preview
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.circleAlert,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // === OPIS ===
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Opis (opcjonalnie)',
                  hintText: _hintText,
                  prefixIcon: const Icon(LucideIcons.notebookPen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              // Email field (visible only for 'Pytanie' category)
              if (_selectedCategory == ReportCategory.question) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Twój email (opcjonalnie)',
                    hintText: 'Żebyśmy mogli odpowiedzieć',
                    prefixIcon: const Icon(LucideIcons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Screenshot attachment section
              const Divider(height: 24),

              // Attached images preview
              if (_attachedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _attachedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _attachedImages.removeAt(index);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _includeScreenshot,
                      onChanged: (v) =>
                          setState(() => _includeScreenshot = v ?? true),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dołącz ${_attachedImages.length} zdj${_attachedImages.length == 1
                            ? 'ęcie'
                            : _attachedImages.length < 5
                            ? 'ęcia'
                            : 'ęć'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // CTA buttons for adding images
              if (_attachedImages.length < 5)
                Row(
                  children: [
                    if (widget.screenshot != null)
                      Expanded(
                        child: NeuButton(
                          icon: LucideIcons.crop,
                          label: 'Screenshot',
                          onPressed: () {
                            setState(() {
                              _attachedImages.insert(0, widget.screenshot!);
                            });
                          },
                        ),
                      ),
                    if (widget.screenshot != null) const SizedBox(width: 8),
                    Expanded(
                      child: NeuButton(
                        icon: LucideIcons.image,
                        label: 'Z galerii',
                        onPressed: _pickFromGallery,
                      ),
                    ),
                  ],
                ),

              // Logs section
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    LucideIcons.fileCode,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Checkbox(
                    value: _includeLogs,
                    onChanged: (v) => setState(() => _includeLogs = v ?? true),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dołącz logi aplikacji'),
                        Text(
                          'Informacje techniczne',
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

              // Send button
              FilledButton.icon(
                onPressed: _isSending ? null : _sendReport,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.send),
                label: Text(_isSending ? 'Wysyłanie...' : 'Wyślij raport'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 8),

              // Privacy note
              Text(
                'Raport zostanie wysłany anonimowo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip do wyboru kategorii
class _CategoryChip extends StatelessWidget {
  final ReportCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              category.icon,
              size: 24,
              color: isSelected
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              category.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
