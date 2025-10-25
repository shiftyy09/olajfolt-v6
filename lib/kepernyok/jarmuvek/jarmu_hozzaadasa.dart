// lib/kepernyok/jarmuvek/jarmu_hozzaadasa.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';
import '../../widgetek/jarmu_alapadatok_widget.dart';
import '../../widgetek/emlekezteto_kapcsolo_widget.dart';
import '../../widgetek/emlekezteto_tartalom_widget.dart';

class JarmuHozzaadasaKepernyo extends StatefulWidget {
  final Jarmu? vehicleToEdit;

  const JarmuHozzaadasaKepernyo({super.key, this.vehicleToEdit});

  @override
  State<JarmuHozzaadasaKepernyo> createState() =>
      _JarmuHozzaadasaKepernyoState();
}

class _JarmuHozzaadasaKepernyoState extends State<JarmuHozzaadasaKepernyo> {
  final _alapadatokFormKey = GlobalKey<FormState>();
  final _muszakiAdatokFormKey = GlobalKey<FormState>();

  String? _selectedMake;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;
  String _selectedVezerlesTipusa = 'Szíj';
  bool _remindersEnabled = false;
  final Map<String, TextEditingController> _kmBasedServiceControllers = {};
  final Map<String, DateTime?> _dateBasedServiceDates = {};
  final Map<String, bool> _serviceEnabledStates = {};
  final Map<String, String?> _serviceErrors = {};
  bool _isLoading = true;

