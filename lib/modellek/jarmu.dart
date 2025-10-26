// lib/modellek/jarmu.dart
class Jarmu {
  final int? id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String? vin;
  final int mileage;
  final String? vezerlesTipusa;
  String? imagePath; // <<<--- A 'final' KULCSSZÓ EL LETT TÁVOLÍTVA

  Jarmu({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.vin,
    required this.mileage,
    this.vezerlesTipusa,
    this.imagePath,
  });

  // A copyWith és a többi metódus helyesen kezeli a nem-final mezőt
  Jarmu copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    int? mileage,
    String? vezerlesTipusa,
    String? imagePath,
  }) {
    return Jarmu(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
      vezerlesTipusa: vezerlesTipusa ?? this.vezerlesTipusa,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'mileage': mileage,
      'vezerlesTipusa': vezerlesTipusa,
      'imagePath': imagePath,
    };
  }

  factory Jarmu.fromMap(Map<String, dynamic> map) {
    return Jarmu(
      id: map['id'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      licensePlate: map['licensePlate'],
      vin: map['vin'],
      mileage: map['mileage'],
      vezerlesTipusa: map['vezerlesTipusa'],
      imagePath: map['imagePath'],
    );
  }
}
