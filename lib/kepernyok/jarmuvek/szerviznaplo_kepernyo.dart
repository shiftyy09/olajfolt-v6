// lib/kepernyok/szerviznaplo/szerviznaplo_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';

// ✅ ELŐRE DEFINIÁLT SZERVIZ TÍPUSOK
final Map<String, Map<String, dynamic>> SZERVIZ_TIPUSOK = {
  'Olajcsere': {'intervalKm': 15000, 'intervalHonap': 12},
  'Vezérlés csere': {'intervalKm': 120000, 'intervalHonap': null},
  'Szűrőcsere': {'intervalKm': 30000, 'intervalHonap': 24},
  'Fékbetét csere': {'intervalKm': 40000, 'intervalHonap': null},
  'Gumicsere': {'intervalKm': null, 'intervalHonap': 6},
  'Műszaki vizsga': {'intervalKm': null, 'intervalHonap': 12},
  'Hűtőfolyadék': {'intervalKm': 50000, 'intervalHonap': 36},
  'Kuplung csere': {'intervalKm': 80000, 'intervalHonap': null},
};

class SzerviznaploKepernyo extends StatefulWidget {
  final Jarmu vehicle;

  const SzerviznaploKepernyo({super.key, required this.vehicle});

  @override
  State<SzerviznaploKepernyo> createState() => _SzerviznaploKepernyoState();
}

