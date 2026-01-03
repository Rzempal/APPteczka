import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  bool _screenshotAttached = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? ReportCategory.bug;
    // If screenshot is passed, don't auto-attach - user needs to click button
    _screenshotAttached = false;
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

  Future<void> _sendReport() async {
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
      screenshot: (_screenshotAttached && _includeScreenshot)
          ? widget.screenshot
          : null,
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
              if (widget.screenshot != null) ...[
                const Divider(height: 24),
                if (!_screenshotAttached) ...[
                  // Neumorphic button to attach screenshot
                  NeuButton(
                    icon: LucideIcons.crop,
                    label: 'Załącz zrzut aplikacji',
                    isExpanded: true,
                    onPressed: () => setState(() => _screenshotAttached = true),
                  ),
                ] else ...[
                  // Screenshot preview with checkbox (shown after attachment)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          widget.screenshot!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: _includeScreenshot,
                        onChanged: (v) =>
                            setState(() => _includeScreenshot = v ?? true),
                      ),
                      const SizedBox(width: 4),
                      const Text('Dołącz screenshot'),
                    ],
                  ),
                ],
              ],

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
