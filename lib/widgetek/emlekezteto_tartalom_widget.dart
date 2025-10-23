// lib/widgetek/emlekezteto_tartalom_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EmlekeztetoTartalomWidget extends StatelessWidget {
  final Map<String, TextEditingController> kmBasedServiceControllers;
  final Map<String, DateTime?> dateBasedServiceDates;
  final Map<String, bool> serviceEnabledStates;
  final Map<String, String?> serviceErrors;
  final Function(String, String?) onKmChanged;
  final Function(String, DateTime) onDateChanged;
  final Function(String, bool) onToggle;
  final String selectedVezerlesTipus;

  final List<String> dateBasedServiceTypes;
  final List<String> kmBasedServiceTypes;

  const EmlekeztetoTartalomWidget({
    super.key,
    required this.kmBasedServiceControllers,
    required this.dateBasedServiceDates,
    required this.serviceEnabledStates,
    required this.serviceErrors,
    required this.onKmChanged,
    required this.onDateChanged,
    required this.onToggle,
    required this.selectedVezerlesTipus,
    required this.dateBasedServiceTypes,
    required this.kmBasedServiceTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ...dateBasedServiceTypes.map((type) =>
                _buildDatePickerRow(context, type)),
            ...kmBasedServiceTypes.map((type) {
              if (type == 'Vezérlés (Szíj)' &&
                  selectedVezerlesTipus != 'Szíj') {
                return const SizedBox.shrink();
              }
              return _buildMileageInputRow(
                  type, key: ValueKey('mileage_input_$type'));
            })
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(BuildContext context, String serviceType) {
    final bool isEnabled = serviceEnabledStates[serviceType] ?? false;
    final String dateText = dateBasedServiceDates[serviceType] != null
        ? DateFormat('yyyy. MM. dd.').format(
        dateBasedServiceDates[serviceType]!)
        : 'Dátum megadása';

    Future<void> pickDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: dateBasedServiceDates[serviceType] ?? DateTime.now(),
        firstDate: DateTime(DateTime
            .now()
            .year - 20),
        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        locale: const Locale('hu', 'HU'),
        helpText: 'MIKOR VOLT AZ ESEMÉNY?',
        confirmText: 'KIVÁLASZT',
        cancelText: 'MÉGSE',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.orange,
                onPrimary: Colors.black,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF2A2A2A),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != dateBasedServiceDates[serviceType]) {
        onDateChanged(serviceType, picked);
      }
    }

    return _buildServiceTile(
      title: serviceType,
      isEnabled: isEnabled,
      onToggle: (value) => onToggle(serviceType, value),
      child: Material(
        color: isEnabled ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: !isEnabled ? null : pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dateText, style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey[600],
                    fontSize: 16)),
                const SizedBox(width: 8),
                Icon(Icons.edit_calendar_outlined,
                    color: isEnabled ? Colors.orange : Colors.transparent,
                    size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMileageInputRow(String serviceType, {Key? key}) {
    bool isEnabled = serviceEnabledStates[serviceType] ?? false;
    return _buildServiceTile(
        key: key,
        title: serviceType,
        isEnabled: isEnabled,
        errorText: serviceErrors[serviceType],
        onToggle: (value) => onToggle(serviceType, value),
        child: SizedBox(
            width: 130,
            child: TextFormField(
                controller: kmBasedServiceControllers[serviceType],
                enabled: isEnabled,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onKmChanged(serviceType, value),
                decoration: InputDecoration(
                    suffixIcon: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                            label: const Text(
                                'km', style: TextStyle(color: Colors.black)),
                            backgroundColor: isEnabled ? Colors.white70 : Colors
                                .transparent,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(height: 0, fontSize: 0)))));
  }

  Widget _buildServiceTile({
    required String title,
    required Widget child,
    required bool isEnabled,
    String? errorText,
    required Function(bool) onToggle,
    Key? key,
  }) {
    final bool hasError = errorText != null;
    return Material(
        key: key,
        color: isEnabled ? (hasError ? Colors.red.withOpacity(0.25) : Colors
            .black.withOpacity(0.3)) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: () => onToggle(!isEnabled),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Checkbox(
                            value: isEnabled,
                            onChanged: (v) => onToggle(v ?? false),
                            activeColor: Colors.orange,
                            checkColor: Colors.black,
                            side: BorderSide(
                                color: Colors.white70, width: 1.5)),
                        Expanded(child: Text(title, style: const TextStyle(
                            color: Colors.white, fontSize: 16))),
                        child
                      ]),
                      if (hasError && isEnabled)
                        Padding(
                            padding: const EdgeInsets.only(
                                left: 48.0, bottom: 8.0, right: 16.0),
                            child: Text(errorText!, style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)))
                    ]))));
  }
}