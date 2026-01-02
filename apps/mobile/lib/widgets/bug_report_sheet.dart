import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/bug_report_service.dart';

/// Bottom sheet do zgłaszania błędów
class BugReportSheet extends StatefulWidget {
  final String? errorMessage;
  final Uint8List? screenshot;

  const BugReportSheet({
    super.key,
    this.errorMessage,
    this.screenshot,
  });

  /// Pokazuje sheet do zgłaszania błędu
  static Future<void> show(
    BuildContext context, {
    String? error,
    Uint8List? screenshot,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BugReportSheet(
        errorMessage: error,
        screenshot: screenshot,
      ),
    );
  }

  @override
  State<BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<BugReportSheet> {
  final _textController = TextEditingController();
  bool _includeLogs = true;
  bool _includeScreenshot = true;
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    setState(() => _isSending = true);

    final result = await BugReportService.instance.sendReport(
      text: _textController.text.trim(),
      errorMessage: widget.errorMessage,
      includeLogs: _includeLogs,
      screenshot: _includeScreenshot ? widget.screenshot : null,
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
        backgroundColor:
            result.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.bug,
                      color: theme.colorScheme.onErrorContainer,
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

              // Error message preview
              if (widget.errorMessage != null) ...[
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
                const SizedBox(height: 16),
              ],

              // Description field
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Opisz problem (opcjonalnie)',
                  hintText: 'Co robiłeś gdy wystąpił błąd?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              // Checkboxes
              CheckboxListTile(
                value: _includeLogs,
                onChanged: (v) => setState(() => _includeLogs = v ?? true),
                title: const Text('Dołącz logi aplikacji'),
                subtitle: const Text('Informacje techniczne o błędzie'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              if (widget.screenshot != null)
                CheckboxListTile(
                  value: _includeScreenshot,
                  onChanged: (v) =>
                      setState(() => _includeScreenshot = v ?? true),
                  title: const Text('Dołącz screenshot'),
                  subtitle: const Text('Zrzut ekranu z momentu błędu'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 20),

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
                'Raport zostanie wysłany anonimowo do zespołu deweloperskiego.',
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