  final List<String> _dateBasedServiceTypes = ['Műszaki vizsga'];
  final List<String> _kmBasedServiceTypes = [
    'Olajcsere',
    'Légszűrő',
    'Pollenszűrő',
    'Gyújtógyertya',
    'Üzemanyagszűrő',
    'Vezérlés (Szíj)',
    'Fékbetét (első)',
    'Fékbetét (hátsó)',
    'Fékfolyadék',
    'Hűtőfolyadék',
    'Kuplung'
  ];
  late List<String> _allServiceTypes;
  final List<String> _supportedCarMakes = [
    'Abarth',
    'Alfa Romeo',
    'Aston Martin',
    'Audi',
    'Bentley',
    'BMW',
    'Bugatti',
    'Cadillac',
    'Chevrolet',
    'Chrysler',
    'Citroën',
    'Dacia',
    'Daewoo',
    'Daihatsu',
    'Dodge',
    'Donkervoort',
    'DS',
    'Ferrari',
    'Fiat',
    'Fisker',
    'Ford',
    'Honda',
    'Hummer',
    'Hyundai',
    'Infiniti',
    'Iveco',
    'Jaguar',
    'Jeep',
    'Kia',
    'KTM',
    'Lada',
    'Lamborghini',
    'Lancia',
    'Land Rover',
    'Lexus',
    'Lotus',
    'Maserati',
    'Maybach',
    'Mazda',
    'McLaren',
    'Mercedes-Benz',
    'MG',
    'Mini',
    'Mitsubishi',
    'Morgan',
    'Nissan',
    'Opel',
    'Peugeot',
    'Porsche',
    'Renault',
    'Rolls-Royce',
    'Rover',
    'Saab',
    'Seat',
    'Skoda',
    'Smart',
    'SsangYong',
    'Subaru',
    'Suzuki',
    'Tesla',
    'Toyota',
    'Volkswagen',
    'Volvo'
  ];
  final List<String> _vezerlesOptions = ['Szíj', 'Lánc', 'Nincs'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeReminders();
    _loadDataIfEditing();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _kmBasedServiceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeFields() {
    _selectedMake = widget.vehicleToEdit?.make;
    _modelController = TextEditingController(text: widget.vehicleToEdit?.model);
    _yearController =
        TextEditingController(text: widget.vehicleToEdit?.year?.toString());
    _licensePlateController =
        TextEditingController(text: widget.vehicleToEdit?.licensePlate);
    _vinController = TextEditingController(text: widget.vehicleToEdit?.vin);
    _mileageController =
        TextEditingController(text: widget.vehicleToEdit?.mileage?.toString());
    _selectedVezerlesTipusa = widget.vehicleToEdit?.vezerlesTipusa ?? 'Szíj';
    if (_selectedMake != null && !_supportedCarMakes.contains(_selectedMake)) {
      if (_selectedMake!.isNotEmpty) {
        _supportedCarMakes.insert(0, _selectedMake!);
      }
    }
    _mileageController.addListener(() {
      if (_remindersEnabled) {
        setState(() => _validateAllServices());
      }
    });
  }

  void _initializeReminders() {
    _allServiceTypes = [..._dateBasedServiceTypes, ..._kmBasedServiceTypes];
    for (var type in _allServiceTypes) {
      _serviceEnabledStates[type] = false;
      _serviceErrors[type] = null;
      if (_kmBasedServiceTypes.contains(type)) {
        _kmBasedServiceControllers[type] = TextEditingController();
      } else {
        _dateBasedServiceDates[type] = null;
      }
    }
  }

  void _loadDataIfEditing() {
    if (widget.vehicleToEdit != null) {
      _remindersEnabled = true;
      _loadMaintenanceData(widget.vehicleToEdit!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMaintenanceData(Jarmu vehicle) async {
    final records = await AdatbazisKezelo.instance.getServicesForVehicle(
        vehicle.id!);
    for (var recordMap in records) {
      final record = Szerviz.fromMap(recordMap);
      for (var type in _allServiceTypes) {
        if (record.description.toLowerCase().contains(
            type.toLowerCase().replaceAll(" (szíj)", ""))) {
          setState(() {
            _serviceEnabledStates[type] = true;
            if (_dateBasedServiceTypes.contains(type)) {
              _dateBasedServiceDates[type] = record.date;
            } else if (_kmBasedServiceControllers.containsKey(type)) {
              _kmBasedServiceControllers[type]!.text =
                  record.mileage.toString();
            }
          });
          break;
        }
      }
    }
    if (mounted) {
      _validateAllServices();
      setState(() => _isLoading = false);
    }
  }

  void _validateService(String serviceType, String? value,
      {bool isFromToggle = false}) {
    if (!_remindersEnabled || !(_serviceEnabledStates[serviceType] ?? false)) {
      _serviceErrors[serviceType] = null;
      return;
    }
    if (value == null || value.isEmpty) {
      _serviceErrors[serviceType] = 'Kötelező megadni!';
    } else {
      final km = int.tryParse(value);
      final currentKm = int.tryParse(_mileageController.text);
      if (km != null && currentKm != null && km > currentKm) {
        _serviceErrors[serviceType] = 'Nem lehet több, mint a jelenlegi km!';
      } else {
        _serviceErrors[serviceType] = null;
      }
    }
  }

  void _validateAllServices() {
    for (var type in _kmBasedServiceTypes) {
      if (_kmBasedServiceControllers.containsKey(type)) {
        _validateService(type, _kmBasedServiceControllers[type]!.text);
      }
    }
  }

  Future<void> _saveOrUpdateVehicle() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final vehicle = Jarmu(
      id: widget.vehicleToEdit?.id,
      make: _selectedMake!,
      model: _modelController.text,
      year: int.tryParse(_yearController.text) ?? 0,
      licensePlate: _licensePlateController.text.toUpperCase(),
      vin: _vinController.text.isEmpty ? null : _vinController.text.toUpperCase(),
      mileage: int.tryParse(_mileageController.text) ?? 0,
      vezerlesTipusa: _selectedVezerlesTipusa,
      imagePath: null,
    );

    final db = AdatbazisKezelo.instance;
    int vehicleId;

    if (widget.vehicleToEdit == null) {
      vehicleId = await db.insert('vehicles', vehicle.toMap());
    } else {
      await db.update('vehicles', vehicle.toMap());
      vehicleId = vehicle.id!;
    }

    // ✅ CSAK AZ EMLÉKEZTETŐKET VALIDÁLD
    if (_remindersEnabled) {
      _validateAllServices();

      if (_serviceErrors.values.any((e) => e != null)) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Az emlékeztetőkben hibás adatok vannak!'),
              backgroundColor: Colors.redAccent));
        }
        return;
      }

      for (var type in _allServiceTypes) {
        final description = 'Emlékeztető alap: $type';
        final existingRecord = await db.findServiceByDescription(
            vehicleId, description);
        if (_serviceEnabledStates[type] == true) {
          int mileage = 0;
          DateTime date = DateTime.now();
          if (_dateBasedServiceTypes.contains(type)) {
            if (_dateBasedServiceDates[type] == null) continue;
            date = _dateBasedServiceDates[type]!;
          } else {
            final controller = _kmBasedServiceControllers[type]!;
            if (controller.text.isEmpty) continue;
            mileage = int.parse(controller.text);
          }
          final service = Szerviz(
            id: existingRecord?.id,
            vehicleId: vehicleId,
            date: date,
            mileage: mileage,
            description: description,
            cost: 0,
          );
          if (existingRecord != null) {
            await db.update('services', service.toMap());
          } else {
            await db.insert('services', service.toMap());
          }
        } else if (existingRecord != null) {
          await db.delete('services', existingRecord.id!);
        }
      }
    } else if (widget.vehicleToEdit != null) {
      await db.deleteReminderServicesForVehicle(vehicleId);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF121212),
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: Text(
          widget.vehicleToEdit == null ? 'Új Jármű' : 'Jármű Szerkesztése'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildSectionHeader('Alapadatok'),
          Form(
            key: _alapadatokFormKey,
            child: JarmuAlapadatokWidget(
              selectedMake: _selectedMake,
              onMakeChanged: (v) => setState(() => _selectedMake = v),
              modelController: _modelController,
              yearController: _yearController,
              licensePlateController: _licensePlateController,
              vinController: _vinController,
              mileageController: _mileageController,
              supportedCarMakes: _supportedCarMakes,
              vezerlesOptions: _vezerlesOptions,
              isFirstStep: true,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Azonosítók és Műszaki Adatok'),
          Form(
            key: _muszakiAdatokFormKey,
            child: JarmuAlapadatokWidget(
              selectedMake: _selectedMake,
              onMakeChanged: (v) {},
              modelController: _modelController,
              yearController: _yearController,
              licensePlateController: _licensePlateController,
              vinController: _vinController,
              mileageController: _mileageController,
              selectedVezerlesTipusa: _selectedVezerlesTipusa,
              onVezerlesChanged: (v) =>
                  setState(() {
                    if (v != null) _selectedVezerlesTipusa = v;
                  }),
              supportedCarMakes: _supportedCarMakes,
              vezerlesOptions: _vezerlesOptions,
              isSecondStep: true,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Karbantartási Emlékeztetők (Opcionális)'),
          EmlekeztetoKapcsoloWidget(isEnabled: _remindersEnabled,
              onToggle: (value) => setState(() => _remindersEnabled = value)),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _remindersEnabled ? EmlekeztetoTartalomWidget(
              kmBasedServiceControllers: _kmBasedServiceControllers,
              dateBasedServiceDates: _dateBasedServiceDates,
              serviceEnabledStates: _serviceEnabledStates,
              serviceErrors: _serviceErrors,
              onKmChanged: (type, value) {
                setState(() => _validateService(type, value));
              },
              onDateChanged: (type, date) {
                setState(() => _dateBasedServiceDates[type] = date);
              },
              onToggle: (String type, bool value) {
                setState(() {
                  _serviceEnabledStates[type] = value;
                  if (_kmBasedServiceTypes.contains(type)) {
                    final controller = _kmBasedServiceControllers[type]!;
                    if (value && controller.text.isEmpty &&
                        _mileageController.text.isNotEmpty) {
                      controller.text = _mileageController.text;
                    }
                    _validateService(type, controller.text, isFromToggle: true);
                    if (!value) {
                      controller.clear();
                      _serviceErrors[type] = null;
                    }
                  }
                });
              },
              dateBasedServiceTypes: _dateBasedServiceTypes,
              kmBasedServiceTypes: _kmBasedServiceTypes,
            ) : const SizedBox.shrink(),
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveOrUpdateVehicle,
        backgroundColor: Colors.orange,
        label: const Text('Mentés',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        icon: const Icon(Icons.save, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.orange.shade700,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
