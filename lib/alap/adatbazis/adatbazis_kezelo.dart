// lib/alap/adatbazis/adatbazis_kezelo.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../modellek/karbantartas_bejegyzes.dart';

class AdatbazisKezelo {
  static final AdatbazisKezelo instance =
  AdatbazisKezelo._privateConstructor();
  static Database? _database;

  AdatbazisKezelo._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 1,
        onCreate: _createAllTables,
        onUpgrade: _onUpgrade);
  }

  Future<void> _createAllTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        licensePlate TEXT NOT NULL UNIQUE,
        vin TEXT,
        mileage INTEGER NOT NULL,
        vezerlesTipusa TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        cost INTEGER NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Itt implementálhatod a migrációs logikát
    }
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await database;
    return await db.query('vehicles', orderBy: 'make, model');
  }

  Future<List<Map<String, dynamic>>> getServicesForVehicle(
      int vehicleId) async {
    final db = await database;
    return await db.query('services',
        where: 'vehicleId = ?',
        whereArgs: [vehicleId],
        orderBy: 'date DESC, mileage DESC');
  }

  Future<void> deleteServicesForVehicle(int vehicleId) async {
    final db = await database;
    await db.delete('services',
        where: 'vehicleId = ? AND description NOT LIKE ?',
        whereArgs: [vehicleId, 'Tankolás%']);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('services');
    await db.delete('vehicles');
  }

  Future<Szerviz?> findServiceByDescription(
      int vehicleId, String description) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('services',
        where: 'vehicleId = ? AND description = ?',
        whereArgs: [vehicleId, description],
        limit: 1);

    if (maps.isNotEmpty) {
      return Szerviz.fromMap(maps.first);
    }

    return null;
  }

  Future<void> deleteReminderServicesForVehicle(int vehicleId) async {
    final db = await instance.database;
    await db.delete('services',
        where: 'vehicleId = ? AND description LIKE ?',
        whereArgs: [vehicleId, 'Emlékeztető alap:%']);
  }
}
