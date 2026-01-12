// rpl_autocomplete.dart - Autocomplete dla wyszukiwania leków w RPL
// Widget z debounce i dropdown z wynikami

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/rpl_service.dart';
import '../theme/app_theme.dart';

/// Callback po wybraniu leku z RPL
typedef OnRplSelected = void Function(RplSearchResult result);

/// Widget autocomplete do wyszukiwania leków w Rejestrze Produktów Leczniczych
class RplAutocomplete extends StatefulWidget {
  /// Kontroler tekstu (opcjonalny - tworzony wewnętrznie jeśli nie podany)
  final TextEditingController? controller;

  /// Callback po wybraniu leku z listy
  final OnRplSelected? onSelected;

  /// Callback po zmianie tekstu (dla fallback do AI)
  final ValueChanged<String>? onTextChanged;

  /// Etykieta pola
  final String labelText;

  /// Placeholder
  final String hintText;

  /// Walidator
  final String? Function(String?)? validator;

  /// Czy pole jest aktywne
  final bool enabled;

  const RplAutocomplete({
    super.key,
    this.controller,
    this.onSelected,
    this.onTextChanged,
    this.labelText = 'Nazwa leku',
    this.hintText = 'np. Paracetamol',
    this.validator,
    this.enabled = true,
  });

  @override
  State<RplAutocomplete> createState() => _RplAutocompleteState();
}

class _RplAutocompleteState extends State<RplAutocomplete> {
  late TextEditingController _controller;
  final RplService _rplService = RplService();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  List<RplSearchResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _isSelecting =
      false; // Flaga zapobiegająca ponownemu wyszukiwaniu po wyborze

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Opóźnij usunięcie overlay, żeby kliknięcie na wynik zadziałało
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return;

    final text = _controller.text.trim();
    widget.onTextChanged?.call(text);

    // Debounce - czekaj 300ms przed wyszukiwaniem
    _debounce?.cancel();
    if (text.length >= 3) {
      setState(() => _isLoading = true);
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _searchMedicines(text);
      });
    } else {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      _removeOverlay();
    }
  }

  Future<void> _searchMedicines(String query) async {
    try {
      final results = await _rplService.searchMedicine(query);
      if (mounted && _controller.text.trim() == query) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
        if (results.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return _buildResultTile(result);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile(RplSearchResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _selectResult(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.pill,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.displaySubtitle.isNotEmpty)
                    Text(
                      result.displaySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.circleCheck,
              size: 18,
              color: isDark ? AppColors.aiAccentDark : AppColors.aiAccentLight,
            ),
          ],
        ),
      ),
    );
  }

  void _selectResult(RplSearchResult result) {
    _isSelecting = true;
    _controller.text = result.displayLabel;
    _removeOverlay();
    setState(() => _results = []);
    widget.onSelected?.call(result);
    // Reset flagi po krótkim opóźnieniu
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(LucideIcons.pill),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _controller.clear();
                    _removeOverlay();
                    setState(() => _results = []);
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          helperText: 'Wpisz min. 3 znaki, aby wyszukać w RPL',
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
