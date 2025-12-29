import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';
import '../models/label.dart';

/// Serwis do przechowywania danych lokalnie (Hive)
class StorageService {
  static const String _medicinesBoxName = 'medicines';
  static const String _labelsBoxName = 'labels';

  late Box<String> _medicinesBox;
  late Box<String> _labelsBox;

  /// Inicjalizacja Hive
  Future<void> init() async {
    await Hive.initFlutter();
    _medicinesBox = await Hive.openBox<String>(_medicinesBoxName);
    _labelsBox = await Hive.openBox<String>(_labelsBoxName);
  }

  // ==================== MEDICINES ====================

  /// Pobiera wszystkie leki
  List<Medicine> getMedicines() {
    final List<Medicine> medicines = [];
    for (final key in _medicinesBox.keys) {
      final json = _medicinesBox.get(key);
      if (json != null) {
        try {
          medicines.add(Medicine.fromJson(jsonDecode(json)));
        } catch (e) {
          // Ignoruj uszkodzone wpisy
        }
      }
    }
    return medicines;
  }

  /// Zapisuje lek
  Future<void> saveMedicine(Medicine medicine) async {
    await _medicinesBox.put(medicine.id, jsonEncode(medicine.toJson()));
  }

  /// Usuwa lek
  Future<void> deleteMedicine(String id) async {
    await _medicinesBox.delete(id);
  }

  /// Czyści wszystkie leki
  Future<void> clearMedicines() async {
    await _medicinesBox.clear();
  }

  /// Importuje leki z JSON
  Future<int> importMedicines(List<Medicine> medicines) async {
    int count = 0;
    for (final medicine in medicines) {
      await saveMedicine(medicine);
      count++;
    }
    return count;
  }

  /// Eksportuje wszystkie leki i etykiety do JSON (kompatybilny z web)
  String exportToJson() {
    final medicines = getMedicines();
    final labels = getLabels();
    return jsonEncode({
      'leki': medicines.map((m) => m.toJson()).toList(),
      'labels': labels.map((l) => l.toJson()).toList(),
    });
  }

  // ==================== LABELS ====================

  /// Pobiera wszystkie etykiety (posortowane po kolejności)
  List<UserLabel> getLabels() {
    final List<UserLabel> labels = [];
    for (final key in _labelsBox.keys) {
      final json = _labelsBox.get(key);
      if (json != null) {
        try {
          labels.add(UserLabel.fromJson(jsonDecode(json)));
        } catch (e) {
          // Ignoruj uszkodzone wpisy
        }
      }
    }
    // Sortuj po kolejności (order)
    labels.sort((a, b) => a.order.compareTo(b.order));
    return labels;
  }

  /// Zapisuje etykietę
  Future<void> saveLabel(UserLabel label) async {
    await _labelsBox.put(label.id, jsonEncode(label.toJson()));
  }

  /// Usuwa etykietę
  Future<void> deleteLabel(String id) async {
    await _labelsBox.delete(id);

    // Usuń referencje z wszystkich leków
    final medicines = getMedicines();
    for (final medicine in medicines) {
      if (medicine.labels.contains(id)) {
        final updatedLabels = medicine.labels.where((l) => l != id).toList();
        await saveMedicine(medicine.copyWith(labels: updatedLabels));
      }
    }
  }

  /// Aktualizuje etykietę
  Future<void> updateLabel(UserLabel label) async {
    await saveLabel(label);
  }

  /// Pobiera etykiety po ID
  List<UserLabel> getLabelsByIds(List<String> ids) {
    final allLabels = getLabels();
    return allLabels.where((l) => ids.contains(l.id)).toList();
  }

  /// Czyści wszystkie etykiety
  Future<void> clearLabels() async {
    await _labelsBox.clear();
  }

  /// Zapisuje nową kolejność etykiet
  Future<void> reorderLabels(List<UserLabel> labels) async {
    for (int i = 0; i < labels.length; i++) {
      final updatedLabel = labels[i].copyWith(order: i);
      await saveLabel(updatedLabel);
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Zwraca nazwy leków jako string "lek1, lek2, lek3"
  String getMedicineNamesString() {
    final medicines = getMedicines();
    return medicines.map((m) => m.nazwa ?? 'Nieznany').join(', ');
  }

  /// Aktualizuje URL ulotki dla leku
  Future<void> updateMedicineLeaflet(String id, String? leafletUrl) async {
    final medicines = getMedicines();
    final index = medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updated = medicines[index].copyWith(leafletUrl: leafletUrl);
      await saveMedicine(updated);
    }
  }

  /// Aktualizuje notatkę leku
  Future<void> updateMedicineNote(String id, String? note) async {
    final medicines = getMedicines();
    final index = medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updated = medicines[index].copyWith(notatka: note);
      await saveMedicine(updated);
    }
  }

  /// Pobiera wszystkie custom tagi (nie predefiniowane)
  List<String> getCustomTags(Set<String> predefinedTags) {
    final allTags = <String>{};
    for (final medicine in getMedicines()) {
      allTags.addAll(medicine.tagi);
    }
    return allTags.where((t) => !predefinedTags.contains(t)).toList()..sort();
  }

  /// Usuwa custom tag ze wszystkich leków
  Future<void> deleteCustomTag(String tag) async {
    final medicines = getMedicines();
    for (final medicine in medicines) {
      if (medicine.tagi.contains(tag)) {
        final updatedTags = medicine.tagi.where((t) => t != tag).toList();
        await saveMedicine(medicine.copyWith(tagi: updatedTags));
      }
    }
  }

  /// Aktualizuje etykiety leku
  Future<void> updateMedicineLabels(String id, List<String> labelIds) async {
    final medicines = getMedicines();
    final index = medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updated = medicines[index].copyWith(labels: labelIds);
      await saveMedicine(updated);
    }
  }
}
