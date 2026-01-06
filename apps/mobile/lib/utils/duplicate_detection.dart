/// Moduł wykrywania duplikatów leków
/// duplicate_detection.dart v0.001 Implementacja wykrywania duplikatów
import '../models/medicine.dart';

/// Słowa ignorowane przy wykrywaniu duplikatów (warianty, formy, jednostki)
const duplicateStopwords = {
  // Warianty produktu
  'max', 'forte', 'plus', 'junior', 'noc', 'day', 'night', 'express',
  'extra', 'rapid', 'long', 'retard', 'sr', 'xr', 'xl', 'ultra',
  'mini', 'kids', 'baby', 'adult', 'pro', 'sensitive',
  // Formy farmaceutyczne
  'gel', 'maść', 'krem', 'syrop', 'tabletki', 'kapsułki', 'krople',
  'spray', 'proszek', 'zawiesina', 'plastry', 'czopki', 'żel',
  // Jednostki
  'mg', 'ml', 'g', '%', 'mcg', 'iu',
};

/// Minimalna długość słowa do analizy
const int _minWordLength = 3;

/// Maksymalna odległość Levenshteina dla fuzzy matching
const int _maxLevenshteinDistance = 2;

/// Wyodrębnia główną nazwę leku (pierwsze znaczące słowo).
///
/// Przykłady:
/// - "Apap Noc" → "apap"
/// - "Ibuprom Max 400mg" → "ibuprom"
/// - "Voltaren Emulgel" → "voltaren"
String extractPrimaryName(String? name) {
  if (name == null || name.isEmpty) return '';

  // Normalizacja: lowercase, usuń znaki specjalne
  final normalized = name.toLowerCase().replaceAll(
    RegExp(r'[^\w\sąćęłńóśźżĄĆĘŁŃÓŚŹŻ]'),
    ' ',
  );

  // Podziel na słowa
  final words = normalized
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= _minWordLength)
      .where((w) => !duplicateStopwords.contains(w))
      .toList();

  // Zwróć pierwsze znaczące słowo lub puste
  return words.isNotEmpty ? words.first : '';
}

/// Oblicza odległość Levenshteina między dwoma stringami.
/// Używane do fuzzy matching wariantów nazw (np. "Ibuprom" ~ "Ibuprofen").
int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Używamy tylko dwóch wierszy dla optymalizacji pamięci
  List<int> previous = List.generate(b.length + 1, (i) => i);
  List<int> current = List.filled(b.length + 1, 0);

  for (int i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (int j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      current[j + 1] = [
        previous[j + 1] + 1, // deletion
        current[j] + 1, // insertion
        previous[j] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    // Swap rows
    final temp = previous;
    previous = current;
    current = temp;
  }

  return previous[b.length];
}

/// Sprawdza czy dwie nazwy główne są podobne (fuzzy match).
bool areSimilarNames(String name1, String name2) {
  if (name1.isEmpty || name2.isEmpty) return false;

  // Dokładne dopasowanie
  if (name1 == name2) return true;

  // Fuzzy matching dla dłuższych słów (min. 5 znaków)
  if (name1.length >= 5 && name2.length >= 5) {
    final distance = levenshteinDistance(name1, name2);
    // Maksymalna dozwolona odległość zależy od długości słowa
    final maxDistance = (name1.length < 7 || name2.length < 7)
        ? 1 // Dla krótszych słów bardziej restrykcyjnie
        : _maxLevenshteinDistance;
    return distance <= maxDistance;
  }

  return false;
}

/// Grupuje leki według nazwy głównej.
/// Zwraca mapę: nazwa główna → lista leków z tą nazwą.
/// Uwzględnia fuzzy matching dla podobnych nazw.
Map<String, List<Medicine>> findDuplicateGroups(List<Medicine> medicines) {
  // Mapa: nazwa główna → lista leków
  final Map<String, List<Medicine>> groups = {};

  // Mapa cache: ID leku → nazwa główna (dla fuzzy matching)
  final Map<String, String> primaryNames = {};

  for (final medicine in medicines) {
    final primaryName = extractPrimaryName(medicine.nazwa);
    if (primaryName.isEmpty) continue;

    primaryNames[medicine.id] = primaryName;

    // Sprawdź czy pasuje do istniejącej grupy (fuzzy)
    String? matchedGroup;
    for (final existingGroup in groups.keys) {
      if (areSimilarNames(primaryName, existingGroup)) {
        matchedGroup = existingGroup;
        break;
      }
    }

    if (matchedGroup != null) {
      groups[matchedGroup]!.add(medicine);
    } else {
      groups[primaryName] = [medicine];
    }
  }

  // Filtruj grupy - zostaw tylko te z więcej niż 1 lekiem (duplikaty)
  groups.removeWhere((_, meds) => meds.length < 2);

  return groups;
}

/// Sprawdza czy dany lek ma duplikaty w liście.
bool hasDuplicates(Medicine medicine, List<Medicine> allMedicines) {
  final primaryName = extractPrimaryName(medicine.nazwa);
  if (primaryName.isEmpty) return false;

  int count = 0;
  for (final m in allMedicines) {
    if (m.id == medicine.id) continue;
    final otherPrimary = extractPrimaryName(m.nazwa);
    if (areSimilarNames(primaryName, otherPrimary)) {
      count++;
      if (count >= 1) return true; // Wystarczy 1 duplikat
    }
  }

  return false;
}

/// Zwraca liczbę duplikatów dla danego leku.
int countDuplicates(Medicine medicine, List<Medicine> allMedicines) {
  final primaryName = extractPrimaryName(medicine.nazwa);
  if (primaryName.isEmpty) return 0;

  int count = 0;
  for (final m in allMedicines) {
    if (m.id == medicine.id) continue;
    final otherPrimary = extractPrimaryName(m.nazwa);
    if (areSimilarNames(primaryName, otherPrimary)) {
      count++;
    }
  }

  return count;
}
