import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../screens/pdf_viewer_screen.dart';
import 'neumorphic/neumorphic.dart';
import 'label_selector.dart';
import 'leaflet_search_sheet.dart';
import 'filters_sheet.dart' show tagCategories;

/// Karta leku - styl neumorficzny z akordeonem
/// v2.5 - unified button sizing, delete section shadow fix
class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final List<UserLabel> labels;
  final StorageService? storageService;
  final VoidCallback? onExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onTagTap;
  final Function(String)? onLabelTap;
  final VoidCallback? onMedicineUpdated;
  final bool isCompact;
  final bool isDuplicate;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.labels = const [],
    this.storageService,
    this.onExpand,
    this.onEdit,
    this.onDelete,
    this.onTagTap,
    this.onLabelTap,
    this.onMedicineUpdated,
    this.isCompact = false,
    this.isDuplicate = false,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isMoreExpanded = false; // Akordeon "Więcej"
  bool _isLabelsOpen = false;
  late Medicine _medicine;

  // Inline note editing
  bool _isEditingNote = false;
  late TextEditingController _noteController;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
    _controller = AnimationController(
      duration: NeuDecoration.tapDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: NeuDecoration.tapScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _noteController = TextEditingController(text: _medicine.notatka ?? '');
    _noteFocusNode = FocusNode();
    _noteFocusNode.addListener(_onNoteFocusChange);
  }

  @override
  void didUpdateWidget(covariant MedicineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicine.id != widget.medicine.id) {
      _medicine = widget.medicine;
      _noteController.text = _medicine.notatka ?? '';
      _isMoreExpanded = false;
      _isLabelsOpen = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _noteFocusNode.removeListener(_onNoteFocusChange);
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onNoteFocusChange() {
    if (!_noteFocusNode.hasFocus && _isEditingNote) {
      _saveNote();
    }
  }

  Future<void> _saveNote() async {
    final newNote = _noteController.text.trim();
    if (newNote != (_medicine.notatka ?? '')) {
      final updatedMedicine = _medicine.copyWith(
        notatka: newNote.isEmpty ? null : newNote,
      );
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
    setState(() => _isEditingNote = false);
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onExpand != null) {
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

    final status = _medicine.expiryStatus;
    final gradient = _getGradient(status, isDark);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    // Pobierz etykiety dla tego leku
    final medicineLabels = widget.labels
        .where((l) => _medicine.labels.contains(l.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTapDown: widget.isCompact ? _handleTapDown : null,
        onTapUp: widget.isCompact ? _handleTapUp : null,
        onTapCancel: widget.isCompact ? _handleTapCancel : null,
        onTap: widget.isCompact ? widget.onExpand : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final scale = 1.0 - (t * (1.0 - NeuDecoration.tapScale));

            final decoration = widget.isCompact
                ? BoxDecoration.lerp(
                    NeuDecoration.statusCard(
                      isDark: isDark,
                      gradient: gradient,
                      radius: 20,
                    ),
                    _getPressedDecoration(isDark, gradient, statusColor),
                    t,
                  )!
                : NeuDecoration.pressed(isDark: isDark, radius: 20);

            return Transform.scale(
              scale: scale,
              child: Container(decoration: decoration, child: child),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  theme,
                  isDark,
                  medicineLabels,
                  statusColor,
                  statusIcon,
                ),
                if (widget.isCompact)
                  _buildCompactContent(theme, statusColor, statusIcon),
                if (!widget.isCompact)
                  _buildExpandedContent(theme, isDark, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    List<UserLabel> medicineLabels,
    Color statusColor,
    IconData statusIcon,
  ) {
    // W expanded mode - kliknięcie w nagłówek zwija do compact
    return GestureDetector(
      onTap: widget.isCompact ? null : widget.onExpand,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lewa strona: Nazwa + Ikona duplikatu + Etykiety (tylko w compact)
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Nazwa leku - tap zwija kartę, long press kopiuje
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isCompact ? null : widget.onExpand,
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(text: _medicine.nazwa ?? ''),
                    );
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skopiowano nazwę leku'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    _medicine.nazwa ?? 'Nieznany lek',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: widget.isCompact ? 15 : 18,
                    ),
                  ),
                ),
                // Ikona duplikatu
                if (widget.isDuplicate)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      LucideIcons.copy,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                // Etykiety tylko w compact mode
                if (widget.isCompact) ...[
                  ...medicineLabels
                      .take(3)
                      .map((label) => _buildBadge(label, isDark)),
                  if (medicineLabels.length > 3)
                    _buildBadgeCount(medicineLabels.length - 3, isDark),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chevron
          if (widget.isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: theme.colorScheme.onSurface,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
              child: Icon(
                LucideIcons.chevronUp,
                size: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactContent(
    ThemeData theme,
    Color statusColor,
    IconData statusIcon,
  ) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            // Opis z fade-out
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
                  _medicine.opis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Status icon
            if (_medicine.terminWaznosci != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, size: 12, color: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    bool isDark,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // === OPIS ===
        _buildSection(
          theme,
          isDark,
          title: 'Opis',
          onEdit: () => _showEditDescriptionDialog(context),
          child: Text(
            _medicine.opis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        // === WSKAZANIA (z ulotkę w CTA area) ===
        const SizedBox(height: 16),
        _buildWskazaniaSection(context, theme, isDark),

        // === NOTATKA ===
        const SizedBox(height: 16),
        _buildNoteSection(context, theme, isDark),

        // === TERMIN WAŻNOŚCI ===
        const SizedBox(height: 16),
        _buildPackagesSection(context, theme, isDark, statusColor),

        // === KALKULATOR ZAPASU ===
        const SizedBox(height: 16),
        _buildSupplyCalculatorSection(context, theme, isDark),

        // === WIĘCEJ (akordeon) ===
        const SizedBox(height: 16),
        _buildMoreSection(context, theme, isDark),

        // === SEPARATOR PRZED ZWIŃ ===
        const SizedBox(height: 16),
        Divider(color: theme.dividerColor.withValues(alpha: 0.5)),

        // === PRZYCISKI AKCJI ===
        const SizedBox(height: 16),
        _buildActionButtons(context, theme, isDark),
      ],
    );
  }

  // ==================== SEKCJE ====================

  Widget _buildSection(
    ThemeData theme,
    bool isDark, {
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.squarePen,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Combined Wskazania + Ulotka section
  Widget _buildWskazaniaSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final hasLeaflet =
        _medicine.leafletUrl != null && _medicine.leafletUrl!.isNotEmpty;
    final hasWskazania = _medicine.wskazania.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Wskazania',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),

        // Content row: bullet points + edit button (align-right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bullet points (expanded)
            Expanded(
              child: hasWskazania
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _medicine.wskazania
                          .map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $w',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Text(
                      'Brak wskazań',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            // Edit button (align-right)
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditWskazaniaDialog(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.squarePen,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),

        // CTA area: Ulotka + Unpin (aligned right)
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasLeaflet) ...[
              NeuButton(
                onPressed: () => _showPdfViewer(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: AppColors.valid,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pokaż ulotkę',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _detachLeaflet,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.pinOff,
                    size: 20,
                    color: AppColors.expired,
                  ),
                ),
              ),
            ] else
              NeuButton(
                onPressed: () => _showLeafletSearch(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileSearch,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Znajdź ulotkę',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteSection(BuildContext context, ThemeData theme, bool isDark) {
    final hasNote = _medicine.notatka?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notatka',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            if (!_isEditingNote) {
              setState(() {
                _isEditingNote = true;
                _noteController.text = _medicine.notatka ?? '';
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _noteFocusNode.requestFocus();
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.transparent
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isEditingNote
                    ? AppColors.valid
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                width: _isEditingNote ? 2 : 1,
              ),
            ),
            child: _isEditingNote
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          maxLines: null,
                          minLines: 1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Wpisz notatkę...',
                          ),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                          onSubmitted: (_) => _saveNote(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _saveNote,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: NeuDecoration.flatSmall(
                            isDark: isDark,
                            radius: 12,
                          ),
                          child: Icon(
                            LucideIcons.check,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    hasNote ? _medicine.notatka! : 'Kliknij, aby dodać notatkę',
                    style: TextStyle(
                      color: hasNote
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color statusColor,
  ) {
    final packages = _medicine.sortedPackages;
    final packageCount = _medicine.packageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Termin ważności',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (packageCount > 0) ...[
              Text(
                ' - $packageCount op.',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (packages.isEmpty)
          _buildEmptyPackageState(context, theme, isDark)
        else
          ...packages.map((package) {
            final pkgStatus = _getPackageStatus(package);
            final pkgColor = _getStatusColor(pkgStatus);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildPackageRow(
                context,
                theme,
                isDark,
                package,
                pkgColor,
              ),
            );
          }),

        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showAddPackageDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.packagePlus,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dodaj opakowanie',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPackageState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _showAddPackageDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarPlus,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Ustaw termin ważności',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageRow(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    MedicinePackage package,
    Color packageColor,
  ) {
    final pkgStatus = _getPackageStatus(package);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Badge z datą
            GestureDetector(
              onTap: () => _showEditPackageDateDialog(context, package),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: packageColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(pkgStatus),
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      package.displayDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Edytuj datę
            GestureDetector(
              onTap: () => _showEditPackageDateDialog(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.calendarCog,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Ilość
            GestureDetector(
              onTap: () => _showEditRemainingDialog(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.blocks,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const Spacer(),
            // Usuń (tylko jeśli >1 opakowanie)
            if (_medicine.packages.length > 1)
              GestureDetector(
                onTap: () => _deletePackage(package),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 20,
                    color: AppColors.expired,
                  ),
                ),
              ),
          ],
        ),
        // Status opakowania
        Padding(
          padding: const EdgeInsets.only(left: 10, top: 2),
          child: GestureDetector(
            onTap: () => _showEditRemainingDialog(context, package),
            child: Text(
              '└─ ${package.remainingDescription}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyCalculatorSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final totalPieces = _medicine.totalPieceCount;
    final supplyEndDate = _medicine.calculateSupplyEndDate();
    final canCalculate = totalPieces > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.calendarHeart, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Do kiedy wystarczy?',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (!canCalculate)
          Text(
            'Uzupełnij ilość sztuk w opakowaniach',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          )
        else if (supplyEndDate == null)
          GestureDetector(
            onTap: () => _showSetDailyIntakeDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.pillBottle,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ustaw dzienne zużycie',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildSupplyResult(context, theme, isDark, supplyEndDate),

        const SizedBox(height: 4),
        Text(
          'Kalkulacja szacunkowa. Nie zastępuje zaleceń lekarza.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyResult(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    DateTime endDate,
  ) {
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;
    final formattedDate =
        '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showSetDailyIntakeDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendarOff,
                  size: 14,
                  color: daysRemaining <= 7
                      ? AppColors.expired
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: daysRemaining <= 7
                              ? AppColors.expired
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' (za $daysRemaining dni)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _addToCalendar(endDate),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Icon(
              LucideIcons.calendarPlus,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreSection(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Przycisk "Więcej" / "Mniej" (wyrównany do prawej)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isMoreExpanded = !_isMoreExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: _isMoreExpanded
                    ? NeuDecoration.pressedSmall(isDark: isDark, radius: 12)
                    : NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isMoreExpanded
                          ? LucideIcons.chevronsDownUp
                          : LucideIcons.chevronsUpDown,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isMoreExpanded ? 'Mniej' : 'Więcej',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Separator po Więcej (gdy rozwinięte)
        if (_isMoreExpanded) ...[
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
        ],

        // Rozwinięta zawartość - animacja pionowa (expand down)
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isMoreExpanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 8,
                      right: 4,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === ETYKIETY (najpierw) ===
                        _buildLabelsSection(context, theme, isDark),

                        // === TAGI ===
                        const SizedBox(height: 12),
                        _buildTagsSection(context, theme, isDark),

                        // === DATA DODANIA + WERYFIKACJA ===
                        const SizedBox(height: 12),
                        Text(
                          'Dodano',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_medicine.dataDodania),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Wskaźnik weryfikacji po kodzie kreskowym
                        if (_medicine.isVerifiedByBarcode) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.valid.withAlpha(
                                isDark ? 30 : 20,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.valid.withAlpha(50),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  LucideIcons.shieldCheck,
                                  size: 16,
                                  color: AppColors.valid,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Zweryfikowano w Rejestrze Produktów Leczniczych Dopuszczonych do Obrotu na terytorium Rzeczypospolitej Polskiej',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.valid,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Monit o konflikcie nazwa/kod (jeśli obecny)
                        if (_medicine.verificationNote != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 14,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _medicine.verificationNote!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.tertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // === USUŃ LEK ===
                        const SizedBox(height: 16),
                        _buildDeleteSection(context, theme, isDark),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#Tags',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showEditCustomTagsDialog(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.squarePen,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_medicine.tagi.isEmpty)
          Text(
            'Brak tagów',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _medicine.tagi.map((tag) {
              return GestureDetector(
                onTap: () => widget.onTagTap?.call(tag),
                child: _buildTag(tag, isDark, theme),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLabelsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Etykiety',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  _isLabelsOpen ? LucideIcons.chevronUp : LucideIcons.squarePen,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.storageService != null)
          LabelSelector(
            storageService: widget.storageService!,
            selectedLabelIds: _medicine.labels,
            isOpen: _isLabelsOpen,
            onToggle: () => setState(() => _isLabelsOpen = !_isLabelsOpen),
            onLabelTap: (labelId) => widget.onLabelTap?.call(labelId),
            onChanged: (newLabelIds) async {
              final updatedMedicine = _medicine.copyWith(labels: newLabelIds);
              await widget.storageService?.saveMedicine(updatedMedicine);
              setState(() => _medicine = updatedMedicine);
              widget.onMedicineUpdated?.call();
            },
          ),
      ],
    );
  }

  Widget _buildDeleteSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        // Usuń lek button (flat style, no shadows)
        GestureDetector(
          onTap: () => _showDeleteConfirmationDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.expired.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.expired.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.trash2, size: 18, color: AppColors.expired),
                const SizedBox(width: 8),
                Text(
                  'Usuń lek',
                  style: TextStyle(
                    color: AppColors.expired,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Przycisk zmiany nazwy dla niezweryfikowanych leków (z padding dla cieni)
        if (!_medicine.isVerifiedByBarcode) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => _showEditNameDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.textCursorInput,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zmień nazwę',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        NeuButton(
          onPressed: widget.onExpand,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.chevronUp,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                'Zwiń',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DIALOGI ====================

  Future<void> _showEditNameDialog(BuildContext context) async {
    final controller = TextEditingController(text: _medicine.nazwa);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj nazwę leku'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nazwa leku...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updatedMedicine = _medicine.copyWith(nazwa: result);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń lek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Czy na pewno chcesz usunąć ${_medicine.nazwa ?? "ten lek"}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expiringSoon.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.expiringSoon.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 16,
                    color: AppColors.expiringSoon,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aby usunąć jedno opakowanie, przejdź do sekcji "Termin ważności"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete?.call();
    }
  }

  Future<void> _showEditDescriptionDialog(BuildContext context) async {
    final controller = TextEditingController(text: _medicine.opis);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj opis'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Opis działania leku...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updatedMedicine = _medicine.copyWith(opis: result);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showEditWskazaniaDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _medicine.wskazania.join(', '),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj wskazania'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Wskazania oddzielone przecinkami...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null) {
      final wskazania = result
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final updatedMedicine = _medicine.copyWith(wskazania: wskazania);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showEditCustomTagsDialog(BuildContext context) async {
    final categorizedTags = tagCategories.values.expand((e) => e).toSet();
    final customTags = _medicine.tagi
        .where((t) => !categorizedTags.contains(t))
        .toList();
    final controller = TextEditingController(text: customTags.join(', '));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj własne tagi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tagi spoza listy kontrolowanej. Oddziel przecinkami.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'np. domowe, mama, dziecko...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null) {
      final systemTags = _medicine.tagi
          .where((t) => categorizedTags.contains(t))
          .toList();
      final newCustomTags = result
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedMedicine = _medicine.copyWith(
        tagi: [...systemTags, ...newCustomTags],
      );
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showAddPackageDialog(BuildContext context) async {
    final currentYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    int selectedYear = currentYear + 1;
    bool useSameDate = false;
    bool useSameQuantity = false;

    final firstPackage = _medicine.packages.isNotEmpty
        ? _medicine.sortedPackages.first
        : null;
    final hasQuantity = firstPackage?.remainingDescription != null;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj opakowanie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_medicine.packages.isNotEmpty) ...[
                CheckboxListTile(
                  title: Text(
                    'Taka sama data (${_medicine.sortedPackages.first.displayDate})',
                  ),
                  value: useSameDate,
                  onChanged: (v) =>
                      setDialogState(() => useSameDate = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasQuantity)
                  CheckboxListTile(
                    title: Text(
                      'Taka sama ilość (${firstPackage!.remainingDescription})',
                    ),
                    value: useSameQuantity,
                    onChanged: (v) =>
                        setDialogState(() => useSameQuantity = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 12),
              ],
              if (!useSameDate)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Miesiąc',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Rok',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(15, (i) => currentYear + i)
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedYear = v!),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                DateTime date;
                if (useSameDate && _medicine.packages.isNotEmpty) {
                  date =
                      _medicine.sortedPackages.first.dateTime ??
                      DateTime(selectedYear, selectedMonth + 1, 0);
                } else {
                  date = DateTime(selectedYear, selectedMonth + 1, 0);
                }
                Navigator.pop(context, {
                  'date': date,
                  'useSameQuantity': useSameQuantity,
                });
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final date = result['date'] as DateTime;
      final copyQuantity = result['useSameQuantity'] as bool;

      MedicinePackage newPackage;
      if (copyQuantity && firstPackage != null) {
        newPackage = MedicinePackage(
          expiryDate: date.toIso8601String().split('T')[0],
          pieceCount: firstPackage.pieceCount,
          percentRemaining: firstPackage.percentRemaining,
        );
      } else {
        newPackage = MedicinePackage(
          expiryDate: date.toIso8601String().split('T')[0],
        );
      }

      final updatedPackages = [..._medicine.packages, newPackage];
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showEditPackageDateDialog(
    BuildContext context,
    MedicinePackage package,
  ) async {
    DateTime currentDate =
        package.dateTime ?? DateTime.now().add(const Duration(days: 365));
    int selectedMonth = currentDate.month;
    int selectedYear = currentDate.year;
    final currentYear = DateTime.now().year;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edytuj termin ważności'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Miesiąc',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.toString().padLeft(2, '0')),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedMonth = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Rok',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(15, (i) => currentYear + i)
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedYear = v!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final lastDay = DateTime(selectedYear, selectedMonth + 1, 0);
                Navigator.pop(context, lastDay);
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedPackage = package.copyWith(
        expiryDate: result.toIso8601String().split('T')[0],
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showEditRemainingDialog(
    BuildContext context,
    MedicinePackage package,
  ) async {
    bool isOpen = package.isOpen;
    int valueMode = package.pieceCount != null
        ? 1
        : package.percentRemaining != null
        ? 2
        : 0;
    final pieceController = TextEditingController(
      text: package.pieceCount?.toString() ?? '',
    );
    final percentController = TextEditingController(
      text: package.percentRemaining?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Określ pozostałą ilość'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status opakowania',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Zamknięte'),
                    selected: !isOpen,
                    onSelected: (_) => setDialogState(() {
                      isOpen = false;
                      if (valueMode == 2) valueMode = 0;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Otwarte'),
                    selected: isOpen,
                    onSelected: (_) => setDialogState(() => isOpen = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ilość (opcjonalne)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Brak'),
                    selected: valueMode == 0,
                    onSelected: (_) => setDialogState(() => valueMode = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Sztuki'),
                    selected: valueMode == 1,
                    onSelected: (_) => setDialogState(() => valueMode = 1),
                  ),
                  if (isOpen)
                    ChoiceChip(
                      label: const Text('Procent'),
                      selected: valueMode == 2,
                      onSelected: (_) => setDialogState(() => valueMode = 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (valueMode == 1)
                TextField(
                  controller: pieceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isOpen ? 'Pozostało sztuk' : 'Ilość sztuk',
                    hintText: 'np. 30',
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (valueMode == 2)
                TextField(
                  controller: percentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pozostało procent',
                    hintText: 'np. 50',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'isOpen': isOpen,
                  'pieceCount': valueMode == 1
                      ? int.tryParse(pieceController.text)
                      : null,
                  'percentRemaining': valueMode == 2
                      ? int.tryParse(percentController.text)
                      : null,
                });
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedPackage = MedicinePackage(
        id: package.id,
        expiryDate: package.expiryDate,
        isOpen: result['isOpen'] as bool,
        pieceCount: result['pieceCount'] as int?,
        percentRemaining: result['percentRemaining'] as int?,
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _deletePackage(MedicinePackage package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń opakowanie?'),
        content: Text(
          'Czy na pewno chcesz usunąć opakowanie z datą ${package.displayDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expired),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedPackages = _medicine.packages
          .where((p) => p.id != package.id)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _showSetDailyIntakeDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _medicine.dailyIntake?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dzienne zużycie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Łączna ilość sztuk: ${_medicine.totalPieceCount}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ile tabletek dziennie?',
                hintText: 'np. 2',
                suffixText: 'szt./dzień',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      final updated = _medicine.copyWith(dailyIntake: result);
      await widget.storageService?.saveMedicine(updated);
      setState(() => _medicine = updated);
      widget.onMedicineUpdated?.call();
    }
  }

  Future<void> _addToCalendar(DateTime endDate) async {
    final medicineName = _medicine.nazwa ?? 'Lek';
    final event = Event(
      title: '$medicineName - koniec',
      description: 'Przypomnienie: koniec zapasu leku "$medicineName".',
      startDate: endDate,
      endDate: endDate.add(const Duration(hours: 1)),
      allDay: true,
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  void _showLeafletSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => LeafletSearchSheet(
            initialQuery: _medicine.nazwa ?? '',
            onLeafletSelected: (url) => _attachLeaflet(url),
          ),
        ),
      ),
    );
  }

  Future<void> _attachLeaflet(String url) async {
    final updatedMedicine = _medicine.copyWith(leafletUrl: url);
    await widget.storageService?.saveMedicine(updatedMedicine);
    setState(() => _medicine = updatedMedicine);
    widget.onMedicineUpdated?.call();

    final cacheService = PdfCacheService();
    cacheService.getPdfFile(url, _medicine.id);
  }

  Future<void> _detachLeaflet() async {
    final cacheService = PdfCacheService();
    await cacheService.clearCache(_medicine.id);

    final updatedMedicine = Medicine(
      id: _medicine.id,
      nazwa: _medicine.nazwa,
      opis: _medicine.opis,
      wskazania: _medicine.wskazania,
      tagi: _medicine.tagi,
      labels: _medicine.labels,
      notatka: _medicine.notatka,
      terminWaznosci: _medicine.terminWaznosci,
      leafletUrl: null,
      dataDodania: _medicine.dataDodania,
      packages: _medicine.packages,
      dailyIntake: _medicine.dailyIntake,
    );
    await widget.storageService?.saveMedicine(updatedMedicine);
    setState(() => _medicine = updatedMedicine);
    widget.onMedicineUpdated?.call();
  }

  void _showPdfViewer(BuildContext context) {
    if (_medicine.leafletUrl == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          url: _medicine.leafletUrl!,
          title: _medicine.nazwa ?? 'Ulotka leku',
          medicineId: _medicine.id,
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  BoxDecoration _getPressedDecoration(
    bool isDark,
    LinearGradient gradient,
    Color statusColor,
  ) {
    // Matching shadow structure for smooth BoxDecoration.lerp() interpolation.
    // Same number of shadows as statusCard, but all transparent.
    if (!isDark) {
      // Light mode: 2 shadows matching statusCard structure
      return BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.transparent,
            offset: Offset(
              NeuDecoration.shadowDistance,
              NeuDecoration.shadowDistance,
            ),
            blurRadius: NeuDecoration.shadowBlur,
          ),
          BoxShadow(
            color: Colors.transparent,
            offset: Offset(
              -NeuDecoration.shadowDistanceSm,
              -NeuDecoration.shadowDistanceSm,
            ),
            blurRadius: NeuDecoration.shadowBlurSm,
          ),
        ],
      );
    }

    // Dark mode: 2 shadows matching statusCard structure
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.transparent, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Colors.transparent,
          offset: Offset(0, 8),
          blurRadius: 32,
        ),
        BoxShadow(
          color: Colors.transparent,
          offset: Offset(0, 0),
          blurRadius: 12,
        ),
      ],
    );
  }

  Widget _buildBadge(UserLabel label, bool isDark) {
    final colorInfo = labelColors[label.color]!;
    final bgColor = Color(colorInfo.hexValue);
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

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1e293b) : Colors.white;
  }

  LinearGradient _getGradient(ExpiryStatus status, bool isDark) {
    switch (status) {
      case ExpiryStatus.expired:
        return isDark
            ? AppColors.darkGradientExpired
            : AppColors.lightGradientExpired;
      case ExpiryStatus.expiringSoon:
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

  ExpiryStatus _getPackageStatus(MedicinePackage package) {
    final expiry = package.dateTime;
    if (expiry == null) return ExpiryStatus.unknown;
    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;
    if (daysUntilExpiry < 0) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.valid;
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
