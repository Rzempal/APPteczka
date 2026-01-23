import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';
import '../models/label.dart';
import '../services/storage_service.dart';
import '../services/pdf_cache_service.dart';
import '../services/gemini_shelf_life_service.dart';
import '../services/app_logger.dart';
import '../theme/app_theme.dart';
import '../screens/pdf_viewer_screen.dart';
import '../utils/shelf_life_parser.dart';
import '../utils/pharmaceutical_form_helper.dart';
import 'package:logging/logging.dart';
import 'neumorphic/neumorphic.dart';

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
  final bool isPerformanceMode;

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
    this.isPerformanceMode = false,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  static final Logger _log = AppLogger.getLogger('MedicineCard');
  bool _isMoreExpanded = false; // Akordeon "Więcej"

  bool _isEditModeButtonActive = false; // Stan lokalny przycisku trybu edycji
  late Medicine _medicine;

  /// Czy tryb edycji jest aktywny (z ustawień LUB z lokalnego buttona)
  bool get _isEditModeActive {
    final alwaysActive = widget.storageService?.editModeAlwaysActive ?? false;
    return alwaysActive || _isEditModeButtonActive;
  }

  /// Czy pokazać przycisk "Tryb edycji" (ukryty gdy ustawienie włączone)
  bool get _showEditModeButton {
    final alwaysActive = widget.storageService?.editModeAlwaysActive ?? false;
    return !alwaysActive;
  }

  // Inline note editing
  bool _isEditingNote = false;
  late TextEditingController _noteController;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
    _noteController = TextEditingController(text: _medicine.notatka ?? '');
    _noteFocusNode = FocusNode();
    _noteFocusNode.addListener(_onNoteFocusChange);
  }

  @override
  void didUpdateWidget(covariant MedicineCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Zawsze aktualizuj lokalną kopię obiektu, jeśli przyszła nowa wersja z góry
    if (oldWidget.medicine != widget.medicine) {
      _medicine = widget.medicine;
      // Aktualizuj tekst notatki tylko jeśli nie jest aktualnie edytowana
      if (!_isEditingNote) {
        _noteController.text = _medicine.notatka ?? '';
      }
    }

    // Resetuj stan UI tylko jeśli zmienił się ID (to zupełnie inny lek)
    if (oldWidget.medicine.id != widget.medicine.id) {
      _isMoreExpanded = false;
    }
  }

  @override
  void dispose() {
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

  /// Czyści notatkę i zapisuje pusty stan (null)
  Future<void> _clearNote() async {
    _noteController.clear();
    // Użyj clearNotatka: true aby explicite ustawić null
    final updatedMedicine = _medicine.copyWith(clearNotatka: true);
    await widget.storageService?.saveMedicine(updatedMedicine);
    setState(() {
      _medicine = updatedMedicine;
      _isEditingNote = false;
    });
    widget.onMedicineUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = _medicine.expiryStatus;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    // Pobierz etykiety dla tego leku
    final medicineLabels = widget.labels
        .where((l) => _medicine.labels.contains(l.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: widget.isCompact ? widget.onExpand : null,
        child: Container(
          decoration: widget.isCompact
              ? BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: AppTheme.organicRadiusSmall,
                  border: Border.all(
                    color: statusColor.withValues(
                      alpha: AppTheme.cardBorderOpacity,
                    ),
                    width: AppTheme.cardBorderWidth,
                  ),
                  boxShadow: widget.isPerformanceMode
                      ? [
                          // Performance mode: reduced shadows
                          BoxShadow(
                            color: (isDark ? Colors.black : Colors.black12)
                                .withValues(alpha: 0.1),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : [
                          // Full quality: neumorphic shadows
                          BoxShadow(
                            color:
                                (isDark
                                        ? AppColors.darkShadowDark
                                        : AppColors.lightShadowDark)
                                    .withValues(alpha: isDark ? 0.3 : 0.15),
                            offset: const Offset(4, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color:
                                (isDark
                                        ? AppColors.darkShadowLight
                                        : AppColors.lightShadowLight)
                                    .withValues(alpha: isDark ? 0.05 : 0.5),
                            offset: const Offset(-2, -2),
                            blurRadius: 6,
                          ),
                        ],
                )
              : NeuDecoration.flat(
                  isDark: isDark,
                  borderRadius: AppTheme.organicRadiusSmall, // Organic shape
                  performanceMode: widget.isPerformanceMode,
                  border: Border.all(
                    color: statusColor.withValues(
                      alpha: AppTheme.cardBorderOpacity,
                    ),
                    width: AppTheme.cardBorderWidth,
                  ),
                ),
          child: Padding(
            padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // W compact mode: Row z ikoną/notatką + Column(H1, H2)
                if (widget.isCompact)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lewa kolumna: Ikona + Notatka (pod ikoną)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ikona typu leku (bez tła)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              _getMedicineTypeIcon(),
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          // Notatka preview (pod ikoną, 2 linie)
                          if (_medicine.notatka?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 44,
                              child: Text(
                                _medicine.notatka!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Prawa kolumna: H1 (nazwa) + H2 (statyczny opis)
                      Expanded(
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
                            const SizedBox(height: 4),
                            // H2: Statyczny opis (bez dynamicznej logiki)
                            Text(
                              _medicine.opis,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  _buildHeader(
                    theme,
                    isDark,
                    medicineLabels,
                    statusColor,
                    statusIcon,
                  ),
                // H3 + H4 pod spodem (tylko compact)
                if (widget.isCompact)
                  _buildCompactStockSection(theme, statusColor),
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
                // Etykiety - w obu trybach (compact i expanded)
                ...medicineLabels
                    .take(3)
                    .map((label) => _buildBadge(label, isDark)),
                if (medicineLabels.length > 3)
                  _buildBadgeCount(medicineLabels.length - 3, isDark),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  /// Zwraca ikonę typu leku na podstawie postaci farmaceutycznej lub jednostki
  IconData _getMedicineTypeIcon() {
    // Priorytet 1: postać farmaceutyczna (z RPL)
    if (_medicine.pharmaceuticalForm != null &&
        _medicine.pharmaceuticalForm!.isNotEmpty) {
      return PharmaceuticalFormHelper.getIcon(_medicine.pharmaceuticalForm);
    }

    // Priorytet 2: fallback do PackageUnit (wsteczna kompatybilność)
    if (_medicine.packages.isEmpty) return LucideIcons.pill;

    switch (_medicine.packages.first.unit) {
      case PackageUnit.ml:
        return LucideIcons.flaskConical;
      case PackageUnit.grams:
        return LucideIcons.droplet;
      case PackageUnit.pieces:
        return LucideIcons.pill;
      case PackageUnit.sachets:
        return LucideIcons.package;
      case PackageUnit.none:
        return LucideIcons.packageOpen;
    }
  }

  /// Buduje opis lub warning - dynamiczny content
  Widget _buildDescriptionOrWarning(ThemeData theme, Color statusColor) {
    // Sprawdź warningi w kolejności priorytetu

    // 1. Krytycznie niski stan (czerwony warning)
    if (_medicine.packages.isNotEmpty) {
      final firstPackage = _medicine.packages.first;
      if (firstPackage.isOpen && firstPackage.percentRemaining != null) {
        if (firstPackage.percentRemaining! <= 10) {
          return Text(
            'KRYTYCZNIE NISKI STAN - UZUPEŁNIJ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.expired,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          );
        }
      } else if (firstPackage.pieceCount != null) {
        final total = _medicine.totalPieceCount;
        if (_medicine.dailyIntake != null && _medicine.dailyIntake! > 0) {
          final daysSupply = total / _medicine.dailyIntake!;
          if (daysSupply <= 3) {
            return Text(
              'ZAPAS NA $daysSupply DNI - UZUPEŁNIJ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expired,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            );
          }
        }
      }
    }

    // 2. Termin ważności < 7 dni (amber warning)
    final status = _medicine.expiryStatus;
    if (status == ExpiryStatus.expiringSoon || status == ExpiryStatus.expired) {
      final expiry = _medicine.terminWaznosci;
      if (expiry != null) {
        final date = DateTime.tryParse(expiry);
        if (date != null) {
          final daysUntilExpiry = date.difference(DateTime.now()).inDays;
          if (daysUntilExpiry >= 0 && daysUntilExpiry <= 7) {
            return Text(
              'Ważne jeszcze $daysUntilExpiry dni',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expiringSoon,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            );
          } else if (daysUntilExpiry < 0) {
            return Text(
              'Produkt przeterminowany',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expired,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            );
          }
        }
      }
    }

    // 3. Przydatność po otwarciu (info)
    if (_medicine.shelfLifeAfterOpening != null &&
        _medicine.packages.isNotEmpty &&
        _medicine.packages.first.isOpen) {
      return Text(
        'Po otwarciu: ${_medicine.shelfLifeAfterOpening}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      );
    }

    // 4. Default - normalny opis
    return Text(
      _medicine.opis,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Buduje sekcję H3+H4 (Smart Hybrid Stock) dla trybu compact
  /// Layout: Ilość (lewa) + Predykcja (prawa) + Segmented Bar
  Widget _buildCompactStockSection(ThemeData theme, Color statusColor) {
    String unitLabel = 'szt.';
    int currentStock = 0;
    int totalCapacity = 0;
    double stockPercentage = 0.0;
    final isDark = theme.brightness == Brightness.dark;

    // Oblicz zapas i sumę pojemności
    if (_medicine.packages.isNotEmpty) {
      final firstPackage = _medicine.packages.first;

      // Jednostka zależna od typu opakowania
      switch (firstPackage.unit) {
        case PackageUnit.ml:
          unitLabel = 'ml';
          break;
        case PackageUnit.grams:
          unitLabel = 'g';
          break;
        case PackageUnit.pieces:
          unitLabel = 'szt.';
          break;
        case PackageUnit.sachets:
          unitLabel = 'sasz.';
          break;
        case PackageUnit.none:
          unitLabel = '';
          break;
      }

      // Oblicz sumę pojemności i aktualny stan
      for (final package in _medicine.packages) {
        // Capacity - pojemność całkowita (fallback: pieceCount dla wstecznej kompatybilności)
        final packageCapacity = package.capacity ?? package.pieceCount;
        if (packageCapacity != null) {
          totalCapacity += packageCapacity;

          // Aktualny stan - pieceCount dla otwartych, capacity dla zamkniętych
          if (package.isOpen) {
            if (package.pieceCount != null) {
              currentStock += package.pieceCount!;
            } else if (package.percentRemaining != null) {
              currentStock +=
                  (packageCapacity * package.percentRemaining! / 100).round();
            }
          } else {
            // Zamknięte = pełne
            currentStock += packageCapacity;
          }
        }
      }

      // Oblicz procent zapasu
      if (totalCapacity > 0) {
        stockPercentage = (currentStock / totalCapacity).clamp(0.0, 1.0);
      }
    }

    // Jeśli brak danych o zapasie, zwróć pusty widget
    // Notatka jest teraz wyświetlana pod ikoną w głównym Row
    if (totalCapacity == 0) {
      return const SizedBox.shrink();
    }

    // === Smart Hybrid Stock: oblicz info o ważności ===
    final validityInfo = _calculateValidityInfo(stockPercentage);
    final validityColor = validityInfo.color;

    // Padding wyrównujący z nazwą (ikona 44px + gap 12px = 56px)
    const double alignmentPadding = 56.0;

    return Padding(
      padding: const EdgeInsets.only(left: alignmentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Góra: Ilość (lewa) + Data/Predykcja (prawa)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lewa strona: Ilość (np. "24 szt.")
              Text(
                '$currentStock$unitLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: validityInfo.isWarning || validityInfo.isDanger
                      ? validityColor
                      : theme.colorScheme.onSurface,
                ),
              ),
              // Prawa strona: Ikona + Predykcja
              const Spacer(),
              Icon(validityInfo.icon, size: 14, color: validityColor),
              const SizedBox(width: 4),
              Text(
                validityInfo.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: validityColor,
                ),
              ),
            ],
          ),
          // Dół: Segmented Progress Bar
          const SizedBox(height: 6),
          _buildSegmentedProgressBar(
            stockPercentage,
            validityColor,
            isDark,
            theme,
          ),
        ],
      ),
    );
  }

  /// Oblicza informacje o ważności dla Smart Hybrid Stock
  /// Zwraca ikonę, tekst, kolor i flagi ostrzeżeń
  _ValidityInfo _calculateValidityInfo(double stockPercentage) {
    final now = DateTime.now();
    final accentColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.accentDark
        : AppColors.accent;
    final warnColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.expiringSoonDark
        : AppColors.expiringSoonLight;
    final dangerColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.expiredDark
        : AppColors.expiredLight;

    // === PRIO 1: Przeterminowane (expiry date) ===
    final expiryDate = _medicine.terminWaznosci;
    DateTime? expiryDateTime;
    int? daysUntilExpiry;
    if (expiryDate != null) {
      expiryDateTime = DateTime.tryParse(expiryDate);
      if (expiryDateTime != null) {
        daysUntilExpiry = expiryDateTime.difference(now).inDays;
        if (daysUntilExpiry < 0) {
          return _ValidityInfo(
            icon: LucideIcons.ban,
            text: 'Przeterminowane',
            color: dangerColor,
            isDanger: true,
            isWarning: false,
          );
        }
      }
    }

    // === PRIO 2: Shelf-life po otwarciu (wyższy prio niż expiry) ===
    final shelfLife = _medicine.shelfLifeAfterOpening;
    final firstPackage = _medicine.packages.isNotEmpty
        ? _medicine.packages.first
        : null;
    if (shelfLife != null &&
        firstPackage != null &&
        firstPackage.isOpen &&
        firstPackage.openedDate != null &&
        (_medicine.shelfLifeStatus == 'completed' ||
            _medicine.shelfLifeStatus == 'manual')) {
      final parsed = ShelfLifeParser.parse(shelfLife);
      if (parsed.isValid && parsed.days != null) {
        final shelfExpiryDate = ShelfLifeParser.getExpiryDate(
          firstPackage.openedDate!,
          parsed.days!,
        );
        if (shelfExpiryDate != null) {
          final daysUntilShelfExpiry = shelfExpiryDate.difference(now).inDays;

          // Przeterminowane po otwarciu
          if (daysUntilShelfExpiry < 0) {
            return _ValidityInfo(
              icon: LucideIcons.ban,
              text: 'Przeterminowane',
              color: dangerColor,
              isDanger: true,
              isWarning: false,
            );
          }

          // === PRIO 3: Brak zapasu ===
          if (stockPercentage <= 0) {
            return _ValidityInfo(
              icon: LucideIcons.ban,
              text: 'Brak zapasu',
              color: dangerColor,
              isDanger: true,
              isWarning: false,
            );
          }

          // === PRIO 4: Warning (ilość <20% LUB shelf-life <7 dni) ===
          if (stockPercentage < 0.20 && daysUntilShelfExpiry < 7) {
            return _ValidityInfo(
              icon: LucideIcons.triangleAlert,
              text: '$daysUntilShelfExpiry dni',
              color: warnColor,
              isDanger: false,
              isWarning: true,
            );
          }

          // === PRIO 5: Shelf-life <35 dni (countdown) ===
          if (daysUntilShelfExpiry < 35) {
            return _ValidityInfo(
              icon: LucideIcons.trendingDown,
              text: 'Otwarto, zużyć w ciągu $daysUntilShelfExpiry dni',
              color: accentColor,
              isDanger: false,
              isWarning: false,
            );
          }

          // === PRIO 6: Shelf-life ≥35 dni (data) ===
          final formattedShelfExpiry =
              '${shelfExpiryDate.day.toString().padLeft(2, '0')}.${shelfExpiryDate.month.toString().padLeft(2, '0')}';
          return _ValidityInfo(
            icon: LucideIcons.circleCheckBig,
            text: 'Otwarto, zużyć do $formattedShelfExpiry',
            color: accentColor,
            isDanger: false,
            isWarning: false,
          );
        }
      }
    }

    // === PRIO 3: Brak zapasu (bez shelf-life) ===
    if (stockPercentage <= 0) {
      return _ValidityInfo(
        icon: LucideIcons.ban,
        text: 'Brak zapasu',
        color: dangerColor,
        isDanger: true,
        isWarning: false,
      );
    }

    // === PRIO 4: Warning (ilość <20% LUB expiry <7 dni) ===
    if (daysUntilExpiry != null &&
        stockPercentage < 0.20 &&
        daysUntilExpiry < 7) {
      return _ValidityInfo(
        icon: LucideIcons.triangleAlert,
        text: '$daysUntilExpiry dni',
        color: warnColor,
        isDanger: false,
        isWarning: true,
      );
    }

    // === PRIO 5: Expiry <35 dni (countdown) ===
    if (daysUntilExpiry != null && daysUntilExpiry < 35) {
      return _ValidityInfo(
        icon: LucideIcons.trendingDown,
        text: 'Ważne jeszcze $daysUntilExpiry dni',
        color: accentColor,
        isDanger: false,
        isWarning: false,
      );
    }

    // === PRIO 7: Default (data ważności) ===
    if (expiryDateTime != null) {
      final formatted =
          '${expiryDateTime.day.toString().padLeft(2, '0')}.${expiryDateTime.month.toString().padLeft(2, '0')}.${expiryDateTime.year}';
      return _ValidityInfo(
        icon: LucideIcons.circleCheckBig,
        text: formatted,
        color: accentColor,
        isDanger: false,
        isWarning: false,
      );
    }

    // Brak danych o ważności
    return _ValidityInfo(
      icon: LucideIcons.circleOff,
      text: 'Brak daty',
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      isDanger: false,
      isWarning: false,
    );
  }

  /// Buduje segmentowany pasek postępu (10 bloków)
  Widget _buildSegmentedProgressBar(
    double percentage,
    Color activeColor,
    bool isDark,
    ThemeData theme,
  ) {
    const int segmentCount = 10;
    const double segmentGap = 2.0;
    final int filledSegments = (percentage * segmentCount).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth =
            (constraints.maxWidth - (segmentCount - 1) * segmentGap) /
            segmentCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(segmentCount, (index) {
            final isFilled = index < filledSegments;
            final isFirst = index == 0;
            final isLast = index == segmentCount - 1;

            return Container(
              width: segmentWidth,
              height: 6,
              decoration: BoxDecoration(
                color: isFilled
                    ? activeColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst
                      ? const Radius.circular(3)
                      : const Radius.circular(1),
                  right: isLast
                      ? const Radius.circular(3)
                      : const Radius.circular(1),
                ),
                // Dark Mode Glow effect
                boxShadow: isFilled && isDark
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }

  /// Zwraca pojemność pierwszego opakowania (lub null)
  int? _getFirstPackageCapacity() {
    if (_medicine.packages.isEmpty) return null;
    final first = _medicine.packages.first;
    return first.capacity ?? first.pieceCount;
  }

  /// Buduje sekcję informacji o opakowaniu: moc + pojemność
  Widget _buildPackageInfoSection(ThemeData theme, bool isDark) {
    final power = _medicine.power;
    final capacity = _getFirstPackageCapacity();
    final firstPackage = _medicine.packages.isNotEmpty
        ? _medicine.packages.first
        : null;

    // Jednostka
    String unitLabel = '';
    if (firstPackage != null) {
      switch (firstPackage.unit) {
        case PackageUnit.pieces:
          unitLabel = 'szt.';
          break;
        case PackageUnit.ml:
          unitLabel = 'ml';
          break;
        case PackageUnit.grams:
          unitLabel = 'g';
          break;
        case PackageUnit.sachets:
          unitLabel = 'sasz.';
          break;
        case PackageUnit.none:
          break;
      }
    }

    // Format: "500mg · 30 szt." lub tylko jedno z nich
    final parts = <String>[];
    if (power != null && power.isNotEmpty) {
      parts.add(power);
    }
    if (capacity != null && unitLabel.isNotEmpty) {
      parts.add('$capacity $unitLabel');
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(LucideIcons.package, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Opakowanie: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            parts.join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje tagi inline (bez nagłówka) - do wyświetlenia nad opisem
  Widget _buildTagsInline(BuildContext context, ThemeData theme, bool isDark) {
    if (_medicine.tagi.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _medicine.tagi
          .map((tag) => _buildTag(tag, isDark, theme))
          .toList(),
    );
  }

  /// Buduje sekcję zapasu leku w expanded mode
  /// Format: X{icon}/Y{pillBottle}, wystarczy do DD.MM.YYYY
  Widget _buildExpandedStockSection(
    ThemeData theme,
    bool isDark,
    Color statusColor,
  ) {
    if (_medicine.packages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Oblicz dane zapasu
    String unitLabel = 'szt.';
    int currentStock = 0;
    final packageCount = _medicine.packages.length;
    final firstPackage = _medicine.packages.first;

    // Jednostka zależna od typu opakowania
    switch (firstPackage.unit) {
      case PackageUnit.ml:
        unitLabel = 'ml';
        break;
      case PackageUnit.grams:
        unitLabel = 'g';
        break;
      case PackageUnit.pieces:
        unitLabel = 'szt.';
        break;
      case PackageUnit.sachets:
        unitLabel = 'sasz.';
        break;
      case PackageUnit.none:
        unitLabel = '';
        break;
    }

    // Oblicz aktualny stan
    for (final package in _medicine.packages) {
      final packageCapacity = package.capacity ?? package.pieceCount;
      if (packageCapacity != null) {
        if (package.isOpen) {
          if (package.pieceCount != null) {
            currentStock += package.pieceCount!;
          } else if (package.percentRemaining != null) {
            currentStock += (packageCapacity * package.percentRemaining! / 100)
                .round();
          }
        } else {
          // Zamknięte = pełne
          currentStock += packageCapacity;
        }
      }
    }

    // Oblicz datę do której wystarczy (jeśli mamy dailyIntake)
    String? endDateStr;
    if (_medicine.dailyIntake != null &&
        _medicine.dailyIntake! > 0 &&
        currentStock > 0) {
      final daysRemaining = (currentStock / _medicine.dailyIntake!).floor();
      final endDate = DateTime.now().add(Duration(days: daysRemaining));
      endDateStr =
          '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';
    }

    return Row(
      children: [
        // Label
        Text(
          'Zapas leku: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Ilość + ikona typu
        Icon(
          _getMedicineTypeIcon(),
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '$currentStock $unitLabel',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        // Separator
        Text(
          ' / ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Liczba opakowań + ikona
        Icon(
          LucideIcons.pillBottle,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '$packageCount op.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        // Data końcowa
        if (endDateStr != null) ...[
          Text(
            ', wystarczy do ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            endDateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
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
        const SizedBox(height: 4),

        // === SEPARATOR ===
        Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
        const SizedBox(height: 12),

        // === OPAKOWANIE (moc + pojemność) ===
        if (_medicine.power != null || _getFirstPackageCapacity() != null)
          _buildPackageInfoSection(theme, isDark),

        // === TAGI (bez nagłówka, nad opisem) ===
        _buildTagsInline(context, theme, isDark),

        // === OPIS (bez nagłówka H1) ===
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _medicine.opis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (_isEditModeActive) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditDescriptionDialog(context),
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

        // === WSKAZANIA ===
        const SizedBox(height: 16),
        _buildWskazaniaSection(context, theme, isDark),

        // === NOTATKA ===
        const SizedBox(height: 16),
        _buildNoteSection(context, theme, isDark),

        // === ZAPAS LEKU (nowa sekcja) ===
        const SizedBox(height: 16),
        _buildExpandedStockSection(theme, isDark, statusColor),

        // === WIĘCEJ (akordeon - zawiera packages, calculator, delete) ===
        const SizedBox(height: 16),
        _buildMoreSection(context, theme, isDark),
      ],
    );
  }

  // ==================== SEKCJE ====================

  /// Wskazania section
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
            // Edit button (align-right) - tylko w trybie edycji
            if (_isEditModeActive) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditWskazaniaDialog(context),
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

        // Ręczny wpis shelf life (gdy brak ulotki)
        if (!hasLeaflet) ...[
          const SizedBox(height: 12),
          _buildManualShelfLifeEntry(context, theme, isDark),
        ],
      ],
    );
  }

  /// Buduje sekcję ręcznego wpisu shelf life (gdy brak ulotki)
  Widget _buildManualShelfLifeEntry(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final hasManualEntry =
        _medicine.shelfLifeAfterOpening != null &&
        _medicine.shelfLifeStatus == 'manual';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.pencil,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Ważność po otwarciu',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(
                  text: hasManualEntry ? _medicine.shelfLifeAfterOpening : '',
                ),
                decoration: InputDecoration(
                  hintText: 'np. "6 miesięcy", "30 dni"',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                onSubmitted: (value) => _saveManualShelfLife(value.trim()),
              ),
            ),
            const SizedBox(width: 8),
            NeuButton(
              onPressed: () {
                final controller = TextEditingController(
                  text: hasManualEntry ? _medicine.shelfLifeAfterOpening : '',
                );
                _showManualShelfLifeDialog(context, controller);
              },
              padding: const EdgeInsets.all(10),
              child: Icon(
                LucideIcons.save,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Zapisuje ręcznie wpisany shelf life
  Future<void> _saveManualShelfLife(String value) async {
    _log.info('Saving manual shelf life: $value');

    if (value.isEmpty) {
      // Usuń manual entry
      final updatedMedicine = _medicine.copyWith(
        shelfLifeAfterOpening: null,
        shelfLifeStatus: null,
      );
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();
      return;
    }

    // Waliduj format (np. "6 miesięcy", "30 dni")
    final parsed = ShelfLifeParser.parse(value);
    if (!parsed.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsed.error ?? 'Nieprawidłowy format'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.expiringSoon,
          ),
        );
      }
      return;
    }

    final updatedMedicine = _medicine.copyWith(
      shelfLifeAfterOpening: value,
      shelfLifeStatus: 'manual',
    );
    await widget.storageService?.saveMedicine(updatedMedicine);
    setState(() => _medicine = updatedMedicine);
    widget.onMedicineUpdated?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zapisano'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.valid,
        ),
      );
    }
  }

  /// Pokazuje dialog do ręcznego wpisu shelf life
  Future<void> _showManualShelfLifeDialog(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ważność po otwarciu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'np. "6 miesięcy", "30 dni"',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result != null) {
      _saveManualShelfLife(result);
    }
  }

  Widget _buildNoteSection(BuildContext context, ThemeData theme, bool isDark) {
    final hasNote = _medicine.notatka?.isNotEmpty == true;
    final hasLeaflet =
        _medicine.leafletUrl != null && _medicine.leafletUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek
        Text(
          'Notatka',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        // Row: Pole tekstowe + CTA Ulotka + unpin
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pole tekstowe notatki (Expanded)
            Expanded(
              child: GestureDetector(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.transparent
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isEditingNote
                          ? AppColors.valid
                          : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400),
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
                              onTap: _clearNote,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: NeuDecoration.flatSmall(
                                  isDark: isDark,
                                  radius: 12,
                                ),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 20,
                                  color: AppColors.expired,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          hasNote
                              ? _medicine.notatka!
                              : 'Kliknij, aby dodać notatkę',
                          style: TextStyle(
                            color: hasNote
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontStyle: hasNote
                                ? FontStyle.normal
                                : FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // CTA Ulotka
            NeuButton(
              onPressed: hasLeaflet
                  ? () => _showPdfViewer(context)
                  : () => _showLeafletSearch(context),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasLeaflet ? LucideIcons.newspaper : LucideIcons.fileSearch,
                    size: 16,
                    color: hasLeaflet
                        ? AppColors.valid
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ulotka',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Pin-off button - tylko w trybie edycji i gdy jest ulotka
            if (hasLeaflet && _isEditModeActive) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _detachLeaflet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ), // Match NeuButton padding
                  decoration: NeuDecoration.flat(isDark: isDark, radius: 10),
                  child: Icon(
                    LucideIcons.pinOff,
                    size: 16,
                    color: AppColors.expired,
                  ),
                ),
              ),
            ],
          ],
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
        // H1: Szczegóły - termin ważności - data otwarcia + licznik opakowań
        Row(
          children: [
            Text(
              'Szczegóły - termin ważności - data otwarcia',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (packageCount > 0) ...[
              Text(
                '$packageCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.pillBottle,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
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
            // Szczegóły opakowania (połączenie edycji daty i ilości)
            GestureDetector(
              onTap: () => _showPackageDetailsBottomSheet(context, package),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.pillBottle,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Badge z datą
            GestureDetector(
              onTap: () => _showPackageDetailsBottomSheet(context, package),
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
        // Status opakowania (z opcjonalnym shelf life info)
        _buildPackageStatusDescription(context, theme, package),
      ],
    );
  }

  /// BottomSheet ze szczegółami opakowania (data, status, ilość)
  Future<void> _showPackageDetailsBottomSheet(
    BuildContext context,
    MedicinePackage package,
  ) async {
    final currentYear = DateTime.now().year;
    DateTime currentDate =
        package.dateTime ?? DateTime.now().add(const Duration(days: 365));
    int selectedMonth = currentDate.month;
    int selectedYear = currentDate.year;
    bool isOpen = package.isOpen;
    PackageUnit selectedUnit = package.unit;

    // Capacity i pieceCount - capacity to pojemność całkowita, pieceCount to pozostała ilość
    final capacityController = TextEditingController(
      text: package.capacity?.toString() ?? '',
    );
    final pieceController = TextEditingController(
      text: package.pieceCount?.toString() ?? '',
    );
    final percentController = TextEditingController(
      text: package.percentRemaining?.toString() ?? '',
    );
    DateTime? openedDate = package.openedDate != null
        ? DateTime.tryParse(package.openedDate!)
        : null;

    // Flagi do blokowania pętli sync
    bool isSyncingFromPiece = false;
    bool isSyncingFromPercent = false;

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.pillBottle,
                            size: 24,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Szczegóły opakowania',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sekcja 0: Informacje wspólne (moc, shelf life)
                            if (_medicine.power != null &&
                                _medicine.power!.isNotEmpty) ...[
                              Text(
                                'Moc leku',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6b7280),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: TextEditingController(
                                  text: _medicine.power,
                                ),
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF3F4F6),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Okres przydatności po otwarciu (z AI lub ręczny)
                            if (_medicine.shelfLifeAfterOpening != null ||
                                isOpen) ...[
                              Text(
                                'Okres przydatności po otwarciu',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6b7280),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: TextEditingController(
                                  text: _medicine.shelfLifeAfterOpening ?? '',
                                ),
                                readOnly: true,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  hintText: 'Brak informacji',
                                  suffixIcon:
                                      _medicine.shelfLifeStatus == 'completed'
                                      ? const Icon(
                                          LucideIcons.sparkles,
                                          color: Colors.amber,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Sekcja 1: Termin ważności
                            Text(
                              'Termin ważności',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6b7280),
                                  ),
                            ),
                            const SizedBox(height: 8),
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
                                            child: Text(
                                              m.toString().padLeft(2, '0'),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setBottomSheetState(
                                      () => selectedMonth = v!,
                                    ),
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
                                    items:
                                        List.generate(
                                              15,
                                              (i) => currentYear + i,
                                            )
                                            .map(
                                              (y) => DropdownMenuItem(
                                                value: y,
                                                child: Text(y.toString()),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setBottomSheetState(
                                      () => selectedYear = v!,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Sekcja 2: Ilość
                            Text(
                              'Ilość',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6b7280),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Brak'),
                                  selected: selectedUnit == PackageUnit.none,
                                  onSelected: (_) => setBottomSheetState(
                                    () => selectedUnit = PackageUnit.none,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Sztuki'),
                                  selected: selectedUnit == PackageUnit.pieces,
                                  onSelected: (_) => setBottomSheetState(
                                    () => selectedUnit = PackageUnit.pieces,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('ml'),
                                  selected: selectedUnit == PackageUnit.ml,
                                  onSelected: (_) => setBottomSheetState(
                                    () => selectedUnit = PackageUnit.ml,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Saszetki'),
                                  selected: selectedUnit == PackageUnit.sachets,
                                  onSelected: (_) => setBottomSheetState(
                                    () => selectedUnit = PackageUnit.sachets,
                                  ),
                                ),
                              ],
                            ),

                            // Inputs dla wybranej jednostki
                            if (selectedUnit != PackageUnit.none) ...[
                              const SizedBox(height: 16),
                              // Pojemność opakowania (całkowita)
                              TextField(
                                controller: capacityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Pojemność opakowania',
                                  hintText: 'np. 30',
                                  suffixText: selectedUnit == PackageUnit.pieces
                                      ? 'szt.'
                                      : selectedUnit == PackageUnit.ml
                                      ? 'ml'
                                      : 'saszetki',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  // Przelicz procent jeśli mamy pieceCount
                                  final capacity = int.tryParse(value);
                                  final piece = int.tryParse(
                                    pieceController.text,
                                  );
                                  if (capacity != null &&
                                      capacity > 0 &&
                                      piece != null &&
                                      !isSyncingFromPercent) {
                                    isSyncingFromPiece = true;
                                    final percent = ((piece / capacity) * 100)
                                        .round()
                                        .clamp(0, 100);
                                    percentController.text = percent.toString();
                                    isSyncingFromPiece = false;
                                  }
                                },
                              ),

                              // Pozostała ilość (tylko dla otwartych)
                              if (isOpen) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: pieceController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Pozostała ilość',
                                    hintText: 'np. 15',
                                    suffixText:
                                        selectedUnit == PackageUnit.pieces
                                        ? 'szt.'
                                        : selectedUnit == PackageUnit.ml
                                        ? 'ml'
                                        : 'saszetki',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    // Sync: pieceCount → percentRemaining
                                    if (isSyncingFromPercent) return;
                                    final capacity = int.tryParse(
                                      capacityController.text,
                                    );
                                    final piece = int.tryParse(value);
                                    if (capacity != null &&
                                        capacity > 0 &&
                                        piece != null) {
                                      isSyncingFromPiece = true;
                                      final percent = ((piece / capacity) * 100)
                                          .round()
                                          .clamp(0, 100);
                                      percentController.text = percent
                                          .toString();
                                      setBottomSheetState(() {});
                                      isSyncingFromPiece = false;
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: percentController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Pozostało procent',
                                    hintText: 'np. 50',
                                    suffixText: '%',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    // Sync: percentRemaining → pieceCount
                                    if (isSyncingFromPiece) return;
                                    final capacity = int.tryParse(
                                      capacityController.text,
                                    );
                                    final percent = int.tryParse(value);
                                    if (capacity != null &&
                                        capacity > 0 &&
                                        percent != null) {
                                      isSyncingFromPercent = true;
                                      final piece = ((capacity * percent) / 100)
                                          .round();
                                      pieceController.text = piece.toString();
                                      setBottomSheetState(() {});
                                      isSyncingFromPercent = false;
                                    }
                                  },
                                ),
                              ],
                            ],

                            const SizedBox(height: 20),

                            // Sekcja 3: Status opakowania
                            Text(
                              'Status opakowania',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6b7280),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Zamknięte'),
                                  selected: !isOpen,
                                  onSelected: (_) => setBottomSheetState(() {
                                    isOpen = false;
                                    percentController.clear();
                                  }),
                                ),
                                ChoiceChip(
                                  label: const Text('Otwarte'),
                                  selected: isOpen,
                                  onSelected: (_) =>
                                      setBottomSheetState(() => isOpen = true),
                                ),
                              ],
                            ),

                            // Sekcja 4: Data otwarcia (tylko gdy otwarte)
                            if (isOpen) ...[
                              const SizedBox(height: 20),
                              Text(
                                'Data otwarcia (opcjonalne)',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6b7280),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Data otwarcia',
                                        hintText: 'Wybierz datę',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            LucideIcons.calendar,
                                          ),
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  openedDate ?? DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now(),
                                            );
                                            if (picked != null) {
                                              setBottomSheetState(
                                                () => openedDate = picked,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      controller: TextEditingController(
                                        text: openedDate != null
                                            ? '${openedDate!.day.toString().padLeft(2, '0')}.${openedDate!.month.toString().padLeft(2, '0')}.${openedDate!.year}'
                                            : '',
                                      ),
                                    ),
                                  ),
                                  if (openedDate != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(LucideIcons.x),
                                      onPressed: () => setBottomSheetState(
                                        () => openedDate = null,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Anuluj'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final lastDay = DateTime(
                                  selectedYear,
                                  selectedMonth + 1,
                                  0,
                                );
                                Navigator.pop(context, {
                                  'expiryDate': lastDay.toIso8601String().split(
                                    'T',
                                  )[0],
                                  'isOpen': isOpen,
                                  'unit': selectedUnit,
                                  'capacity': selectedUnit != PackageUnit.none
                                      ? int.tryParse(capacityController.text)
                                      : null,
                                  'pieceCount': selectedUnit != PackageUnit.none
                                      ? int.tryParse(pieceController.text)
                                      : null,
                                  'percentRemaining':
                                      isOpen && selectedUnit != PackageUnit.none
                                      ? int.tryParse(percentController.text)
                                      : null,
                                  'openedDate': isOpen && openedDate != null
                                      ? openedDate!.toIso8601String().split(
                                          'T',
                                        )[0]
                                      : null,
                                });
                              },
                              child: const Text('Zapisz'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != null && widget.storageService != null) {
      final updatedPackage = MedicinePackage(
        id: package.id,
        expiryDate: result['expiryDate'] as String,
        isOpen: result['isOpen'] as bool,
        unit: result['unit'] as PackageUnit,
        capacity: result['capacity'] as int?,
        pieceCount: result['pieceCount'] as int?,
        percentRemaining: result['percentRemaining'] as int?,
        openedDate: result['openedDate'] as String?,
      );
      final updatedPackages = _medicine.packages
          .map((p) => p.id == package.id ? updatedPackage : p)
          .toList();
      final updatedMedicine = _medicine.copyWith(packages: updatedPackages);
      await widget.storageService!.saveMedicine(updatedMedicine);
      setState(() {
        _medicine = updatedMedicine;
      });
      widget.onMedicineUpdated?.call();
    }
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
        // H1: Kalkulator zapasu leku
        Text(
          'Kalkulator zapasu leku',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // H2: Zapas leku do [→] + CTA
        Row(
          children: [
            Text(
              'Zapas leku do',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.arrowRight,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            // CTA buttons (bez zmian)
            if (canCalculate && supplyEndDate == null)
              GestureDetector(
                onTap: () => _showSetDailyIntakeDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: NeuDecoration.flatSmall(
                    isDark: isDark,
                    radius: 12,
                  ),
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
            else if (canCalculate && supplyEndDate != null)
              _buildSupplyResultCompact(context, theme, isDark, supplyEndDate),
          ],
        ),

        // H3: Wypełnij Szczegóły (tylko gdy !canCalculate)
        if (!canCalculate) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                LucideIcons.cornerLeftDown,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Wypełnij Szczegóły leku by odblokować kalkulator',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSupplyResultCompact(
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
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showSetDailyIntakeDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendarOff,
                  size: 18,
                  color: daysRemaining <= 7
                      ? AppColors.expired
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: daysRemaining <= 7
                        ? AppColors.expired
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' (za $daysRemaining dni)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
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
        // Row z dwoma CTA: Szczegóły (50%) + Zwiń (50%)
        Row(
          children: [
            // Lewa połowa: Szczegóły (rozwija do stanu szczegółowego)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMoreExpanded = !_isMoreExpanded),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                        _isMoreExpanded ? 'Mniej' : 'Szczegóły',
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
            ),
            // Prawa połowa: Zwiń (zwija do compact)
            Expanded(
              child: GestureDetector(
                onTap: widget.onExpand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Zwiń',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.chevronUp,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Separator po Szczegóły (gdy rozwinięte)
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
                        // === TERMIN WAŻNOŚCI (przeniesiony) ===
                        _buildPackagesSection(
                          context,
                          theme,
                          isDark,
                          _getStatusColor(_medicine.expiryStatus),
                        ),

                        // === KALKULATOR ZAPASU (przeniesiony) ===
                        const SizedBox(height: 16),
                        _buildSupplyCalculatorSection(context, theme, isDark),

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

                        // === OKRES PRZYDATNOŚCI PO OTWARCIU ===
                        const SizedBox(height: 16),
                        _buildShelfLifeBadge(context, theme, isDark),

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

  Widget _buildDeleteSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        // Usuń lek button (flat style, no shadows)
        // W trybie edycji pokazuj tylko ikonę, żeby zmieścić inne przyciski
        GestureDetector(
          onTap: () => _showDeleteConfirmationDialog(context),
          child: Container(
            padding: _isEditModeActive
                ? const EdgeInsets.all(10)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                if (!_isEditModeActive) ...[
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
              ],
            ),
          ),
        ),
        // Przycisk zmiany nazwy dla niezweryfikowanych leków (tylko w trybie edycji)
        if (_isEditModeActive && !_medicine.isVerifiedByBarcode) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => _showEditNameDialog(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Icon(
                  LucideIcons.textCursorInput,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        // Przycisk Tryb edycji (ukryty gdy ustawienie "zawsze aktywny" włączone)
        if (_showEditModeButton)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => setState(
                () => _isEditModeButtonActive = !_isEditModeButtonActive,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: _isEditModeButtonActive
                    ? NeuDecoration.pressedSmall(isDark: isDark, radius: 12)
                    : NeuDecoration.flatSmall(isDark: isDark, radius: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditModeButtonActive
                          ? LucideIcons.pencilOff
                          : LucideIcons.pencil,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    // Tekst tylko gdy tryb edycji nieaktywny (ikona zajmuje mniej miejsca)
                    if (!_isEditModeButtonActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Tryb edycji',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: widget.onExpand,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
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
                hintText: 'np. 2 (0 = anuluj)',
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

    if (result != null) {
      // 0 = anuluj kalkulację (user przestał brać tabletki)
      final updated = _medicine.copyWith(
        dailyIntake: result == 0 ? null : result,
      );
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

  /// Sekcja: Okres przydatności po otwarciu (shelf life) - powiększona wersja
  Widget _buildShelfLifeBadge(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final status = _medicine.shelfLifeStatus;
    final shelfLife = _medicine.shelfLifeAfterOpening;

    // completed - znaleziono w ulotce
    if (status == 'completed' && shelfLife != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.valid.withAlpha(isDark ? 30 : 20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.valid.withAlpha(50), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek z ikonami
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.valid),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Okres przydatności po otwarciu sprawdzono w ulotce',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.valid,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: AppColors.valid.withAlpha(180),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Cytat z wcięciem (na wzór Outlook quoted)
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.valid.withAlpha(100),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                shelfLife,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.valid,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // manual - ręcznie wprowadzony
    if (status == 'manual' && shelfLife != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.valid.withAlpha(isDark ? 30 : 20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.valid.withAlpha(50), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.valid),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Okres przydatności po otwarciu (wprowadzono ręcznie)',
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.valid.withAlpha(100),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                shelfLife,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.valid,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // pending - analiza w toku
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Okres przydatności po otwarciu - Sprawdzam w ulotce',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              LucideIcons.sparkles,
              size: 14,
              color: theme.colorScheme.primary.withAlpha(180),
            ),
          ],
        ),
      );
    }

    // error - błąd analizy
    if (status == 'error') {
      return GestureDetector(
        onTap: () => _retryShelfLifeAnalysis(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.expiringSoon.withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.expiringSoon.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: AppColors.expiringSoon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Okres przydatności po otwarciu - Błąd',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.expiringSoon,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: AppColors.expiringSoon.withAlpha(180),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.refreshCw,
                size: 14,
                color: AppColors.expiringSoon,
              ),
            ],
          ),
        ),
      );
    }

    // not_found - nie znaleziono, pokaż pole ręcznego wpisu
    if (status == 'not_found') {
      final controller = TextEditingController(text: shelfLife ?? '');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withAlpha(isDark ? 15 : 10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(30),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Okres przydatności po otwarciu - Nie znaleziono... wprowadź ręcznie poniżej',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'np. 6 miesięcy, 30 dni',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  fontStyle: FontStyle.italic,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _saveManualShelfLife(value);
                }
              },
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  _saveManualShelfLife(value);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.save,
                      size: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Zapisz',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // null - brak statusu, CTA do uruchomienia analizy
    return GestureDetector(
      onTap: () => _startShelfLifeAnalysis(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withAlpha(isDark ? 15 : 10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(30),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Okres przydatności po otwarciu - Zweryfikuj z AI',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Uruchamia analizę shelf life
  void _startShelfLifeAnalysis() {
    if (_medicine.leafletUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak ulotki do analizy'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _analyzeShelfLife();
  }

  /// Ponawia analizę shelf life po błędzie
  void _retryShelfLifeAnalysis() {
    if (_medicine.leafletUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak ulotki do analizy'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _analyzeShelfLife();
  }

  /// Wykonuje analizę shelf life w tle
  Future<void> _analyzeShelfLife() async {
    _log.info('Starting shelf life analysis for ${_medicine.nazwa}');

    // Ustaw status na "pending"
    final pendingMedicine = _medicine.copyWith(shelfLifeStatus: 'pending');
    await widget.storageService?.saveMedicine(pendingMedicine);
    setState(() => _medicine = pendingMedicine);
    widget.onMedicineUpdated?.call();

    try {
      final service = GeminiShelfLifeService();
      final result = await service.analyzeLeaflet(_medicine.leafletUrl!);

      if (result.found) {
        // Znaleziono informację
        final updatedMedicine = _medicine.copyWith(
          shelfLifeAfterOpening: result.shelfLife,
          shelfLifeStatus: 'completed',
        );
        await widget.storageService?.saveMedicine(updatedMedicine);
        setState(() => _medicine = updatedMedicine);
        widget.onMedicineUpdated?.call();

        _log.info('Shelf life analysis completed: ${result.period}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Znaleziono: ${result.period}'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.valid,
            ),
          );
        }
      } else {
        // Nie znaleziono w ulotce (to nie jest błąd!)
        final updatedMedicine = _medicine.copyWith(
          shelfLifeStatus: 'not_found',
        );
        await widget.storageService?.saveMedicine(updatedMedicine);
        setState(() => _medicine = updatedMedicine);
        widget.onMedicineUpdated?.call();

        _log.info('Shelf life not found in leaflet: ${result.reason}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Nie znaleziono w ulotce. Możesz wprowadzić ręcznie poniżej',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      _log.severe('Error analyzing shelf life: $e');

      final updatedMedicine = _medicine.copyWith(shelfLifeStatus: 'error');
      await widget.storageService?.saveMedicine(updatedMedicine);
      setState(() => _medicine = updatedMedicine);
      widget.onMedicineUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd analizy: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Buduje opis statusu opakowania z opcjonalnym shelf life info i walidacją
  Widget _buildPackageStatusDescription(
    BuildContext context,
    ThemeData theme,
    MedicinePackage package,
  ) {
    final shelfLife = _medicine.shelfLifeAfterOpening;
    final hasShelfLife = shelfLife != null && package.isOpen;

    // Walidacja wygaśnięcia po otwarciu
    bool isExpiredAfterOpening = false;
    String? expiryDateStr;

    if (hasShelfLife &&
        package.openedDate != null &&
        (_medicine.shelfLifeStatus == 'completed' ||
            _medicine.shelfLifeStatus == 'manual')) {
      // Parsuj okres z natural language
      final parsed = ShelfLifeParser.parse(shelfLife);
      if (parsed.isValid && parsed.days != null) {
        isExpiredAfterOpening = ShelfLifeParser.isExpired(
          package.openedDate!,
          parsed.days!,
        );
        expiryDateStr = ShelfLifeParser.formatExpiryDate(
          package.openedDate!,
          parsed.days!,
        );
      }
    }

    // Pojedyncza linia z "Zużyć przed" włączonym w opis
    final description = package.getDescription(useByDate: expiryDateStr);

    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 2),
      child: GestureDetector(
        onTap: () => _showPackageDetailsBottomSheet(context, package),
        child: Row(
          children: [
            // Ostrzeżenie o wygaśnięciu
            if (isExpiredAfterOpening) ...[
              Icon(
                LucideIcons.triangleAlert,
                size: 12,
                color: AppColors.expired,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                '└─ $description',
                style: TextStyle(
                  fontSize: 11,
                  color: isExpiredAfterOpening
                      ? AppColors.expired
                      : theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontWeight: isExpiredAfterOpening
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(UserLabel label, bool isDark) {
    final colorInfo = labelColors[label.color]!;
    final bgColor = Color(colorInfo.hexValue);
    final textColor = _getContrastColor(bgColor);

    return GestureDetector(
      onTap: () => widget.onLabelTap?.call(label.id),
      child: Container(
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
    return GestureDetector(
      onTap: () => widget.onTagTap?.call(tag),
      child: Container(
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

/// Helper class dla Smart Hybrid Stock
/// Przechowuje informacje o ważności leku do wyświetlenia w compakt mode
class _ValidityInfo {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDanger;
  final bool isWarning;

  const _ValidityInfo({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDanger,
    required this.isWarning,
  });
}
