// lib/modellek/karbantartas_bejegyzes.dart

class Szerviz {
  final int? id;
  final int vehicleId;
  final String description;
  final DateTime date;
  final num cost; // JAVÍTVA: int -> num (elfogad egész és tizedes törtet is)
  final int mileage;

  Szerviz({
    this.id,
    required this.vehicleId,
    required this.description,
    required this.date,
    required this.cost,
    required this.mileage,
  });

  // Ez a segédfüggvény hasznos, ha egy meglévő objektumot akarsz másolni
  // és csak néhány értékét módosítani. Ezt most nem bántjuk.
  Szerviz copyWith({
    int? id,
    int? vehicleId,
    String? description,
    DateTime? date,
    num? cost, // JAVÍTVA: int? -> num?
    int? mileage,
  }) {
    return Szerviz(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      description: description ?? this.description,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
    );
  }

  // A gyár-konstruktor, ami Map-ből (pl. adatbázisból) hozza létre az objektumot.
  // EZT A RÉSZT JAVÍTOTTUK A LEGNAGYOBB MÉRTÉKBEN.
  factory Szerviz.fromMap(Map<String, dynamic> map) {
    // Biztonságos konverzió a cost mezőre
    num costValue;
    if (map['cost'] is num) {
      costValue = map['cost']; // Ha már szám, elfogadjuk
    } else {
      // Ha nem szám (pl. String a CSV-ből), megpróbáljuk átalakítani
      costValue = num.tryParse(map['cost'].toString()) ?? 0;
    }

    return Szerviz(
      // A többi mező biztonságos kezelése
      id: map['id'] as int?,
      // Lehet null
      vehicleId: map['vehicleId'] as int,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      cost: costValue,
      // A javított érték használata
      mileage: map['mileage'] as int,
    );
  }

  // Adatbázisba íráshoz alakítja vissza az objektumot Map-pé.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'description': description,
      'date': date.toIso8601String(), // Dátumot szöveggé alakítjuk tároláshoz
      'cost': cost,
      'mileage': mileage,
    };
  }
}
