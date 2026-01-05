import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';

/// Karta leku - styl neumorficzny z animacjami tap
/// Obsługuje Light/Dark mode z gradientami statusu
class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final List<UserLabel> labels;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final bool isCompact;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.labels = const [],
    this.onTap,
    this.onExpand,
    this.isCompact = false,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: NeuDecoration.tapDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: NeuDecoration.tapScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = widget.medicine.expiryStatus;
    final gradient = _getGradient(status, isDark);
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final statusIcon = _getStatusIcon(status);

    // Pobierz etykiety dla tego leku
    final medicineLabels = widget.labels
        .where((l) => widget.medicine.labels.contains(l.id))
        .toList();

    // Dla isCompact=false z onExpand, nagłówek rozwija/zwija akordeon,
    // reszta karty otwiera szczegóły
    final bool useSplitTouchAreas =
        !widget.isCompact && widget.onExpand != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        // Główny GestureDetector obsługuje całą kartę gdy nie ma split touch
        onTapDown: useSplitTouchAreas ? null : _handleTapDown,
        onTapUp: useSplitTouchAreas ? null : _handleTapUp,
        onTapCancel: useSplitTouchAreas ? null : _handleTapCancel,
        onTap: useSplitTouchAreas ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: AnimatedContainer(
            duration: NeuDecoration.tapDuration,
            decoration: _isPressed
                ? _getPressedDecoration(isDark, gradient, statusColor)
                : NeuDecoration.statusCard(
                    isDark: isDark,
                    gradient: gradient,
                    radius: 20,
                  ),
            child: Padding(
              padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek: [Nazwa + Etykiety] align left | [Badge] align right
                  // W trybie split touch - cały nagłówek reaguje na onExpand
                  GestureDetector(
                    behavior: useSplitTouchAreas
                        ? HitTestBehavior.opaque
                        : HitTestBehavior.deferToChild,
                    onTap: useSplitTouchAreas ? widget.onExpand : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lewa strona: Nazwa + Etykiety (wrap to 2 lines if needed)
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Nazwa leku
                              Text(
                                widget.medicine.nazwa ?? 'Nieznany lek',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: widget.isCompact ? 15 : null,
                                ),
                              ),
                              // Etykiety
                              ...medicineLabels
                                  .take(3)
                                  .map((label) => _buildBadge(label, isDark)),
                              if (medicineLabels.length > 3)
                                _buildBadgeCount(
                                  medicineLabels.length - 3,
                                  isDark,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Prawa strona: Status badge (tylko w trybie full) lub Chevron (w compact)
                        if (widget.isCompact)
                          // Strzałka rozwijania akordeonu
                          GestureDetector(
                            onTap: widget.onExpand,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: NeuDecoration.flatSmall(
                                isDark: isDark,
                                radius: 12,
                              ),
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        else if (widget.onExpand != null)
                          // Strzałka zwijania akordeonu (gdy karta rozwinięta)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: NeuDecoration.flatSmall(
                              isDark: isDark,
                              radius: 12,
                            ),
                            child: Icon(
                              LucideIcons.chevronUp,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else if (statusLabel != null)
                          // Badge statusu tylko gdy brak onExpand (tryb full globalny)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Compact: opis (left) + status icon (right) - bez daty
                  if (widget.isCompact) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Opis z fade-out po prawej
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.85, 1.0],
                            ).createShader(bounds),
                            blendMode: BlendMode.dstIn,
                            child: Text(
                              widget.medicine.opis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        // Status icon (zamiast daty)
                        if (statusLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    // Full view - reszta karty reaguje na onTap (detail sheet)
                    GestureDetector(
                      behavior: useSplitTouchAreas
                          ? HitTestBehavior.opaque
                          : HitTestBehavior.deferToChild,
                      onTap: useSplitTouchAreas ? widget.onTap : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Opis
                          SelectableText(
                            widget.medicine.opis,
                            maxLines: 2,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // #tags - styl neumorficzny
                          if (widget.medicine.tagi.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.medicine.tagi.take(4).map((tag) {
                                return _buildTag(tag, isDark, theme);
                              }).toList(),
                            ),

                          // Notatka jeśli istnieje - styl neumorficzny basin
                          if (widget.medicine.notatka != null &&
                              widget.medicine.notatka!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: NeuDecoration.basin(
                                isDark: isDark,
                                radius: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.stickyNote,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      widget.medicine.notatka!,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Data ważności (bez zdublowanego Badge statusu)
                          if (widget.medicine.terminWaznosci != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ważny do: ${_formatDate(widget.medicine.terminWaznosci!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dekoracja dla stanu pressed - subtelniejsze cienie
  /// Dekoracja dla stanu pressed - skalowanie załatwia sprawę,
  /// ale możemy zmniejszyć cień.
  BoxDecoration _getPressedDecoration(
    bool isDark,
    LinearGradient gradient,
    Color statusColor,
  ) {
    // W stanie pressed używamy po prostu statusCard ale z mniejszymi cieniami
    // (symulowanymi przz NeuDecoration.statusCard parametry? Nie mamy ich tam).
    // Więc zwracamy to samo, ale scaleAnimation zrobi robotę.
    // Ewentualnie możemy zwrócić "płaską" wersję bez cienia.

    // Używamy helpera z NeuDecoration.statusCard ale modyfikujemy shadow ręcznie
    // dla efektu "wciśnięcia" (mniejszy blur/distance)

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      // Brak cienia lub szczątkowy cień "inner" (trudne na gradiencie)
      // Zostawiamy czyste, scale załatwia wizualny feedback
      boxShadow: [],
    );
  }

  /// Badge etykiety - kolorowe tło z białym tekstem
  Widget _buildBadge(UserLabel label, bool isDark) {
    final colorInfo = labelColors[label.color]!;
    final bgColor = Color(colorInfo.hexValue);

    // Określ kolor tekstu na podstawie jasności tła
    final textColor = _getContrastColor(bgColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Badge count indicator when more than 2 labels
  Widget _buildBadgeCount(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFe5e7eb),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF374151),
        ),
      ),
    );
  }

  /// Tag - prosty Badge (transparent bg, gray outline, # inny kolor)
  Widget _buildTag(String tag, bool isDark, ThemeData theme) {
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '#',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: borderColor,
              ),
            ),
            TextSpan(
              text: tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zwraca kontrastowy kolor tekstu dla danego tła
  Color _getContrastColor(Color background) {
    // Oblicz jasność tła
    final luminance = background.computeLuminance();
    // Dla jasnych kolorów (yellow, orange) użyj ciemnego tekstu
    return luminance > 0.5 ? const Color(0xFF1e293b) : Colors.white;
  }

  LinearGradient _getGradient(ExpiryStatus status, bool isDark) {
    switch (status) {
      case ExpiryStatus.expired:
        return isDark
            ? AppColors.darkGradientExpired
            : AppColors.lightGradientExpired;
      case ExpiryStatus.expiringSoon:
        // Dark mode: neutralne tło (jak valid) - tylko expired ma czerwone
        return isDark
            ? AppColors.darkGradientValid
            : const LinearGradient(
                colors: [Color(0xFFe0e8e4), Color(0xFFe0e8e4)],
              );
      case ExpiryStatus.valid:
        return isDark
            ? AppColors.darkGradientValid
            : const LinearGradient(
                colors: [Color(0xFFe0e8e4), Color(0xFFe0e8e4)],
              );
      case ExpiryStatus.unknown:
        // Neutral gradient - light gray
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1e293b), const Color(0xFF334155)]
              : [const Color(0xFFe0e8e4), const Color(0xFFe0e8e4)],
        );
    }
  }

  Color _getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return AppColors.expired;
      case ExpiryStatus.expiringSoon:
        return AppColors.expiringSoon;
      case ExpiryStatus.valid:
        return AppColors.valid;
      case ExpiryStatus.unknown:
        return const Color(0xFF6b7280);
    }
  }

  String? _getStatusLabel(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'Przeterminowany';
      case ExpiryStatus.expiringSoon:
        return 'Kończy się';
      case ExpiryStatus.valid:
        return 'Ważny';
      case ExpiryStatus.unknown:
        return null;
    }
  }

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return LucideIcons.circleX;
      case ExpiryStatus.expiringSoon:
        return LucideIcons.triangleAlert;
      case ExpiryStatus.valid:
        return LucideIcons.circleCheck;
      case ExpiryStatus.unknown:
        return LucideIcons.circleOff;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
