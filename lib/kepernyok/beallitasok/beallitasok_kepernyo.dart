// lib/kepernyok/beallitasok/beallitasok_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';
import '../../szolgaltatasok/csv_szolgaltatas.dart';
import '../../szolgaltatasok/pdf_szolgaltatas.dart';
import '../../widgetek/kozos_menu_kartya.dart';
import 'ertesitesek_beallitasa_kepernyo.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas();

  bool _isProcessing = false;

  Future<void> _handlePdfExport() async {
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
        return;
      }

      final vehicleToExport = vehicles.first;
      final bool success = await _pdfSzolgaltatas.createAndExportPdf(
        vehicleToExport,
        context,
        ExportAction.save,
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

  Future<void> _handleDeleteAllData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.red),
              SizedBox(width: 10),
              Text('Összes adat törlése?',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
              'Ez az akció végleges! Minden járműd, szerviz adat és beállítás törlésre kerül.',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Mégsem',
                  style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Törlés',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isProcessing = true);

                try {
                  final db = AdatbazisKezelo.instance;
                  await db.clearAllData();

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Összes adat törölve!'),
                            backgroundColor: Colors.green));

                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hiba: $e'),
                            backgroundColor: Colors.red));
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 10),
              Text('Tudnivalók', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Itt kezelheted az alkalmazás beállításait és exportálhatod az adataidat.',
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 15),
                Text('Adatkezelés', style: TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(
                    '• PDF Export: Egy kiválasztott jármű szerviztörténetét menti egy formázott PDF fájlba.\n• CSV Export: Az összes adatodat (járművek, szervizek) egyetlen CSV fájlba menti, ami egy biztonsági mentés.\n• CSV Import: Visszatölti az adatokat egy korábban mentett CSV fájlból.',
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 15),
                Text('Értesítések', style: TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(
                    '• Kapcsold be, hogy emlékeztetőket kapj a közelgő műszaki vizsgákról és más karbantartási eseményekről.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                  'Rendben', style: TextStyle(color: Colors.amber)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
          _buildSectionHeader('Adatkezelés'),
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
          _buildSectionHeader('Értesítések'),
          KozosMenuKartya(
            icon: Icons.notifications_active,
            title: 'Karbantartás értesítések beállítása',
            subtitle: 'Válaszd ki, mely értesítéseket szeretnéd kapni',
            color: Colors.orange.shade400,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ErtesitesekBeallitasaKepernyo(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Adatvédelem & Jogi'),
          KozosMenuKartya(
            icon: Icons.policy_outlined,
            title: 'Adatvédelmi irányelvek',
            subtitle: 'Hogyan kezeljük az adataidat?',
            color: Colors.purple.shade600,
            onTap: () => _launchURL('https://www.google.com/search?q=privacy+policy+template'),
          ),
          KozosMenuKartya(
            icon: Icons.description,
            title: 'Felhasználási feltételek',
            subtitle: 'Az alkalmazás használatának szabályai',
            color: Colors.purple.shade600,
            onTap: () => _launchURL('https://www.google.com/search?q=terms+of+service+template'),
          ),
          KozosMenuKartya(
            icon: Icons.assignment,
            title: 'GDPR Információ',
            subtitle: 'Az adataid tulajdonosa vagy te',
            color: Colors.purple.shade600,
            onTap: () => _launchURL('https://www.google.com/search?q=gdpr+information'),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 0.5.0',
            color: Colors.grey.shade600,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF212121),
                    title: const Text('Olajfolt v0.5.0',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        'Autó karbantartás szerviz napló és értesítési rendszer\n\n© 2025 - Összes jog fenntartva.',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        child: const Text('OK',
                            style: TextStyle(color: Colors.orange)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Veszélyzóna'),
          KozosMenuKartya(
            icon: Icons.delete_forever,
            title: 'Összes adat törlése',
            subtitle: 'FIGYELEM: Ez nem visszavonható!',
            color: Colors.red.shade700,
            onTap: _isProcessing ? () {} : _handleDeleteAllData,
            trailing: _isProcessing
                ? const SizedBox(width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.red))
                : null,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
