import 'dart:io';
import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImportResult { success, error, noFileSelected, invalidFormat, emptyFile }

class CsvSzolgaltatas {
  Future<String?> exportAllDataToCsv() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        return "permission_denied";
      }
    }

    final db = AdatbazisKezelo.instance;
    final List<Map<String, dynamic>> vehicles = await db.getVehicles();

    // === ITT VAN A JAVÍTÁS ===
    // A 'getServices' helyett a helyes, általános 'queryAllRows' metódust hívjuk.
    final List<Map<String, dynamic>> services = await db.queryAllRows(
        'services');
    // ========================

    if (vehicles.isEmpty && services.isEmpty) {
      return "empty";
    }

    String vehicleCsv = "";
    if (vehicles.isNotEmpty) {
      List<List<dynamic>> vehicleRows = [
        vehicles.first.keys.toList(),
        ...vehicles.map((v) => v.values.toList())
      ];
      vehicleCsv = const ListToCsvConverter().convert(vehicleRows);
    }
    String serviceCsv = "";
    if (services.isNotEmpty) {
      List<List<dynamic>> serviceRows = [
        services.first.keys.toList(),
        ...services.map((s) => s.values.toList())
      ];
      serviceCsv = const ListToCsvConverter().convert(serviceRows);
    }
    String combinedCsv = "---VEHICLES---\n$vehicleCsv\n---SERVICES---\n$serviceCsv";

    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          print("Hiba: A külső tárhely nem elérhető.");
          return null;
        }
        final downloadDir = Directory('${directory.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        directory = downloadDir;
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        print("Nem sikerült meghatározni a mentési mappát.");
        return null;
      }

      final String formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(
          DateTime.now());
      final String fileName = "olajfolt_mentes_$formattedDate.csv";
      final File file = File("${directory.path}/$fileName");

      await file.writeAsString(combinedCsv);
      print("Sikeres exportálás ide: ${file.path}");
      return file.path;
    } catch (e) {
      print("Hiba a CSV exportálás során: $e");
      return null;
    }
  }

  Future<ImportResult> importDataFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) {
      return ImportResult.noFileSelected;
    }

    File file = File(result.files.single.path!);
    try {
      final String content = await file.readAsString();
      if (content
          .trim()
          .isEmpty) {
        return ImportResult.emptyFile;
      }
      if (!content.contains('---VEHICLES---') ||
          !content.contains('---SERVICES---')) {
        return ImportResult.invalidFormat;
      }

      final parts = content.split('---SERVICES---');
      final vehiclePart = parts[0].replaceFirst('---VEHICLES---', '').trim();
      final servicePart = parts.length > 1 ? parts[1].trim() : '';

      final db = AdatbazisKezelo.instance;
      await db.clearAllData();

      if (vehiclePart.isNotEmpty) {
        List<List<dynamic>> vehicleRows = const CsvToListConverter(
            shouldParseNumbers: false).convert(vehiclePart);
        if (vehicleRows.length > 1) {
          List<String> headers = vehicleRows[0]
              .map((h) => h.toString())
              .toList();
          for (int i = 1; i < vehicleRows.length; i++) {
            Map<String, dynamic> rowMap = Map.fromIterables(
                headers, vehicleRows[i]);

            // Típuskonverziók a biztonság kedvéért
            rowMap['id'] = int.tryParse(rowMap['id']?.toString() ?? '');
            rowMap['year'] = int.tryParse(rowMap['year']?.toString() ?? '');
            rowMap['mileage'] =
                int.tryParse(rowMap['mileage']?.toString() ?? '');

            // Kihagyjuk azokat az oszlopokat, amik esetleg nincsenek a sémában
            rowMap.removeWhere((key, value) =>
            ![
              'id',
              'make',
              'model',
              'year',
              'licensePlate',
              'vin',
              'mileage',
              'vezerlesTipusa',
              'imagePath'
            ].contains(key));

            await db.insert('vehicles', rowMap);
          }
        }
      }

      if (servicePart.isNotEmpty) {
        List<List<dynamic>> serviceRows = const CsvToListConverter(
            shouldParseNumbers: false).convert(servicePart);
        if (serviceRows.length > 1) {
          List<String> headers = serviceRows[0]
              .map((h) => h.toString())
              .toList();
          for (int i = 1; i < serviceRows.length; i++) {
            Map<String, dynamic> rowMap = Map.fromIterables(
                headers, serviceRows[i]);

            rowMap['id'] = int.tryParse(rowMap['id']?.toString() ?? '');
            rowMap['vehicleId'] =
                int.tryParse(rowMap['vehicleId']?.toString() ?? '');
            rowMap['mileage'] =
                int.tryParse(rowMap['mileage']?.toString() ?? '');
            rowMap['cost'] = int.tryParse(rowMap['cost']?.toString() ?? '0');

            await db.insert('services', rowMap);
          }
        }
      }

      return ImportResult.success;
    } catch (e) {
      print("Hiba a CSV importálás során: $e");
      return ImportResult.error;
    }
  }
}