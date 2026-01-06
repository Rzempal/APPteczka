// lib/utils/tag_normalization.dart
// Normalizacja i rozszerzanie tagów leków

/// Mapowanie synonimów tagów na formy kanoniczne
/// Stare tagi → nowe tagi (migracja ze starych backupów)
const Map<String, String> tagSynonyms = {
  // === RODZAJ LEKU - zamiana terminologii OTC/Rx ===
  'lek OTC': 'bez recepty',
  'OTC': 'bez recepty',
  'otc': 'bez recepty',
  'lek Rx': 'na receptę',
  'Rx': 'na receptę',
  'rx': 'na receptę',
  'recepta': 'na receptę',

  // === STARE RODZAJ PRODUKTU - normalizacja ===
  'test diagnostyczny': 'wyrób medyczny',
  'kosmetyk leczniczy': 'nawilżający',
};

/// Lista starych tagów które są ignorowane (nie mapowane, ale też nie pokazywane jako "nieznane")
/// Te tagi po prostu usuwamy podczas normalizacji
const Set<String> deprecatedTags = {
  'oczy', // stary obszar ciała - zbyt ogólny
  'uszy', // stary obszar ciała - zbyt ogólny
  'dla seniorów', // usunięty z grup docelowych
  'układ krążenia', // stary obszar ciała - brak odpowiednika
  'układ moczowy', // stary obszar ciała - brak odpowiednika
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
/// Zwraca null dla deprecated tagów
String? normalizeTag(String tag) {
  final trimmed = tag.trim();

  // Deprecated tagi - ignorujemy
  if (deprecatedTags.contains(trimmed)) {
    return null;
  }

  return tagSynonyms[trimmed] ?? trimmed;
}

/// Normalizuje listę tagów (zamienia synonimy, usuwa deprecated)
List<String> normalizeTags(List<String> tags) {
  return tags
      .map(normalizeTag)
      .whereType<String>() // Usuwa null (deprecated tagi)
      .toList();
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
