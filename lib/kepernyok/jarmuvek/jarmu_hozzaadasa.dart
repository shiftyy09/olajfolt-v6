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
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];
  String? _selectedMake;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;
  String _selectedVezerlesTipus = 'Szíj';
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
    _selectedVezerlesTipus = widget.vehicleToEdit?.vezerlesTipusa ?? 'Szíj';

    if (_selectedMake != null && !_supportedCarMakes.contains(_selectedMake)) {
      if (_selectedMake!.isNotEmpty) _supportedCarMakes.insert(
          0, _selectedMake!);
    }
    _mileageController.addListener(() {
      if (_remindersEnabled) setState(() => _validateAllServices());
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
    if (_selectedMake == null || _selectedMake!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A márka kiválasztása kötelező!'),
          backgroundColor: Colors.redAccent));
      return;
    }
    if (!_formKeys.every((key) => key.currentState?.validate() ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kérjük, javítsd a pirossal jelölt hibákat!'),
          backgroundColor: Colors.redAccent));
      return;
    }
    final newMileage = int.tryParse(_mileageController.text);
    if (widget.vehicleToEdit != null && newMileage != null) {
      if (newMileage < widget.vehicleToEdit!.mileage) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
            'A kilométeróra-állás nem lehet kevesebb a korábban rögzítettnél!'),
            backgroundColor: Colors.redAccent));
        return;
      }
    }
    if (_remindersEnabled) {
      _validateAllServices();
      await Future.delayed(const Duration(milliseconds: 50));
      if (_serviceErrors.values.any((e) => e != null)) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Az emlékeztetőkben hibás adatok vannak!'),
            backgroundColor: Colors.redAccent));
        return;
      }
    }

    setState(() => _isLoading = true);

    final vehicle = Jarmu(
      id: widget.vehicleToEdit?.id,
      make: _selectedMake!,
      model: _modelController.text,
      year: int.tryParse(_yearController.text) ?? 0,
      licensePlate: _licensePlateController.text,
      vin: _vinController.text.isEmpty ? null : _vinController.text,
      mileage: int.tryParse(_mileageController.text) ?? 0,
      vezerlesTipusa: _selectedVezerlesTipus,
      imagePath: null, // Kép nincs
    );

    final db = AdatbazisKezelo.instance;
    int vehicleId;
    if (widget.vehicleToEdit == null) {
      vehicleId = await db.insert('vehicles', vehicle.toMap());
    } else {
      await db.update('vehicles', vehicle.toMap());
      vehicleId = vehicle.id!;
    }

    if (_remindersEnabled) {
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
              cost: 0
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
      appBar: AppBar(
        title: Text(
            widget.vehicleToEdit == null ? 'Új Jármű' : 'Jármű Szerkesztése'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(primary: Colors.orange),
        ),
        child: Stepper(
          margin: const EdgeInsets.all(0),
          controlsBuilder: (context, details) {
            return Container(
              margin: const EdgeInsets.only(top: 30),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _build3DButton(
                      text: _currentStep == 2 ? 'MENTÉS' : 'TOVÁBB',
                      onPressed: details.onStepContinue,
                      color: Colors.orange,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _build3DButton(
                        text: 'VISSZA',
                        onPressed: details.onStepCancel,
                        color: Colors.grey.shade800,
                        isPrimary: false,
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < 2 &&
                _formKeys[_currentStep].currentState!.validate()) {
              setState(() => _currentStep += 1);
            } else if (_currentStep == 2) {
              _saveOrUpdateVehicle();
            }
          },
          onStepCancel: _currentStep == 0 ? null : () =>
              setState(() => _currentStep -= 1),
          steps: [
            _buildStep(
              title: 'Alapadatok',
              content: Form(
                key: _formKeys[0],
                child: JarmuAlapadatokWidget(
                  selectedMake: _selectedMake,
                  onMakeChanged: (v) => setState(() => _selectedMake = v),
                  modelController: _modelController,
                  yearController: _yearController,
                  licensePlateController: TextEditingController(),
                  // Dummy
                  vinController: TextEditingController(),
                  // Dummy
                  mileageController: TextEditingController(),
                  // Dummy
                  selectedVezerlesTipus: _selectedVezerlesTipus,
                  onVezerlesChanged: (v) {},
                  supportedCarMakes: _supportedCarMakes,
                  vezerlesOptions: _vezerlesOptions,
                  isFirstStep: true,
                ),
              ),
              isActive: _currentStep >= 0,
            ),
            _buildStep(
              title: 'Azonosítók és Műszaki Adatok',
              content: Form(
                key: _formKeys[1],
                child: JarmuAlapadatokWidget(
                  selectedMake: _selectedMake,
                  onMakeChanged: (v) {},
                  modelController: _modelController,
                  yearController: _yearController,
                  licensePlateController: _licensePlateController,
                  vinController: _vinController,
                  mileageController: _mileageController,
                  selectedVezerlesTipus: _selectedVezerlesTipus,
                  onVezerlesChanged: (v) =>
                      setState(() {
                        if (v != null) _selectedVezerlesTipus = v;
                      }),
                  supportedCarMakes: _supportedCarMakes,
                  vezerlesOptions: _vezerlesOptions,
                  isSecondStep: true,
                ),
              ),
              isActive: _currentStep >= 1,
            ),
            _buildStep(
              title: 'Karbantartási Emlékeztetők (Opcionális)',
              content: Form(
                key: _formKeys[2],
                child: Column(
                  children: [
                    EmlekeztetoKapcsoloWidget(
                      isEnabled: _remindersEnabled,
                      onToggle: (value) =>
                          setState(() => _remindersEnabled = value),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: _remindersEnabled
                          ? EmlekeztetoTartalomWidget(
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
                              _validateService(
                                  type, controller.text, isFromToggle: true);
                              if (!value) {
                                controller.clear();
                                _serviceErrors[type] = null;
                              }
                            }
                          });
                        },
                        selectedVezerlesTipus: _selectedVezerlesTipus,
                        dateBasedServiceTypes: _dateBasedServiceTypes,
                        kmBasedServiceTypes: _kmBasedServiceTypes,
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveOrUpdateVehicle,
        backgroundColor: Colors.orange,
        tooltip: 'Jármű mentése',
        child: const Icon(Icons.save, color: Colors.black),
      ),
    );
  }

  Widget _build3DButton(
      {required String text, required VoidCallback? onPressed, required Color color, bool isPrimary = true}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: isPrimary ? Colors.black.withOpacity(0.4) : Colors
                .transparent, offset: const Offset(0, 4), blurRadius: 8,),
          ],
          border: isPrimary ? null : Border.all(
              color: Colors.grey.shade500, width: 1.5),
        ),
        child: Center(
          child: Text(text, style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,),
          ),
        ),
      ),
    );
  }

  Step _buildStep(
      {required String title, required Widget content, bool isActive = false}) {
    int stepIndex = _getStepIndex(title);
    return Step(
      title: Text(title, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold)),
      content: content,
      state: _currentStep > stepIndex ? StepState.complete : (_currentStep ==
          stepIndex ? StepState.editing : StepState.indexed),
      isActive: _currentStep >= stepIndex,
    );
  }

  int _getStepIndex(String title) {
    if (title == 'Alapadatok') return 0;
    if (title == 'Azonosítók és Műszaki Adatok') return 1;
    if (title == 'Karbantartási Emlékeztetők (Opcionális)') return 2;
    return 0;
  }
}