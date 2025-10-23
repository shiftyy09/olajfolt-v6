// lib/kepernyok/karbantartas/karbantartas_emlekezteto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';

class KarbantartasEmlekezteto extends StatefulWidget {
  const KarbantartasEmlekezteto({super.key});

  @override
  State<KarbantartasEmlekezteto> createState() =>
      _KarbantartasEmlekeztetoState();
}

class _KarbantartasEmlekeztetoState extends State<KarbantartasEmlekezteto> {
  Jarmu? _selectedVehicle;
  Future<List<Szerviz>>? _serviceHistoryFuture;
  final TextEditingController _mileageController = TextEditingController();

  Map<String, int> _serviceIntervals = {};
  Map<String, int> _dateIntervalsInYears = {};

  @override
  void initState() {
    super.initState();
    _loadIntervals();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _selectVehicle(context));
  }

  void _loadIntervals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serviceIntervals = {
        'Olaj': prefs.getInt('interval_Olaj') ?? 15000,
        'Levegőszűrő': prefs.getInt('interval_Levegőszűrő') ?? 30000,
        'Pollenszűrő': prefs.getInt('interval_Pollenszűrő') ?? 30000,
        'Üzemanyagszűrő': prefs.getInt('interval_Üzemanyagszűrő') ?? 60000,
        'Vezérlés': prefs.getInt('interval_Vezérlés') ?? 120000,
        'Fékbetét (első)': prefs.getInt('interval_Fékbetét (első)') ?? 50000,
        'Fékbetét (hátsó)': prefs.getInt('interval_Fékbetét (hátsó)') ?? 70000,
        'Fékfolyadék': prefs.getInt('interval_Fékfolyadék') ?? 60000,
        'Hűtőfolyadék': prefs.getInt('interval_Hűtőfolyadék') ?? 100000,
      };
      _dateIntervalsInYears = {
        'Műszaki': prefs.getInt('interval_Műszaki') ?? 2,
        'Akkumulátor': prefs.getInt('interval_Akkumulátor') ?? 5,
      };
    });
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectVehicle(BuildContext context) async {
    final db = AdatbazisKezelo.instance;
    final vehicles =
        (await db.getVehicles()).map((e) => Jarmu.fromMap(e)).toList();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      setState(() => _selectedVehicle = null);
      return;
    }

    Jarmu? selected = vehicles.length == 1
        ? vehicles.first
        : await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Válassz járművet!',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(
                          '${vehicles[index].make} ${vehicles[index].model}',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(vehicles[index].licensePlate,
                          style: const TextStyle(color: Colors.white70)),
                      onTap: () => Navigator.of(context).pop(vehicles[index]),
                    ),
                  )),
            ),
          );

    if (selected != null) {
      _loadDataForVehicle(selected);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _loadDataForVehicle(Jarmu vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _mileageController.text = vehicle.mileage.toString();
      _serviceHistoryFuture = AdatbazisKezelo.instance
          .getServicesForVehicle(vehicle.id!)
          .then((data) => data.map((item) => Szerviz.fromMap(item)).toList());
    });
  }

  Future<void> _updateMileage() async {
    if (_selectedVehicle == null) return;
    final newMileage = int.tryParse(_mileageController.text);
    if (newMileage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Érvénytelen kilométeróra-állás!'),
          backgroundColor: Colors.redAccent));
      return;
    }

    if (newMileage < _selectedVehicle!.mileage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Az új érték nem lehet kisebb a jelenleginél!'),
          backgroundColor: Colors.redAccent));
      _mileageController.text = _selectedVehicle!.mileage.toString();
      return;
    }

    final updatedVehicle = _selectedVehicle!.copyWith(mileage: newMileage);
    await AdatbazisKezelo.instance.update('vehicles', updatedVehicle.toMap());
    setState(() {
      _selectedVehicle = updatedVehicle;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kilométeróra-állás frissítve!'),
        backgroundColor: Colors.green));
  }

  Szerviz? _findLastService(List<Szerviz> allServices, String keyword) {
    try {
      final servicesOfType = allServices
          .where((s) =>
              s.description.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
      if (servicesOfType.isEmpty) return null;
      servicesOfType.sort((a, b) => _dateIntervalsInYears.containsKey(keyword)
          ? b.date.compareTo(a.date)
          : b.mileage.compareTo(a.mileage));
      return servicesOfType.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> _editLastEvent(Szerviz lastService) async {
    bool isDateBased = _dateIntervalsInYears.keys
        .any((key) => lastService.description.contains(key));
    final TextEditingController valueController = isDateBased
        ? TextEditingController(
            text: DateFormat('yyyy.MM.dd').format(lastService.date))
        : TextEditingController(text: lastService.mileage.toString());

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('"${lastService.description}" szerkesztése',
              style: TextStyle(color: Colors.amber, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  isDateBased
                      ? 'Utolsó esemény dátuma:'
                      : 'Utolsó csere km-állása:',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              TextField(
                controller: valueController,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    isDateBased ? TextInputType.none : TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: Icon(
                        isDateBased ? Icons.calendar_today : Icons.speed,
                        color: Colors.amber)),
                readOnly: isDateBased,
                onTap: isDateBased
                    ? () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: lastService.date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('hu', 'HU'),
                        );
                        if (pickedDate != null) {
                          valueController.text =
                              DateFormat('yyyy.MM.dd').format(pickedDate);
                        }
                      }
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Mégse')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () async {
                // === JAVÍTÁS: ELLENŐRZÉS HOZZÁADVA ===
                if (!isDateBased) {
                  final newMileage = int.tryParse(valueController.text);
                  if (newMileage != null &&
                      newMileage > _selectedVehicle!.mileage) {
                    // Kontextus ellenőrzése a SnackBarhoz
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'A csere km-állása nem lehet nagyobb a jármű jelenlegi km-állásánál!'),
                        backgroundColor: Colors.redAccent,
                      ));
                    }
                    return; // Megszakítjuk a mentést
                  }
                }
                // ===================================

                Szerviz updatedService;
                if (isDateBased) {
                  updatedService = lastService.copyWith(
                      date:
                          DateFormat('yyyy.MM.dd').parse(valueController.text));
                } else {
                  updatedService = lastService.copyWith(
                      mileage: int.tryParse(valueController.text) ??
                          lastService.mileage);
                }
                await AdatbazisKezelo.instance
                    .update('services', updatedService.toMap());
                Navigator.of(context).pop(true);
              },
              child: Text('Mentés', style: TextStyle(color: Colors.black)),
            )
          ],
        );
      },
    );

    if (success == true) {
      _loadDataForVehicle(_selectedVehicle!);
    }
  }

  void _editIntervals() async {
    Map<String, TextEditingController> kmControllers = {
      for (var item in _serviceIntervals.entries)
        item.key: TextEditingController(text: item.value.toString())
    };
    Map<String, TextEditingController> dateControllers = {
      for (var item in _dateIntervalsInYears.entries)
        item.key: TextEditingController(text: item.value.toString())
    };

    final bool? success = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Intervallumok Testreszabása',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Futásteljesítmény alapú (km)",
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...kmControllers.entries.map((entry) =>
                      _buildIntervalEditorRow(entry.key, entry.value)),
                  const Divider(height: 24),
                  const Text("Idő alapú (év)",
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...dateControllers.entries.map((entry) =>
                      _buildIntervalEditorRow(entry.key, entry.value)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Mégse')),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('Mentés',
                      style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() {
                      for (var entry in kmControllers.entries) {
                        final value = int.tryParse(entry.value.text) ??
                            _serviceIntervals[entry.key]!;
                        _serviceIntervals[entry.key] = value;
                        prefs.setInt('interval_${entry.key}', value);
                      }
                      for (var entry in dateControllers.entries) {
                        final value = int.tryParse(entry.value.text) ??
                            _dateIntervalsInYears[entry.key]!;
                        _dateIntervalsInYears[entry.key] = value;
                        prefs.setInt('interval_${entry.key}', value);
                      }
                    });
                    Navigator.of(context).pop(true);
                  }),
            ],
          );
        });

    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Intervallumok frissítve!'),
          backgroundColor: Colors.green));
    }
  }

  Widget _buildIntervalEditorRow(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: Colors.white70))),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54))),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 10),
                Text('Emlékeztető működése',
                    style: TextStyle(color: Colors.white, fontSize: 18))
              ]),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Ez a képernyő a Szerviznapló bejegyzései alapján automatikusan kiszámolja a következő karbantartások esedékességét.',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 16),
                    Text(
                        '1. A felső sávban mindig frissítheted az aktuális km-óra állást.',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                        '2. A program megkeresi az utolsó releváns bejegyzést (pl. "Olajcsere").',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                        '3. Kiszámolja és vizuálisan jelzi, mennyi van hátra a következő cseréig.',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notifications_active,
                                color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    'A háttérben futó értesítésekhez engedélyezd a funkciót a "Beállítások" menüpontban!',
                                    style: TextStyle(
                                        color: Colors.amber.shade200))),
                          ]),
                    ),
                    SizedBox(height: 16),
                    Text(
                        'Hosszan nyomva egy kártyát, manuálisan is módosíthatod az utolsó csere adatát.',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text(
                        'Az AppBar-on lévő beállítások ikonnal (⚙️) testreszabhatod a csereintervallumokat.',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Értem', style: TextStyle(color: Colors.amber)))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: Text(_selectedVehicle != null
              ? 'Emlékeztető: ${_selectedVehicle!.make}'
              : 'Karbantartási Emlékeztető'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_selectedVehicle != null)
              IconButton(
                  icon: const Icon(Icons.settings, color: Colors.amber),
                  tooltip: 'Intervallumok szerkesztése',
                  onPressed: _editIntervals),
            if (_selectedVehicle != null)
              IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.amber),
                  tooltip: 'Másik jármű választása',
                  onPressed: () => _selectVehicle(context)),
            IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.amber),
                tooltip: 'Hogyan működik?',
                onPressed: _showInfoDialog),
          ]),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedVehicle == null) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                  'Nincs jármű a parkban.\nElőször vegyél fel egyet a Járműpark menüben!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18))));
    }
    if (_serviceHistoryFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildMileageUpdater(),
        Expanded(
          child: FutureBuilder<List<Szerviz>>(
            future: _serviceHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(
                    child: Text('Hiba: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
              final allServices = snapshot.data ?? [];
              final List<Widget> cards = [];
              _dateIntervalsInYears.forEach((keyword, years) {
                final lastService = _findLastService(allServices, keyword);
                if (lastService != null) {
                  String cardTitle =
                      keyword == 'Műszaki' ? 'Műszaki vizsga' : keyword;
                  cards.add(_buildDateCard(
                      exam: lastService,
                      title: cardTitle,
                      validForYears: years));
                }
              });
              _serviceIntervals.forEach((keyword, interval) {
                final lastService = _findLastService(allServices, keyword);
                if (lastService != null) {
                  String cardTitle = keyword == 'Olaj'
                      ? 'Olajcsere'
                      : keyword == 'Vezérlés'
                          ? 'Vezérléscsere'
                          : keyword;
                  cards.add(_buildMileageCard(
                      currentVehicleMileage: _selectedVehicle!.mileage,
                      title: cardTitle,
                      lastService: lastService,
                      interval: interval));
                }
              });
              if (cards.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                            'Rögzíts egy eseményt a Szerviznaplóban (pl. "Olajcsere 2024"), hogy itt megjelenjenek az emlékeztetők!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70, fontSize: 18))));
              }
              cards.sort((a, b) {
                final colorA = a is Card
                    ? (a.shape as RoundedRectangleBorder).side.color
                    : Colors.transparent;
                final colorB = b is Card
                    ? (b.shape as RoundedRectangleBorder).side.color
                    : Colors.transparent;
                int scoreA = colorA == Colors.red.shade400
                    ? 0
                    : colorA == Colors.amber.shade400
                        ? 1
                        : 2;
                int scoreB = colorB == Colors.red.shade400
                    ? 0
                    : colorB == Colors.amber.shade400
                        ? 1
                        : 2;
                return scoreA.compareTo(scoreB);
              });
              return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: cards.length,
                  itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: cards[index]));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMileageUpdater() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.speed, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: _mileageController,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                          labelText: 'Aktuális km óra állás',
                          labelStyle:
                              TextStyle(color: Colors.white54, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ])),
              ElevatedButton(
                  onPressed: _updateMileage,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Frissít',
                      style: TextStyle(color: Colors.black))),
            ])));
  }

  Widget _buildDateCard(
      {required Szerviz exam,
      required String title,
      required int validForYears}) {
    final expiryDate = DateTime(
        exam.date.year + validForYears, exam.date.month, exam.date.day);
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    final statusColor = _getDateStatusColor(daysLeft: daysLeft);
    return Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: statusColor, width: 1.5)),
        child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onLongPress: () => _editLastEvent(exam),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(_getIconDataForService(title),
                            color: statusColor, size: 20),
                        SizedBox(width: 10),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))
                      ]),
                      const Divider(height: 24, color: Colors.white24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('Utolsó esemény',
                                DateFormat('yyyy.MM.dd').format(exam.date)),
                            _buildInfoColumn('Lejárat',
                                DateFormat('yyyy.MM.dd').format(expiryDate))
                          ]),
                      const SizedBox(height: 16),
                      Align(
                          alignment: Alignment.center,
                          child: Text(
                              daysLeft > 0
                                  ? '$daysLeft nap van hátra'
                                  : 'Lejárt!',
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18))),
                    ]))));
  }

  Widget _buildMileageCard(
      {required int currentVehicleMileage,
      required String title,
      required Szerviz lastService,
      required int interval}) {
    final kmSinceLastService = currentVehicleMileage - lastService.mileage;
    final kmLeft = interval - kmSinceLastService;
    final double progress = (kmSinceLastService / interval).clamp(0.0, 1.0);
    final statusColor = _getStatusColor(kmLeft: kmLeft);
    return Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: statusColor, width: 1.5)),
        child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onLongPress: () => _editLastEvent(lastService),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(_getIconDataForService(title),
                            color: statusColor, size: 20),
                        SizedBox(width: 10),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))
                      ]),
                      const Divider(height: 24, color: Colors.white24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('Előző csere',
                                '${NumberFormat.decimalPattern('hu_HU').format(lastService.mileage)} km'),
                            _buildInfoColumn('Intervallum',
                                '${NumberFormat.decimalPattern('hu_HU').format(interval)} km')
                          ]),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade800,
                          color: statusColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      Align(
                          alignment: Alignment.center,
                          child: Text(
                              kmLeft > 0
                                  ? '${NumberFormat.decimalPattern('hu_HU').format(kmLeft)} km van hátra'
                                  : 'Csere esedékes!',
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))),
                    ]))));
  }

  Widget _buildInfoColumn(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      ]);

  IconData _getIconDataForService(String serviceType) {
    serviceType = serviceType.toLowerCase();
    if (serviceType.contains('műszaki')) return Icons.calendar_today;
    if (serviceType.contains('olaj')) return Icons.water_drop_outlined;
    if (serviceType.contains('fék')) return Icons.car_repair;
    if (serviceType.contains('szűrő')) return Icons.air;
    if (serviceType.contains('vezérlés')) return Icons.sync;
    if (serviceType.contains('akkumulátor')) return Icons.battery_charging_full;
    if (serviceType.contains('hűtőfolyadék')) return Icons.opacity;
    return Icons.miscellaneous_services;
  }

  Color _getStatusColor({required int kmLeft}) {
    if (kmLeft <= 0) return Colors.red.shade400;
    if (kmLeft <= 5000) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  Color _getDateStatusColor({required int daysLeft}) {
    if (daysLeft <= 30) return Colors.red.shade400;
    if (daysLeft <= 90) return Colors.amber.shade400;
    return Colors.green.shade400;
  }
}
