import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Neumorphic text field with basin (concave/inset) style
///
/// Features:
/// - Sunken appearance simulating pressed/input area (Soft UI 2026)
/// - Optional prefix and suffix icons
/// - Focus state with accent color border
/// - Support for organic border radius
class NeuTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final BorderRadius? borderRadius; // Organic radius support
  final double radius; // Fallback to circular
  final EdgeInsetsGeometry contentPadding;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const NeuTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.borderRadius, // Optional organic radius
    this.radius = 16, // Design spec: 16px for inputs
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    this.focusNode,
    this.validator,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }

    _controller.removeListener(_onTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.labelText!.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(widget.radius),
            border: Border.all(
              color: _isFocused
                  ? (isDark
                        ? AppColors.accentDark
                        : AppColors.accent) // Use accent color
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: [
              // Focus glow effect
              if (_isFocused)
                BoxShadow(
                  color: (isDark ? AppColors.accentDark : AppColors.accent)
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              // Inner shadow (basin/inset effect) - dark
              BoxShadow(
                color: isDark
                    ? AppColors.darkShadowDark.withValues(alpha: 0.6)
                    : AppColors.lightShadowDark.withValues(alpha: 0.4),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              // Inner shadow (basin/inset effect) - light highlight
              BoxShadow(
                color: isDark
                    ? AppColors.darkShadowLight.withValues(alpha: 0.05)
                    : AppColors.lightShadowLight.withValues(alpha: 0.7),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              filled: false,
              prefixIcon: widget.prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: _isFocused
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      child: widget.prefixIcon!,
                    )
                  : null,
              suffixIcon: _hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                      },
                    )
                  : widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: widget.contentPadding,
            ),
          ),
        ),
      ],
    );
  }
}

/// Neumorphic search field variant
/// Pre-configured with search icon and pills shape
class NeuSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const NeuSearchField({
    super.key,
    this.controller,
    this.hintText = 'Szukaj...',
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<NeuSearchField> createState() => _NeuSearchFieldState();
}

class _NeuSearchFieldState extends State<NeuSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChange);
    _hasText = _controller.text.isNotEmpty;

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }

    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onFocusChange() {
    // Focus change handled by NeuTextField internally
  }

  @override
  Widget build(BuildContext context) {
    return NeuTextField(
      controller: _controller,
      focusNode: _focusNode,
      hintText: widget.hintText,
      radius: 50, // Pills shape
      prefixIcon: Icon(LucideIcons.packageSearch),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}
