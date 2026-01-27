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
      unit: PackageUnit.doses,
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
      unit: PackageUnit.doses,
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
      case PackageUnit.doses:
        return 'dawki';
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
    if (unitText.contains('dawk') || unitText.contains('doz')) {
      return PackageUnit.doses;
    }
    return PackageUnit.pieces;
  }

  /// Parsuje string packaging na ilość sztuk (logika z AddMedicineScreen)
  /// Np. "28 tabl. (2 x 14)" -> 28, "1 butelka 120 ml" -> 120
  static int? parsePackaging(String? packaging) {
    if (packaging == null || packaging.isEmpty) return null;

    final lower = packaging.toLowerCase();

    // Wzorzec 1: "28 tabl.", "30 kaps.", "10 amp." - rozszerzony o dawk/doz
    final countMatch = RegExp(
      r'^(\d+)\s*(tabl|kaps|amp|sasz|czop|plast|dawk|doz)',
    ).firstMatch(lower);
    if (countMatch != null) {
      return int.tryParse(countMatch.group(1)!);
    }

    // Wzorzec 2: "1 butelka 120 ml", "1 tuba 30 g"
    final volumeMatch = RegExp(r'(\d+)\s*(ml|g)\b').firstMatch(lower);
    if (volumeMatch != null) {
      return int.tryParse(volumeMatch.group(1)!);
    }

    // Wzorzec 3: pierwsza liczba
    final firstNumber = RegExp(r'(\d+)').firstMatch(lower);
    if (firstNumber != null) {
      return int.tryParse(firstNumber.group(1)!);
    }

    return null;
  }

  /// Generuje tagi dla danej postaci farmaceutycznej
  static Set<String> getTagsForForm(String? form) {
    if (form == null || form.isEmpty) return {};
    final formLower = form.toLowerCase();
    final tags = <String>{};

    if (formLower.contains('tabletk')) {
      tags.add('tabletki');
    } else if (formLower.contains('kaps')) {
      tags.add('kapsułki');
    } else if (formLower.contains('syrop')) {
      tags.add('syrop');
    } else if (formLower.contains('masc') || formLower.contains('krem')) {
      tags.add('maść');
    } else if (formLower.contains('zastrzyk') ||
        formLower.contains('iniekcj') ||
        formLower.contains('ampuł')) {
      tags.add('zastrzyki');
    } else if (formLower.contains('krople')) {
      tags.add('krople');
    } else if (formLower.contains('aerozol') || formLower.contains('spray')) {
      tags.add('aerozol');
    } else if (formLower.contains('czopk')) {
      tags.add('czopki');
    } else if (formLower.contains('plast')) {
      tags.add('plastry');
    } else if (formLower.contains('zawies') || formLower.contains('proszek')) {
      tags.add('proszek/zawiesina');
    } else if (formLower.contains('inhal')) {
      tags.add('inhalacja');
    }

    return tags;
  }
}

class CapacityParseResult {
  final int value;
  final PackageUnit unit;

  CapacityParseResult({required this.value, required this.unit});
}