class _SzerviznaploKepernyoState extends State<SzerviznaploKepernyo> {
  late Future<List<Szerviz>> _serviceRecordsFuture;
  late Jarmu _currentVehicle;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadServiceRecords();
  }

  void _loadServiceRecords() {
    setState(() {
      _serviceRecordsFuture = AdatbazisKezelo.instance
          .getServicesForVehicle(_currentVehicle.id!)
          .then((maps) => maps.map((map) => Szerviz.fromMap(map)).toList());
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text('Hogyan működik?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ez a képernyő a járműved összes rögzített eseményét mutatja.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 15),
              Text(
                'Szerviz hozzáadása:',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1️⃣ Válaszd ki az előre definiált típust vagy "Egyedi"-t',
                  style: TextStyle(color: Colors.white70)),
              Text('2️⃣ Az intervallum automatikusan kitöltődik',
                  style: TextStyle(color: Colors.white70)),
              Text('3️⃣ Szerkesztheted a szövegét és dátumát',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 15),
              Text(
                'Emlékeztető:',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text('Az emlékeztető automatikusan létrejön a beállítások alapján!',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            const Text('Értem', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEditService({Szerviz? record}) async {
    String selectedServiceType = 'Olajcsere';
    String customDescription = record?.description ?? '';
    int? selectedIntervalKm = SZERVIZ_TIPUSOK['Olajcsere']!['intervalKm'];
    int? selectedIntervalHonap = SZERVIZ_TIPUSOK['Olajcsere']!['intervalHonap'];
    bool useKmInterval = true;

    final costController = TextEditingController(
        text: record?.cost.toString() == '0' ? '' : record?.cost.toString());
    final mileageController =
    TextEditingController(text: record?.mileage.toString());
    DateTime selectedDate = record?.date ?? DateTime.now();

    final bool? success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Text(
                  record == null ? 'Új Szervizesemény' : 'Esemény Szerkesztése',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ LEGÖRDÜLŐ SZERVIZ TÍPUSOK
                    DropdownSearch<String>(
                      items: ['Egyedi', ...SZERVIZ_TIPUSOK.keys],
                      selectedItem: selectedServiceType,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Keresés...',
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Szerviz típusa',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.build,
                              color: Colors.orange, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.orange, width: 2),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedServiceType = value;
                            if (value != 'Egyedi') {
                              selectedIntervalKm =
                              SZERVIZ_TIPUSOK[value]!['intervalKm'];
                              selectedIntervalHonap =
                              SZERVIZ_TIPUSOK[value]!['intervalHonap'];
                              useKmInterval = selectedIntervalKm != null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ EGYEDI LEÍRÁS (ha "Egyedi")
                    if (selectedServiceType == 'Egyedi')
                      Column(
                        children: [
                          _buildTextField(
                            TextEditingController(text: customDescription),
                            'Szerviz neve (pl. Vezérléskorrekció)',
                            Icons.edit,
                            onChanged: (value) {
                              customDescription = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Intervallum típus választása
                          Row(
                            children: [
                              Expanded(
                                child: _buildCheckboxTile(
                                  'KM alapú',
                                  useKmInterval,
                                      (value) => setDialogState(
                                          () => useKmInterval = value ?? true),
                                ),
                              ),
                              Expanded(
                                child: _buildCheckboxTile(
                                  'Hó alapú',
                                  !useKmInterval,
                                      (value) => setDialogState(
                                          () => useKmInterval = !(value ?? true)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Intervallum érték
                          _buildTextField(
                            TextEditingController(
                              text: useKmInterval
                                  ? (selectedIntervalKm?.toString() ?? '')
                                  : (selectedIntervalHonap?.toString() ?? ''),
                            ),
                            useKmInterval ? 'Intervallum (km)' : 'Intervallum (hó)',
                            Icons.schedule,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final intValue = int.tryParse(value);
                              if (useKmInterval) {
                                selectedIntervalKm = intValue;
                              } else {
                                selectedIntervalHonap = intValue;
                              }
                            },
                          ),
                        ],
                      )
                    else
                    // ✅ ELŐRE DEFINIÁLT TÍPUS - MUTASD AZ INTERVALLUMOT
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ajánlott intervallum:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (selectedIntervalKm != null)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.speed,
                                            color: Colors.orange, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$selectedIntervalKm km',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (selectedIntervalHonap != null)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Colors.orange, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$selectedIntervalHonap hó',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Költség & Kilométer
                    _buildTextField(costController, 'Költség (Ft)', Icons.paid,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(
                        mileageController, 'Kilométeróra-állás', Icons.speed,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildDatePicker(
                      selectedDate,
                          (newDate) => setDialogState(() => selectedDate = newDate),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Mégse',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description = selectedServiceType == 'Egyedi'
                        ? customDescription
                        : selectedServiceType;

                    if (description.isEmpty) return;

                    // ✅ EMLÉKEZTETŐ LEÍRÁS GENERÁLÁSA
                    String reminderDescription = 'Emlékeztető alap: $description';
                    if (selectedServiceType != 'Egyedi') {
                      if (useKmInterval && selectedIntervalKm != null) {
                        reminderDescription +=
                        ' - ${selectedIntervalKm} km-ként';
                      } else if (!useKmInterval && selectedIntervalHonap != null) {
                        reminderDescription +=
                        ' - ${selectedIntervalHonap} hónaponként';
                      }
                    }

                    final newRecord = Szerviz(
                      id: record?.id,
                      vehicleId: _currentVehicle.id!,
                      description: description,
                      date: selectedDate,
                      cost: int.tryParse(costController.text) ?? 0,
                      mileage: int.tryParse(mileageController.text) ?? 0,
                    );

                    final db = AdatbazisKezelo.instance;
                    if (record == null) {
                      await db.insert('services', newRecord.toMap());

                      // ✅ EMLÉKEZTETŐ AUTOMATIKUSAN FELVÉTELE
                      if (selectedServiceType != 'Egyedi') {
                        final reminderRecord = Szerviz(
                          vehicleId: _currentVehicle.id!,
                          description: reminderDescription,
                          date: selectedDate,
                          cost: 0,
                          mileage: int.tryParse(mileageController.text) ?? 0,
                        );
                        await db.insert('services', reminderRecord.toMap());
                      }
                    } else {
                      await db.update('services', newRecord.toMap());
                    }
                    Navigator.of(context).pop(true);
                  },
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Mentés',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      _loadServiceRecords();
    }
  }

  Widget _buildCheckboxTile(
      String label, bool value, Function(bool?)? onChanged) {
    return InkWell(
      onTap: () => onChanged?.call(!value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? Colors.orange.withOpacity(0.2) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? Colors.orange : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.orange,
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
        Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2)),
      ),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
    );
  }

  Widget _buildDatePicker(DateTime date, Function(DateTime) onDateChanged) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != date) {
          onDateChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Text(DateFormat('yyyy. MM. dd.').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // ✅ STATISZTIKÁK KISZÁMÍTÁSA
  Map<String, dynamic> _calculateStatistics(List<Szerviz> records) {
    int totalServices = records.length;
    int totalCost = records.fold<num>(0, (sum, item) => sum + item.cost).toInt();
    int expiredReminders = records.where((r) =>
    r.description.contains('emlékeztető') && r.date.isBefore(DateTime.now())
    ).length;

    return {
      'totalServices': totalServices,
      'totalCost': totalCost,
      'expiredReminders': expiredReminders,
    };
  }

  // ✅ STATISZTIKA PANEL
  Widget _buildStatisticsPanel(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF252525),
            const Color(0xFF1E1E1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // ✅ FŐSTATISZTIKÁK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Szervizek száma - CSAVARKULCS
              _buildStatCard(
                Icons.build,
                '${stats['totalServices']}',
                'Szerviz',
                Colors.orange,
              ),
              // Összes költség - FORINT
              _buildStatCard(
                Icons.paid,
                '${NumberFormat.decimalPattern('hu_HU').format(stats['totalCost'])} Ft',
                'Költség',
                Colors.green,
              ),
              // Lejárt emlékeztetők - FIGYELMEZTETÉS
              _buildStatCard(
                Icons.warning_rounded,
                '${stats['expiredReminders']}',
                'Lejárt',
                stats['expiredReminders'] > 0 ? Colors.red : Colors.grey,
              ),
            ],
          ),

          // ✅ HA VAN LEJÁRT, MUTASD MEG
          if (stats['expiredReminders'] > 0) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => _buildExpiredRemindersSheet(),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stats['expiredReminders']} lejárt emlékeztető - Kattints a megtekintéshez',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ STATISZTIKA KÁRTYA
  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ✅ LEJÁRT EMLÉKEZTETŐK MODAL
  Widget _buildExpiredRemindersSheet() {
    return FutureBuilder<List<Szerviz>>(
      future: _serviceRecordsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final expiredRecords = snapshot.data!
            .where((r) => r.description.contains('emlékeztető') &&
            r.date.isBefore(DateTime.now()))
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Lejárt emlékeztetők',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: expiredRecords.length,
                itemBuilder: (context, index) {
                  final record = expiredRecords[index];
                  return Card(
                    color: const Color(0xFF252525),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.error_outline, color: Colors.red),
                      title: Text(
                        record.description,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy. MM. dd.').format(record.date),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        '${(DateTime.now().difference(record.date).inDays)} nap',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${_currentVehicle.make} Szerviznapló'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: _showInfoDialog,
            tooltip: 'Hogyan működik?',
          ),
        ],
      ),
      body: FutureBuilder<List<Szerviz>>(
        future: _serviceRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Hiba történt: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Nincsenek rögzített események.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kattints az \'+\' gombra új szerviz hozzáadásához',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data!;
          final stats = _calculateStatistics(records);

          return Column(
            children: [
              // ✅ STATISZTIKA PANEL
              _buildStatisticsPanel(stats),

              // ✅ "ELŐZŐ SZERVIZEK" FEJLÉC
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Text(
                      'Előző szervizek',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ SZERVIZEK LISTÁJA
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 100),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(records[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditService(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Új szerviz',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Szerviz record) {
    final String desc = record.description.toLowerCase();
    final Color cardColor;
    final IconData cardIcon;

    if (desc.contains('tankolás')) {
      cardColor = Colors.green;
      cardIcon = Icons.local_gas_station;
    } else if (desc.contains('emlékeztető') || desc.contains('esedékes')) {
      cardColor = Colors.red.shade400;
      cardIcon = Icons.warning_amber_rounded;
    } else {
      cardColor = Colors.orange;
      cardIcon = Icons.build;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: cardColor.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        backgroundColor: const Color(0xFF252525),
        collapsedBackgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Icon(cardIcon, color: cardColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                record.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('yyyy. MM. dd.').format(record.date),
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: Icon(Icons.expand_more, color: cardColor),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white24, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailColumn(
                      Icons.speed,
                      '${NumberFormat.decimalPattern('hu_HU').format(record.mileage)} km',
                    ),
                    if (record.cost > 0)
                      _buildDetailColumn(
                        Icons.paid,
                        '${NumberFormat.decimalPattern('hu_HU').format(record.cost)} Ft',
                      )
                    else
                      _buildDetailColumn(
                        Icons.check_circle,
                        'Ingyenes',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _addOrEditService(record: record),
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      label: const Text('Szerkesztés',
                          style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
