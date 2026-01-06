import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'neumorphic/neumorphic.dart';
import 'filters_sheet.dart'; // Dla tagCategories i tagsObjawIDzialanie

/// Widget do wyboru tagów systemowych z listy pogrupowanej jak w filtrach.
/// Użytkownik może tylko zaznaczać tagi - nie dodawać własnych.
class TagSelectorWidget extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const TagSelectorWidget({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  State<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends State<TagSelectorWidget> {
  final Map<String, bool> _expandedCategories = {};
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Inicjalizuj kategorie jako zwinięte
    _expandedCategories['Klasyfikacja'] = false;
    _expandedCategories['Objawy i działanie'] = false;
  }

  Set<String> get _selectedSet => widget.selectedTags.toSet();

  void _toggleTag(String tag) {
    final newSet = Set<String>.from(_selectedSet);
    if (newSet.contains(tag)) {
      newSet.remove(tag);
    } else {
      newSet.add(tag);
    }
    widget.onChanged(newSet.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header z przyciskiem rozwijania
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: NeuDecoration.flat(isDark: isDark, radius: 12),
            child: Row(
              children: [
                Icon(
                  LucideIcons.tags,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tagi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.selectedTags.isEmpty
                            ? 'Wybierz tagi z listy'
                            : '${widget.selectedTags.length} wybranych',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Wybrane tagi - pokazuj zawsze gdy są
        if (widget.selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                deleteIcon: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onDeleted: () => _toggleTag(tag),
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],

        // Rozwinięta lista kategorii
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withAlpha(150)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Klasyfikacja z podkategoriami
                _buildCategoryWithSubcategories(
                  'Klasyfikacja',
                  tagsKlasyfikacja,
                  isDark,
                ),

                // Objawy i działanie z podkategoriami
                _buildCategoryWithSubcategories(
                  'Objawy i działanie',
                  tagsObjawIDzialanie,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection(String name, List<String> tags, bool isDark) {
    final isExpanded = _expandedCategories[name] ?? false;
    final selectedInCategory = tags
        .where((t) => _selectedSet.contains(t))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[name] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Transform.rotate(
                  angle: isExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (selectedInCategory > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedInCategory',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) => _buildTagChip(tag, isDark)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryWithSubcategories(
    String name,
    Map<String, List<String>> subcategories,
    bool isDark,
  ) {
    final isExpanded = _expandedCategories[name] ?? false;
    final allTags = subcategories.values.expand((t) => t).toList();
    final selectedCount = allTags.where((t) => _selectedSet.contains(t)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[name] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Transform.rotate(
                  angle: isExpanded ? math.pi / 2 : 0,
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (selectedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subcategories.entries.map((subEntry) {
                final subName = subEntry.key;
                final subTags = subEntry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        subName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subTags
                          .map((t) => _buildTagChip(t, isDark))
                          .toList(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTagChip(String tag, bool isDark) {
    final isSelected = _selectedSet.contains(tag);

    return FilterChip(
      selected: isSelected,
      label: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onSelected: (_) => _toggleTag(tag),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
