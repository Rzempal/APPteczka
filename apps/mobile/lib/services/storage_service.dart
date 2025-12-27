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

  /// Eksportuje wszystkie leki do JSON
  String exportToJson() {
    final medicines = getMedicines();
    return jsonEncode({'leki': medicines.map((m) => m.toJson()).toList()});
  }

  // ==================== LABELS ====================

  /// Pobiera wszystkie etykiety
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
}
