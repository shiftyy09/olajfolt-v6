import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EmlekeztetoTartalomWidget extends StatefulWidget {
  final Map<String, TextEditingController> kmBasedServiceControllers;
  final Map<String, DateTime?> dateBasedServiceDates;
  final Map<String, bool> serviceEnabledStates;
  final Map<String, String?> serviceErrors;
  final Function(String, String?) onKmChanged;
  final Function(String, DateTime?) onDateChanged;
  final Function(String, bool) onToggle;
  final String? selectedVezerlesTipus;
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
    this.selectedVezerlesTipus,
    required this.dateBasedServiceTypes,
    required this.kmBasedServiceTypes,
  });

  @override
  State<EmlekeztetoTartalomWidget> createState() =>
      _EmlekeztetoTartalomWidgetState();
}

class _EmlekeztetoTartalomWidgetState extends State<EmlekeztetoTartalomWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._buildDateBasedServices(context),
        ..._buildKmBasedServices(),
      ],
    );
  }

  List<Widget> _buildDateBasedServices(BuildContext context) {
    return widget.dateBasedServiceTypes.map((type) {
      bool isEnabled = widget.serviceEnabledStates[type] ?? false;
      DateTime? selectedDate = widget.dateBasedServiceDates[type];

      return _buildReminderCard(
        type: type,
        icon: Icons.calendar_today,
        isEnabled: isEnabled,
        onToggle: () => widget.onToggle(type, !isEnabled),
        child: isEnabled
            ? GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              widget.onDateChanged(type, picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat('yyyy.MM.dd').format(selectedDate)
                  : 'Válassz dátumot',
              style: TextStyle(
                color: selectedDate != null
                    ? Colors.white
                    : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
        )
            : const SizedBox.shrink(),
      );
    }).toList();
  }

  List<Widget> _buildKmBasedServices() {
    return widget.kmBasedServiceTypes.map((type) {
      bool isEnabled = widget.serviceEnabledStates[type] ?? false;
      String? error = widget.serviceErrors[type];
      TextEditingController controller =
          widget.kmBasedServiceControllers[type] ?? TextEditingController();

      return _buildReminderCard(
        type: type,
        icon: Icons.speed,
        isEnabled: isEnabled,
        onToggle: () => widget.onToggle(type, !isEnabled),
        child: isEnabled
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Km érték',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: error != null
                        ? Colors.red
                        : Colors.grey.shade700,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: error != null ? Colors.red : Colors.orange,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                suffix: const Text(
                  'km',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              onChanged: (value) => widget.onKmChanged(type, value),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        )
            : const SizedBox.shrink(),
      );
    }).toList();
  }

  Widget _buildReminderCard({
    required String type,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? Colors.orange.shade400 : Colors.grey.shade700,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.orange.shade400 : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (_) => onToggle(),
                activeColor: Colors.orange.shade400,
              ),
            ],
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: child,
            ),
        ],
      ),
    );
  }
}
