import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wynik wyszukiwania w Rejestrze Produktów Leczniczych
class RplSearchResult {
  final int id;
  final String nazwa;
  final String moc;
  final String postac;
  final String ulotkaUrl;

  RplSearchResult({
    required this.id,
    required this.nazwa,
    required this.moc,
    required this.postac,
    required this.ulotkaUrl,
  });

  factory RplSearchResult.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    return RplSearchResult(
      id: id,
      nazwa: json['medicinalProductName'] as String? ?? '',
      moc: json['medicinalProductPower'] as String? ?? '',
      postac: json['pharmaceuticalFormName'] as String? ?? '',
      ulotkaUrl:
          'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/$id/leaflet',
    );
  }
}

/// Serwis do wyszukiwania leków w Rejestrze Produktów Leczniczych (MZ)
class RplService {
  static const String _baseUrl =
      'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products';

  /// Wyszukuje leki w RPL
  /// [query] - Nazwa leku do wyszukania (min. 3 znaki)
  /// Zwraca listę pasujących leków z linkami do ulotek
  Future<List<RplSearchResult>> searchMedicine(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    final endpoint = Uri.parse(
      '$_baseUrl/search/public?name=${Uri.encodeComponent(query.trim())}&size=10&page=0',
    );

    try {
      final response = await http
          .get(endpoint, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>?;

      if (content == null || content.isEmpty) {
        return [];
      }

      return content
          .map(
            (item) => RplSearchResult.fromApiJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // Błąd sieci lub parsowania - zwróć pustą listę
      return [];
    }
  }
}
