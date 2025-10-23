import 'dart:io';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'jarmu_hozzaadasa.dart';
import 'szerviznaplo_kepernyo.dart';

class JarmuparkKepernyo extends StatefulWidget {
  const JarmuparkKepernyo({super.key});

  @override
  State<JarmuparkKepernyo> createState() => _JarmuparkKepernyoState();
}

class _JarmuparkKepernyoState extends State<JarmuparkKepernyo> {
  Future<List<Jarmu>>? _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = AdatbazisKezelo.instance
          .getVehicles()
          .then((maps) => maps.map((map) => Jarmu.fromMap(map)).toList());
    });
  }

  void _navigateAndReload(Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      _loadVehicles();
    }
  }

  void _navigateToServiceLog(Jarmu jarmu) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SzerviznaploKepernyo(vehicle: jarmu),
      ),
    );
  }

  void _deleteVehicle(Jarmu vehicle) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title:
            const Text(
                'Törlés megerősítése', style: TextStyle(color: Colors.white)),
            content: Text(
                'Biztosan törölni szeretnéd a(z) ${vehicle.make} ${vehicle
                    .model} járművet és minden hozzá tartozó adatot?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Mégse')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Törlés',
                    style:
                    TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final db = AdatbazisKezelo.instance;
      await db.deleteServicesForVehicle(vehicle.id!);
      await db.delete('vehicles', vehicle.id!);
      _loadVehicles();
    }
  }

  String _getLogoPath(String make) {
    String safeName = removeDiacritics(make.toLowerCase());
    safeName = safeName.replaceAll(RegExp(r'\s+'), '-');
    safeName = safeName.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return 'assets/images/$safeName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text('Járműpark'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: FutureBuilder<List<Jarmu>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Hiba a járművek betöltése közben.\n\nHiba részletei: ${snapshot
                        .error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ));
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 80, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          const Text('Még nincsenek járművek rögzítve.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text(
                              'Nyomj a "+" gombra egy új jármű hozzáadásához.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16))
                        ])));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndReload(const JarmuHozzaadasaKepernyo()),
          backgroundColor: Colors.orange,
          tooltip: 'Új jármű hozzáadása',
          child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  Widget _buildVehicleCard(Jarmu vehicle) {
    final logoPath = _getLogoPath(vehicle.make);
    final bool hasUserImage =
        vehicle.imagePath != null && vehicle.imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToServiceLog(vehicle),
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16.0),
        color: const Color(0xFF1E1E1E),
        clipBehavior: Clip.antiAlias,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: hasUserImage
                  ? Image.file(File(vehicle.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _buildLogoContainer(logoPath))
                  : _buildLogoContainer(logoPath),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                children: [
                  _buildLicensePlate(vehicle.licensePlate),
                  const SizedBox(height: 16),
                  Text(
                    '${vehicle.make} ${vehicle.model}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Évjárat: ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6), fontSize: 15),
                      ),
                      Text(
                        '${vehicle.year}',
                        style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.2),
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed_outlined,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${NumberFormat.decimalPattern('hu_HU').format(
                            vehicle.mileage)} km',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.orange, size: 22),
                        tooltip: 'Jármű szerkesztése',
                        onPressed: () =>
                            _navigateAndReload(
                                JarmuHozzaadasaKepernyo(
                                    vehicleToEdit: vehicle)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 22),
                        tooltip: 'Jármű törlése',
                        onPressed: () => _deleteVehicle(vehicle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === JAVÍTOTT RENDSZÁMTÁBLA, CÍMER NÉLKÜL ===
  Widget _buildLicensePlate(String licensePlate) {
    final cleanPlate =
    licensePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    bool isNewFormat = cleanPlate.length >= 6 &&
        int.tryParse(cleanPlate.substring(cleanPlate.length - 3)) != null;

    String part1 = '';
    String part2 = '';
    String part3 = '';

    if (isNewFormat && cleanPlate.length == 7) {
      part1 = cleanPlate.substring(0, 2);
      part2 = cleanPlate.substring(2, 4);
      part3 = cleanPlate.substring(4);
    } else if (cleanPlate.length == 6) {
      part1 = cleanPlate.substring(0, 3);
      part3 = cleanPlate.substring(3);
    } else {
      part1 = cleanPlate;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF003399),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
            ),
            child: const Center(
              child: Text('H',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(part1,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              // === A CÍMER ÉS A KÖRÜLÖTTE LÉVŐ ELVÁLASZTÓK EL LETTEK TÁVOLÍTVA ===
              Text(part2,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              if (part3.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('-',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ),
              Text(part3,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildLogoContainer(String logoPath) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1E1E1E),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.directions_car,
                  color: Colors.white30, size: 50);
            },
          ),
        ),
      ),
    );
  }
}