import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Serwis do cache'owania plików PDF ulotek offline
/// Limit cache: 100MB (FIFO - najstarsze usuwane automatycznie)
class PdfCacheService {
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const String _cacheDir = 'leaflets';

  /// Pobiera katalog cache
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDir');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generuje nazwę pliku z URL
  String _getFileName(String medicineId) {
    return 'leaflet_$medicineId.pdf';
  }

  /// Sprawdza czy PDF jest w cache
  Future<bool> isCached(String medicineId) async {
    final cacheDir = await _getCacheDirectory();
    final file = File('${cacheDir.path}/${_getFileName(medicineId)}');
    return file.exists();
  }

  /// Pobiera ścieżkę do pliku PDF (z cache lub pobiera z sieci)
  /// Zwraca null jeśli pobieranie się nie powiodło
  Future<File?> getPdfFile(String url, String medicineId) async {
    final cacheDir = await _getCacheDirectory();
    final fileName = _getFileName(medicineId);
    final file = File('${cacheDir.path}/$fileName');

    // Jeśli jest w cache, zwróć
    if (await file.exists()) {
      // Zaktualizuj czas modyfikacji (dla FIFO)
      await file.setLastModified(DateTime.now());
      return file;
    }

    // Pobierz z sieci
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Sprawdź limit cache przed zapisem
        await _enforceCache();

        // Zapisz do pliku
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      // Błąd pobierania - zwróć null
    }

    return null;
  }

  /// Usuwa PDF z cache
  Future<void> clearCache(String medicineId) async {
    final cacheDir = await _getCacheDirectory();
    final file = File('${cacheDir.path}/${_getFileName(medicineId)}');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Czyści cały cache
  Future<void> clearAllCache() async {
    final cacheDir = await _getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }
  }

  /// Wymusza limit cache (usuwa najstarsze pliki gdy przekroczone 100MB)
  Future<void> _enforceCache() async {
    final cacheDir = await _getCacheDirectory();
    final files = await cacheDir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    if (files.isEmpty) return;

    // Oblicz rozmiar cache
    int totalSize = 0;
    for (final file in files) {
      final stat = await file.stat();
      totalSize += stat.size;
    }

    // Jeśli poniżej limitu, nic nie rób
    if (totalSize < _maxCacheSizeBytes) return;

    // Sortuj po czasie modyfikacji (najstarsze najpierw)
    final sortedFiles = <MapEntry<File, int>>[];
    for (final file in files) {
      final stat = await file.stat();
      sortedFiles.add(MapEntry(file, stat.modified.millisecondsSinceEpoch));
    }
    sortedFiles.sort((a, b) => a.value.compareTo(b.value));

    // Usuwaj najstarsze aż zmieścimy się w limicie
    for (final entry in sortedFiles) {
      if (totalSize < _maxCacheSizeBytes * 0.8) break; // Zostaw 20% marginesu

      final stat = await entry.key.stat();
      totalSize -= stat.size;
      await entry.key.delete();
    }
  }

  /// Zwraca rozmiar cache w bajtach
  Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDirectory();
    int totalSize = 0;

    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return totalSize;
  }
}
