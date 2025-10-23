import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';
import '../../szolgaltatasok/csv_szolgaltatas.dart';
import '../../szolgaltatasok/ertesites_szolgaltatas.dart';
import '../../szolgaltatasok/pdf_szolgaltatas.dart';
import '../../widgetek/kozos_menu_kartya.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final ErtesitesSzolgaltatas _ertesitesSzolgaltatas = ErtesitesSzolgaltatas();
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas();

  bool _notificationsEnabled = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  void _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _updateAndScheduleAllNotifications() async {
    await _ertesitesSzolgaltatas.cancelAllNotifications();

    if (!_notificationsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Értesítések kikapcsolva.'),
            backgroundColor: Colors.grey));
      }
      return;
    }

    final db = AdatbazisKezelo.instance;
    final vehicles = (await db.getVehicles())
        .map((map) => Jarmu.fromMap(map))
        .toList();
    int notificationId = 0;

    for (var vehicle in vehicles) {
      final records = await db.getServicesForVehicle(vehicle.id!);
      final muszakiRecords = records
          .map((r) => Szerviz.fromMap(r))
          .where((s) => s.description == 'Emlékeztető alap: Műszaki vizsga')
          .toList();

      if (muszakiRecords.isNotEmpty) {
        final muszakiDate = muszakiRecords.first.date;
        final expiryDate = DateTime(
            muszakiDate.year + 2, muszakiDate.month, muszakiDate.day);
        final now = DateTime.now();

        final oneMonthBefore = expiryDate.subtract(const Duration(days: 30));
        if (oneMonthBefore.isAfter(now)) {
          await _ertesitesSzolgaltatas.scheduleNotification(
            id: notificationId++,
            title: 'Lejáró műszaki: ${vehicle.make}',
            body: 'A(z) ${vehicle
                .licensePlate} műszaki vizsgája 1 hónap múlva lejár.',
            scheduledDate: DateTime(
                oneMonthBefore.year, oneMonthBefore.month, oneMonthBefore.day,
                10),
          );
        }

        final oneWeekBefore = expiryDate.subtract(const Duration(days: 7));
        if (oneWeekBefore.isAfter(now)) {
          await _ertesitesSzolgaltatas.scheduleNotification(
            id: notificationId++,
            title: 'Lejáró műszaki: ${vehicle.make}',
            body: 'Figyelem! A(z) ${vehicle
                .licensePlate} műszaki vizsgája 1 hét múlva lejár!',
            scheduledDate: DateTime(
                oneWeekBefore.year, oneWeekBefore.month, oneWeekBefore.day, 10),
          );
        }
      }
    }

    if (vehicles.isNotEmpty) {
      await _ertesitesSzolgaltatas.scheduleWeeklyNotification(
        id: 999,
        title: 'Olajfolt Emlékeztető',
        body: 'Ne felejtsd el frissíteni a km óra állást a pontos emlékeztetőkért!',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Értesítések frissítve!'),
          backgroundColor: Colors.green));
    }
  }

  // --- JAVÍTOTT FÜGGVÉNYEK KEZDETE ---

  Future<void> _handlePdfExport() async {
    // A PDF export egy járműhöz kötődik. Egy egyszerűsített verzióban
    // most az első járművet exportáljuk. Ezt a jövőben fejlesztheted egy
    // járműválasztó dialógusablakkal.
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final db = AdatbazisKezelo.instance;
      final vehicles = (await db.getVehicles())
          .map((map) => Jarmu.fromMap(map))
          .toList();

      if (vehicles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nincs jármű az exportáláshoz.'),
                  backgroundColor: Colors.orange));
        }
        return; // Kilépünk a függvényből, ha nincs jármű
      }

      // Itt most az első járművet használjuk példaként.
      final vehicleToExport = vehicles.first;

      // JAVÍTÁS: A helyes 'createAndExportPdf' metódus hívása,
      // a szükséges paraméterekkel. Mentést választunk alapértelmezetten.
      final bool success = await _pdfSzolgaltatas.createAndExportPdf(
        vehicleToExport,
        context,
        ExportAction.save, // Megadjuk, hogy menteni akarunk.
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('PDF sikeresen mentve a Letöltések mappába.'),
                  backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hiba a PDF exportálás során.'),
                  backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Váratlan hiba: $e'),
                backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCsvExport() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _csvSzolgaltatas.exportAllDataToCsv();

      if (mounted) {
        String message;
        Color color;
        if (result == "permission_denied") {
          message = 'A mentéshez engedélyezni kell a tárhely hozzáférést!';
          color = Colors.red;
        } else if (result == "empty") {
          message = 'Nincs adat, amit exportálni lehetne.';
          color = Colors.orange;
        } else if (result != null) {
          message = 'CSV sikeresen exportálva: $result';
          color = Colors.green;
        } else {
          message = 'Hiba a CSV exportálás során.';
          color = Colors.red;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Váratlan hiba: $e'),
                backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCsvImport() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _csvSzolgaltatas.importDataFromCsv();

      if (mounted) {
        String message;
        Color color;
        switch (result) {
          case ImportResult.success:
            message =
            'Adatok sikeresen importálva! Indítsd újra az appot a változások megtekintéséhez.';
            color = Colors.green;
            break;
          case ImportResult.error:
            message = 'Hiba történt az importálás során.';
            color = Colors.red;
            break;
          case ImportResult.noFileSelected:
            message = 'Nem választottál ki fájlt.';
            color = Colors.orange;
            break;
          case ImportResult.invalidFormat:
            message = 'A kiválasztott fájl formátuma nem megfelelő.';
            color = Colors.red;
            break;
          case ImportResult.emptyFile:
            message = 'A kiválasztott fájl üres.';
            color = Colors.orange;
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Váratlan hiba: $e'),
                backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // --- JAVÍTOTT FÜGGVÉNYEK VÉGE ---

  void _showInfoDialog() {
    // Ide jöhet egy showDialog(...) hívás, ami elmagyarázza az app működését.
  }

  Future<void> _launchURL() async {
    final url = Uri.parse('https://www.google.com'); // Ide jön a te URL-ed
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Az URL nem indítható el.'),
                backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.amber),
              tooltip: 'Hogyan működik?',
              onPressed: _showInfoDialog)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          _buildSectionHeader(context, 'Adatkezelés'),
          KozosMenuKartya(
            icon: Icons.picture_as_pdf,
            title: 'Adatlap exportálása (PDF)',
            subtitle: 'Generálj egy adatlapot a járművedről',
            color: Colors.red.shade400,
            onTap: _isProcessing ? () {} : _handlePdfExport,
            trailing: _isProcessing
                ? const SizedBox(width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.red))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.upload_file,
            title: 'Mentés exportálása (CSV)',
            subtitle: 'Minden adat kimentése egyetlen fájlba',
            color: Colors.blue.shade400,
            onTap: _isProcessing ? () {} : _handleCsvExport,
            trailing: _isProcessing
                ? const SizedBox(width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.blue))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.download,
            title: 'Mentés importálása (CSV)',
            subtitle: 'Adatok visszatöltése mentésből',
            color: Colors.green.shade400,
            onTap: _isProcessing ? () {} : _handleCsvImport,
            trailing: _isProcessing
                ? const SizedBox(width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.green))
                : null,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Értesítések'),
          KozosMenuKartya(
            icon: Icons.notifications_active,
            title: 'Karbantartás értesítések',
            subtitle: 'Emlékeztetők a közelgő eseményekről',
            color: Colors.orange.shade400,
            onTap: () {},
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) async {
                setState(() => _notificationsEnabled = value);
                await _saveNotificationSetting(value);
                await _updateAndScheduleAllNotifications();
              },
              activeColor: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 1.0.0',
            color: Colors.grey.shade600,
            onTap: () {},
          ),
          KozosMenuKartya(
            icon: Icons.policy_outlined,
            title: 'Adatvédelmi irányelvek',
            subtitle: 'Hogyan kezeljük az adataidat?',
            color: Colors.grey.shade600,
            onTap: _launchURL,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}