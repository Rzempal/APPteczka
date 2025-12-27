import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';

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
}
