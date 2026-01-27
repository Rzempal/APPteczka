import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/rpl_service.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'neumorphic/neumorphic.dart';

/// Bottom sheet do wyszukiwania ulotek w Rejestrze Produktów Leczniczych
class LeafletSearchSheet extends StatefulWidget {
  final String initialQuery;
  final Function(String url) onLeafletSelected;

  const LeafletSearchSheet({
    super.key,
    required this.initialQuery,
    required this.onLeafletSelected,
  });

  @override
  State<LeafletSearchSheet> createState() => _LeafletSearchSheetState();
}

class _LeafletSearchSheetState extends State<LeafletSearchSheet> {
  final RplService _rplService = RplService();
  final TextEditingController _controller = TextEditingController();

  List<RplSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Proste czyszczenie zapytania: bierzemy tylko pierwsze słowo (nazwę leku)
    // jeśli pełna nazwa jest długa (np. "Apap 500mg table...")
    final sanitized = _sanitizeQuery(widget.initialQuery);
    _controller.text = sanitized;

    if (sanitized.length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search();
      });
    }
  }

  String _sanitizeQuery(String raw) {
    if (raw.isEmpty) return '';

    // 1. Usuń dawki (cyfry + mg/g/ml) - prymitywny regex
    // Ale prościej: weź po prostu pierwsze słowo, to zazwyczaj działa najlepiej w RPL
    // RPL ma problem jak dostanie "Apap Extra", a lek nazywa się "Apap" (lub odwrotnie)
    // Najbezpieczniej szukać po pierwszym członie.

    final parts = raw.split(' ');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return raw.trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 3) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = []; // Clear previous results
    });

    try {
      final results = await _rplService.searchMedicine(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BottomSheetConstants.radius),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BottomSheetConstants.contentPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          const BottomSheetDragHandle(),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Szukaj w bazie MZ:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              NeuIconButton(
                icon: LucideIcons.x,
                size: 32,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          NeuSearchField(
            controller: _controller,
            hintText: 'Wpisz nazwę leku...',
            onChanged: (_) {
              // Optional: auto-search on text change if desired
            },
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),

          // Results or messages
          Flexible(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSearched) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Wpisz co najmniej 3 znaki i wciśnij szukaj',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nie znaleziono - spróbuj inną nazwę lub tylko pierwsze słowo.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uwaga: suplementy diety nie są w Rejestrze Produktów Leczniczych.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultItem(context, result);
      },
    );
  }

  Widget _buildResultItem(BuildContext context, RplSearchResult result) {
    return NeuButton(
      onPressed: () {
        widget.onLeafletSelected(result.ulotkaUrl);
        Navigator.pop(context);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: result.nazwa,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text:
                        ' (${result.moc}${result.postac.isNotEmpty ? ', ${result.postac}' : ''})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}
