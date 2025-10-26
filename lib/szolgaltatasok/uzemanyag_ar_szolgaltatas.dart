// lib/szolgaltatasok/uzemanyag_ar_szolgaltatas.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UzemanyagArak {
  final double benzinAr;
  final double gazolajAr;

  UzemanyagArak({required this.benzinAr, required this.gazolajAr});
}

class UzemanyagArSzolgaltatas {
  // A te saját, megbízható API végpontod
  final String _apiUrl = "https://raw.githubusercontent.com/shiftyy09/uzemanyag-arak/main/arak.json";

  Future<UzemanyagArak?> fetchFuelPrices() async {
    try {
      // === GYORSÍTÓTÁR-KIKERÜLŐ JAVÍTÁS ===
      // Hozzáadunk egy egyedi, mindig változó paramétert az URL végéhez,
      // hogy a szerver ne a gyorsítótárból adja vissza a régi, hibás fájlt.
      final cacheBuster = DateTime
          .now()
          .millisecondsSinceEpoch;
      final urlWithCacheBuster = Uri.parse('$_apiUrl?v=$cacheBuster');
      // ============================================

      final response = await http
          .get(urlWithCacheBuster) // Itt már a módosított URL-t használjuk
          .timeout(const Duration(seconds: 10)); // Időtúllépés 10 mp után

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // A te saját, egyszerű JSON struktúrád feldolgozása
        final double benzin = (data['benzin'] as num?)?.toDouble() ?? 0;
        final double gazolaj = (data['gazolaj'] as num?)?.toDouble() ?? 0;

        if (benzin > 0 && gazolaj > 0) {
          print(
              "SIKER (Saját API): Árak sikeresen lekérdezve: Benzin: $benzin, Gázolaj: $gazolaj");
          return UzemanyagArak(benzinAr: benzin, gazolajAr: gazolaj);
        }
      }
      // Ha az URL valamiért nem elérhető (pl. GitHub hiba)
      print(
          "HIBA: A saját API nem adott vissza érvényes adatot. Státuszkód: ${response
              .statusCode}");
      return null;
    } catch (e) {
      // Bármilyen egyéb hiba esetén (pl. nincs internet, formátumhiba a JSON-ban)
      print("VÉGZETES HIBA a saját API lekérdezése közben: $e");
      return null;
    }
  }
}
