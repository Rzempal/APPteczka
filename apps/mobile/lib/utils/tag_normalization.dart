// lib/utils/tag_normalization.dart
// Normalizacja i rozszerzanie tagów leków

/// Mapowanie synonimów tagów na formy kanoniczne
const Map<String, String> tagSynonyms = {
  // Rodzaj leku - zamiana terminologii OTC/Rx
  'lek OTC': 'bez recepty',
  'OTC': 'bez recepty',
  'otc': 'bez recepty',
  'lek Rx': 'na receptę',
  'Rx': 'na receptę',
  'rx': 'na receptę',
  'recepta': 'na receptę',
};

/// Implikacje tagów - automatyczne dodawanie powiązanych tagów
/// Klucz: tag wejściowy (objaw szczegółowy)
/// Wartość: tagi do automatycznego dodania
const Map<String, List<String>> tagImplications = {
  // Bóle → ogólny ból + działanie przeciwbólowe
  'ból głowy': ['ból', 'przeciwbólowy'],
  'ból gardła': ['ból', 'przeciwbólowy'],
  'ból mięśni': ['ból', 'przeciwbólowy'],
  'ból menstruacyjny': ['ból', 'przeciwbólowy', 'rozkurczowy'],
  'ból ucha': ['ból', 'przeciwbólowy'],

  // Objawy → działanie leczące
  'gorączka': ['przeciwgorączkowy'],
  'kaszel': ['przeciwkaszlowy'],
  'biegunka': ['przeciwbiegunkowy'],
  'nudności': ['przeciwwymiotny'],
  'wymioty': ['przeciwwymiotny'],
  'alergia': ['przeciwhistaminowy'],
  'świąd': ['przeciwświądowy'],
  'zaparcia': ['przeczyszczający'],
};

/// Normalizuje pojedynczy tag (zamienia synonimy na formę kanoniczną)
String normalizeTag(String tag) {
  final trimmed = tag.trim();
  return tagSynonyms[trimmed] ?? trimmed;
}

/// Normalizuje listę tagów (zamienia synonimy)
List<String> normalizeTags(List<String> tags) {
  return tags.map(normalizeTag).toList();
}

/// Rozszerza tagi o implikowane (np. "ból głowy" → +ból +przeciwbólowy)
List<String> expandTags(List<String> tags) {
  final expanded = Set<String>.from(tags);

  for (final tag in tags) {
    final implied = tagImplications[tag];
    if (implied != null) {
      expanded.addAll(implied);
    }
  }

  return expanded.toList();
}

/// Pełna normalizacja: synonimy + rozszerzenie
/// Używać przy imporcie leków i OCR
List<String> processTagsForImport(List<String> tags) {
  final normalized = normalizeTags(tags);
  return expandTags(normalized);
}
