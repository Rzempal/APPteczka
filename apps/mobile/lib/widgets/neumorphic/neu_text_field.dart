import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'neu_decoration.dart';

/// Neumorphic text field with basin (concave) style
///
/// Features:
/// - Sunken appearance simulating pressed/input area
/// - Optional prefix and suffix icons
/// - Focus state with primary color border
class NeuTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final double borderRadius;
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
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.borderRadius = 12,
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
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
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
              widget.labelText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration:
              NeuDecoration.basin(
                isDark: isDark,
                radius: widget.borderRadius,
              ).copyWith(
                border: Border.all(
                  color: _isFocused
                      ? AppColors.primary.withOpacity(0.6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
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
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
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
/// Pre-configured with search icon and clear button
class NeuSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const NeuSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Szukaj...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icon(
        Icons.search,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
      ),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              onPressed: () {
                controller.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
    );
  }
}
