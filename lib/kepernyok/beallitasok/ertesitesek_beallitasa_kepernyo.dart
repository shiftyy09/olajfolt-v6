// lib/kepernyok/beallitasok/ertesitesek_beallitasa_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';
import '../../szolgaltatasok/ertesites_szolgaltatas.dart';
import '../../widgetek/kozos_menu_kartya.dart';

class ErtesitesekBeallitasaKepernyo extends StatefulWidget {
  const ErtesitesekBeallitasaKepernyo({super.key});

  @override
  State<ErtesitesekBeallitasaKepernyo> createState() =>
      _ErtesitesekBeallitasaKepernyoState();
}

class _ErtesitesekBeallitasaKepernyoState
    extends State<ErtesitesekBeallitasaKepernyo> {
  final ErtesitesSzolgaltatas _ertesitesSzolgaltatas =
  ErtesitesSzolgaltatas();

  bool _muszakiEnabled = false;
  bool _olajcseraEnabled = false;
  bool _legszuroEnabled = false;
  bool _pollensuzroEnabled = false;
  bool _gyujtogerytyaEnabled = false;
  bool _uzemanyagszuroEnabled = false;
  bool _vezetlesEnabled = false;
  bool _fekbetetEloEnabled = false;
  bool _fekbetetHatsoEnabled = false;
  bool _fekfolyadekhEnabled = false;
  bool _hutofloyadekEnabled = false;
  bool _kuplung_ckuEnabled = false;

  bool _isProcessing = false;

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Műszaki vizsga',
      'subtitle': 'Dátum alapú - 1 hónappal és 1 héttel az expirálás előtt',
      'key': 'muszaki',
      'type': 'date'
    },
    {
      'title': 'Olajcsere',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'olajcsera',
      'type': 'km'
    },
    {
      'title': 'Légszűrő',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'legszuro',
      'type': 'km'
    },
    {
      'title': 'Pollenszűrő',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'pollensuzro',
      'type': 'km'
    },
    {
      'title': 'Gyújtógyertya',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'gyujtogyertya',
      'type': 'km'
    },
    {
      'title': 'Üzemanyagszűrő',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'uzemanyagszuro',
      'type': 'km'
    },
    {
      'title': 'Vezérlés (Szíj)',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'vezetles',
      'type': 'km'
    },
    {
      'title': 'Fékbetét (első)',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'fekbetet_elo',
      'type': 'km'
    },
    {
      'title': 'Fékbetét (hátsó)',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'fekbetet_hatso',
      'type': 'km'
    },
    {
      'title': 'Fékfolyadék',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'fekfolyadeH',
      'type': 'km'
    },
    {
      'title': 'Hűtőfolyadék',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'hutoflyadek',
      'type': 'km'
    },
    {
      'title': 'Kuplung',
      'subtitle': 'KM alapú - 1000 km előtte értesítés, majd 1x',
      'key': 'kuplung',
      'type': 'km'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ✅ FRISSÍTÉS: Az adatbázisból hivja le az aktuális beállításokat
  Future<void> _loadSettings() async {
    final db = AdatbazisKezelo.instance;
    final vehicles = (await db.getVehicles())
        .map((map) => Jarmu.fromMap(map))
        .toList();

    final enabledServices = <String>{};

    // Összes járműből legyűjti az engedélyezett emlékeztetőket
    for (var vehicle in vehicles) {
      final records =
      await db.getServicesForVehicle(vehicle.id!);
      for (var recordMap in records) {
        final description = recordMap['description'] as String? ?? '';
        if (description.contains('Emlékeztető alap:')) {
          final serviceType =
          description.replaceAll('Emlékeztető alap: ', '').trim();
          enabledServices.add(serviceType);
        }
      }
    }

    // ✅ Az adatbázisból olvasott értékek alapján állítja be a UI-t
    setState(() {
      _muszakiEnabled = enabledServices.contains('Műszaki vizsga');
      _olajcseraEnabled = enabledServices.contains('Olajcsere');
      _legszuroEnabled = enabledServices.contains('Légszűrő');
      _pollensuzroEnabled = enabledServices.contains('Pollenszűrő');
      _gyujtogerytyaEnabled = enabledServices.contains('Gyújtógyertya');
      _uzemanyagszuroEnabled =
          enabledServices.contains('Üzemanyagszűrő');
      _vezetlesEnabled = enabledServices.contains('Vezérlés (Szíj)');
      _fekbetetEloEnabled = enabledServices.contains('Fékbetét (első)');
      _fekbetetHatsoEnabled = enabledServices.contains('Fékbetét (hátsó)');
      _fekfolyadekhEnabled = enabledServices.contains('Fékfolyadék');
      _hutofloyadekEnabled = enabledServices.contains('Hűtőfolyadék');
      _kuplung_ckuEnabled = enabledServices.contains('Kuplung');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_muszaki', _muszakiEnabled);
    await prefs.setBool('notif_olajcsera', _olajcseraEnabled);
    await prefs.setBool('notif_legszuro', _legszuroEnabled);
    await prefs.setBool('notif_pollensuzro', _pollensuzroEnabled);
    await prefs.setBool('notif_gyujtogyertya', _gyujtogerytyaEnabled);
    await prefs.setBool('notif_uzemanyagszuro', _uzemanyagszuroEnabled);
    await prefs.setBool('notif_vezetles', _vezetlesEnabled);
    await prefs.setBool('notif_fekbetet_elo', _fekbetetEloEnabled);
    await prefs.setBool('notif_fekbetet_hatso', _fekbetetHatsoEnabled);
    await prefs.setBool('notif_fekfolyadeH', _fekfolyadekhEnabled);
    await prefs.setBool('notif_hutoflyadek', _hutofloyadekEnabled);
    await prefs.setBool('notif_kuplung', _kuplung_ckuEnabled);
  }

  bool _getNotificationState(String key) {
    switch (key) {
      case 'muszaki':
        return _muszakiEnabled;
      case 'olajcsera':
        return _olajcseraEnabled;
      case 'legszuro':
        return _legszuroEnabled;
      case 'pollensuzro':
        return _pollensuzroEnabled;
      case 'gyujtogyertya':
        return _gyujtogerytyaEnabled;
      case 'uzemanyagszuro':
        return _uzemanyagszuroEnabled;
      case 'vezetles':
        return _vezetlesEnabled;
      case 'fekbetet_elo':
        return _fekbetetEloEnabled;
      case 'fekbetet_hatso':
        return _fekbetetHatsoEnabled;
      case 'fekfolyadeH':
        return _fekfolyadekhEnabled;
      case 'hutoflyadek':
        return _hutofloyadekEnabled;
      case 'kuplung':
        return _kuplung_ckuEnabled;
      default:
        return false;
    }
  }

  void _setNotificationState(String key, bool value) {
    setState(() {
      switch (key) {
        case 'muszaki':
          _muszakiEnabled = value;
          break;
        case 'olajcsera':
          _olajcseraEnabled = value;
          break;
        case 'legszuro':
          _legszuroEnabled = value;
          break;
        case 'pollensuzro':
          _pollensuzroEnabled = value;
          break;
        case 'gyujtogyertya':
          _gyujtogerytyaEnabled = value;
          break;
        case 'uzemanyagszuro':
          _uzemanyagszuroEnabled = value;
          break;
        case 'vezetles':
          _vezetlesEnabled = value;
          break;
        case 'fekbetet_elo':
          _fekbetetEloEnabled = value;
          break;
        case 'fekbetet_hatso':
          _fekbetetHatsoEnabled = value;
          break;
        case 'fekfolyadeH':
          _fekfolyadekhEnabled = value;
          break;
        case 'hutoflyadek':
          _hutofloyadekEnabled = value;
          break;
        case 'kuplung':
          _kuplung_ckuEnabled = value;
          break;
      }
    });
  }

  Future<void> _applySettings() async {
    setState(() => _isProcessing = true);

    try {
      await _saveSettings();
      await _scheduleAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Értesítések frissítve!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba történt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _scheduleAllNotifications() async {
    await _ertesitesSzolgaltatas.cancelAllNotifications();

    final db = AdatbazisKezelo.instance;
    final vehicles =
    (await db.getVehicles()).map((map) => Jarmu.fromMap(map)).toList();

    int notificationId = 0;

    for (var vehicle in vehicles) {
      final records = await db.getServicesForVehicle(vehicle.id!);

      // MŰSZAKI VIZSGA (Dátum alapú)
      if (_muszakiEnabled) {
        final muszakiRecords = records
            .where((r) => r['description']
            .contains('Emlékeztető alap: Műszaki vizsga'))
            .toList();

        if (muszakiRecords.isNotEmpty) {
          final muszakiDate =
          DateTime.parse(muszakiRecords.first['date']);
          final expiryDate = DateTime(
              muszakiDate.year + 2, muszakiDate.month, muszakiDate.day);
          final now = DateTime.now();

          final oneMonthBefore =
          expiryDate.subtract(const Duration(days: 30));
          if (oneMonthBefore.isAfter(now)) {
            await _ertesitesSzolgaltatas.scheduleNotification(
              id: notificationId++,
              title: 'Lejáró műszaki: ${vehicle.make}',
              body:
              'A(z) ${vehicle.licensePlate} műszaki vizsgája 1 hónap múlva lejár.',
              scheduledDate: DateTime(oneMonthBefore.year, oneMonthBefore.month,
                  oneMonthBefore.day, 10),
            );
          }

          final oneWeekBefore = expiryDate.subtract(const Duration(days: 7));
          if (oneWeekBefore.isAfter(now)) {
            await _ertesitesSzolgaltatas.scheduleNotification(
              id: notificationId++,
              title: 'Lejáró műszaki: ${vehicle.make}',
              body:
              'Figyelem! A(z) ${vehicle.licensePlate} műszaki vizsgája 1 hét múlva lejár!',
              scheduledDate: DateTime(oneWeekBefore.year, oneWeekBefore.month,
                  oneWeekBefore.day, 10),
            );
          }
        }
      }
    }

    if (vehicles.isNotEmpty) {
      await _ertesitesSzolgaltatas.scheduleWeeklyNotification(
        id: 999,
        title: 'Olajfolt Emlékeztető',
        body:
        'Ne felejtsd el frissíteni a km óra állást a pontos emlékeztetőkért!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Értesítések Beállítása'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade400, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade300),
                    const SizedBox(width: 8),
                    const Text('Hogyan működik?',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    '1️⃣ Járműhöz adott emlékeztetőit itt látod\n\n'
                        '2️⃣ A KM alapú értesítések 1000 km-rel az esedékesség előtt szólnak\n\n'
                        '3️⃣ Miután értesített, már nem floodol - csak 1x jelzi\n\n'
                        '4️⃣ A műszaki vizsgák 1 hónappal és 1 héttel az expirálás előtt szólnak',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'KM ALAPÚ ÉRTESÍTÉSEK',
              style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2),
            ),
          ),
          ..._services
              .where((s) => s['type'] == 'km')
              .map((service) {
            final isEnabled = _getNotificationState(service['key']);
            return KozosMenuKartya(
              icon: Icons.speed,
              title: service['title'],
              subtitle: service['subtitle'],
              color: isEnabled
                  ? Colors.orange.shade400
                  : Colors.grey.shade600,
              onTap: () {},
              trailing: Switch(
                value: isEnabled,
                onChanged: (bool value) {
                  _setNotificationState(service['key'], value);
                },
                activeColor: Colors.orange.shade400,
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'DÁTUM ALAPÚ ÉRTESÍTÉSEK',
              style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2),
            ),
          ),
          ..._services
              .where((s) => s['type'] == 'date')
              .map((service) {
            final isEnabled = _getNotificationState(service['key']);
            return KozosMenuKartya(
              icon: Icons.calendar_today,
              title: service['title'],
              subtitle: service['subtitle'],
              color: isEnabled
                  ? Colors.blue.shade400
                  : Colors.grey.shade600,
              onTap: () {},
              trailing: Switch(
                value: isEnabled,
                onChanged: (bool value) {
                  _setNotificationState(service['key'], value);
                },
                activeColor: Colors.blue.shade400,
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? () {} : _applySettings,
        backgroundColor: Colors.orange,
        label: const Text(
          'Mentés',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        icon: _isProcessing
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        )
            : const Icon(Icons.check, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
