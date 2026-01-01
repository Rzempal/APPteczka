import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/rpl_service.dart';
import '../theme/app_theme.dart';
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
    _controller.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 3) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await _rplService.searchMedicine(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

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
          Row(
            children: [
              Expanded(
                child: NeuTextField(
                  controller: _controller,
                  hintText: 'Wpisz nazwę leku...',
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 12),
              NeuIconButton(
                icon: _isLoading ? LucideIcons.loader : LucideIcons.search,
                onPressed: _isLoading ? null : _search,
                size: 48,
              ),
            ],
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
