// pharmaceutical_form_helper.dart
// Helper do mapowania postaci farmaceutycznej na ikonę i jednostkę
// Źródło danych: pole pharmaceuticalFormName z API RPL (eZdrowie)

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';

class PharmaceuticalFormDefinition {
  final String mainName;
  final String description; // Warianty (aliasy)
  final IconData icon;
  final PackageUnit unit;

  const PharmaceuticalFormDefinition({
    required this.mainName,
    required this.description,
    required this.icon,
    required this.unit,
  });

  String get displayName => mainName;
}

/// Helper do mapowania postaci farmaceutycznej na ikonę i jednostkę opakowania
class PharmaceuticalFormHelper {
  static const List<PharmaceuticalFormDefinition> _definitions = [
    PharmaceuticalFormDefinition(
      mainName: 'Tabletki',
      description: 'pastylki, tabletki do ssania',
      icon: LucideIcons.tablets,
      unit: PackageUnit.pieces,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Kapsułki',
      description: 'pigułki, opłatki',
      icon: LucideIcons.pill,
      unit: PackageUnit.pieces,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Saszetki',
      description: '',
      icon: LucideIcons.stickyNote,
      unit: PackageUnit.sachets,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Proszki',
      description: 'zawiesiny, mikstury',
      icon: LucideIcons.waves,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Plastry lecznicze',
      description: 'okłady',
      icon: LucideIcons.bandage,
      unit: PackageUnit.pieces,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Syropy',
      description: 'eliksiry, roztwory',
      icon: LucideIcons.flaskConical,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Maści',
      description: 'żele, kremy',
      icon: LucideIcons.droplet,
      unit: PackageUnit.grams,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Krople',
      description: 'oczne, do uszu, do nosa',
      icon: LucideIcons.droplets,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Krople doustne',
      description: 'koloidy',
      icon: LucideIcons.glassWater,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Aerozole',
      description: 'spraye',
      icon: LucideIcons.sprayCan,
      unit: PackageUnit
          .pieces, // Zmieniłem na pieces/dawki, ale PackageUnit ma ograniczony set
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Iniekcje',
      description: 'zastrzyki, ampułki',
      icon: LucideIcons.syringe,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Infuzje',
      description: 'kroplówki, irygacje',
      icon: LucideIcons.pipette,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Inhalacje',
      description: 'insuflacje',
      icon: LucideIcons.wind,
      unit: PackageUnit.pieces, // Dawki -> pieces
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Czopki',
      description: 'globulki',
      icon: LucideIcons.thermometer,
      unit: PackageUnit.pieces,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Płukanki',
      description: '',
      icon: LucideIcons.cupSoda,
      unit: PackageUnit.ml,
    ),
    PharmaceuticalFormDefinition(
      mainName: 'Produkty sterylne',
      description: '',
      icon: LucideIcons.stethoscope,
      unit: PackageUnit.pieces,
    ),
  ];

  /// Zwraca listę wszystkich definicji (do użycia w UI Dropdowna)
  static List<PharmaceuticalFormDefinition> get definitions => _definitions;

  /// Lista nazw głównych (zachowanie kompatybilności tam gdzie oczekiwana jest lista stringów)
  static List<String> get predefinedForms =>
      _definitions.map((e) => e.mainName).toList();

  /// Znajduje definicję pasującą do danej nazwy (szuka w mainName i description)
  static PharmaceuticalFormDefinition? _findDefinition(String? form) {
    if (form == null || form.isEmpty) return null;
    final normalized = form.toLowerCase().trim();

    // 1. Exact match on main name
    try {
      return _definitions.firstWhere(
        (d) => d.mainName.toLowerCase() == normalized,
      );
    } catch (_) {}

    // 2. Contains match on main name or description
    try {
      return _definitions.firstWhere(
        (d) =>
            d.mainName.toLowerCase().contains(normalized) ||
            d.description.toLowerCase().contains(normalized),
      );
    } catch (_) {}

    return null;
  }

  /// Zwraca ikonę Lucide dla postaci farmaceutycznej
  static IconData getIcon(String? form) {
    if (form == null || form.isEmpty) return LucideIcons.pill;
    final def = _findDefinition(form);
    return def?.icon ?? LucideIcons.pill;
  }

  /// Zwraca jednostkę opakowania dla postaci farmaceutycznej
  static PackageUnit getPackageUnit(String? form) {
    if (form == null || form.isEmpty) return PackageUnit.pieces;
    final def = _findDefinition(form);
    return def?.unit ?? PackageUnit.pieces;
  }

  /// Zwraca opis pomocniczy (description)
  static String getDescription(String? form) {
    if (form == null || form.isEmpty) return '';
    final def = _findDefinition(form);
    // Jeśli znaleziono definicję, upewnijmy się, że nie zwracamy opisu dla formy która nie jest 'Main Name'
    // Tzn. jeśli user wpisał 'pastylki', a my zmapowaliśmy to na 'Tabletki', to description 'pastylki...' jest ok.
    return def?.description ?? '';
  }

  /// Zwraca etykietę jednostki
  static String getUnitLabel(String? form) {
    final unit = getPackageUnit(form);
    switch (unit) {
      case PackageUnit.pieces:
        return 'szt.';
      case PackageUnit.ml:
        return 'ml';
      case PackageUnit.grams:
        return 'g';
      case PackageUnit.sachets:
        return 'sasz.';
      case PackageUnit.none:
        return '';
    }
  }

  /// Parsuje string capacity z Gemini na (int, PackageUnit)
  static CapacityParseResult? parseCapacity(String? capacity) {
    if (capacity == null || capacity.isEmpty) {
      return null;
    }

    final normalized = capacity.toLowerCase().trim();
    final regex = RegExp(r'(\d+)\s*(.*)');
    final match = regex.firstMatch(normalized);

    if (match == null) {
      return null;
    }

    final value = int.tryParse(match.group(1) ?? '');
    if (value == null || value <= 0) {
      return null;
    }

    final unitText = match.group(2)?.trim() ?? '';
    final unit = _parseUnitFromText(unitText);

    return CapacityParseResult(value: value, unit: unit);
  }

  static PackageUnit _parseUnitFromText(String unitText) {
    if (unitText.contains('ml') || unitText.contains('mililit')) {
      return PackageUnit.ml;
    }
    if (unitText.startsWith('g') || unitText.contains('gram')) {
      return PackageUnit.grams;
    }
    if (unitText.contains('saszetk') || unitText.contains('sasz')) {
      return PackageUnit.sachets;
    }
    return PackageUnit.pieces;
  }
}

class CapacityParseResult {
  final int value;
  final PackageUnit unit;

  CapacityParseResult({required this.value, required this.unit});
}
