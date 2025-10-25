import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kozos_bemeneti_kartya.dart';

class JarmuAlapadatokWidget extends StatelessWidget {
  final String? selectedMake;
  final Function(String?) onMakeChanged;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController licensePlateController;
  final TextEditingController vinController;
  final TextEditingController mileageController;

  final String? selectedVezerlesTipusa;
  final Function(String?)? onVezerlesChanged;

  final List<String> supportedCarMakes;
  final List<String> vezerlesOptions;
  final bool isFirstStep;
  final bool isSecondStep;

  const JarmuAlapadatokWidget({
    super.key,
    required this.selectedMake,
    required this.onMakeChanged,
    required this.modelController,
    required this.yearController,
    required this.licensePlateController,
    required this.vinController,
    required this.mileageController,
    required this.supportedCarMakes,
    required this.vezerlesOptions,
    this.selectedVezerlesTipusa,
    this.onVezerlesChanged,
    this.isFirstStep = false,
    this.isSecondStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isFirstStep) ...[
          _buildMakeDropdown(),
          _buildTextField(
              title: 'Modell',
              controller: modelController,
              icon: Icons.star_outline,
              shouldValidate: false),
          _buildTextField(
              title: 'Évjárat',
              controller: yearController,
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
              maxLength: 4,
              shouldValidate: false),
        ],
        if (isSecondStep) ...[
          _buildTextField(
              title: 'Kilométeróra',
              controller: mileageController,
              icon: Icons.speed,
              keyboardType: TextInputType.number,
              shouldValidate: true),
          _buildDropdown(
            title: 'Vezérlés',
            icon: Icons.settings,
            value: selectedVezerlesTipusa,
            onChanged: onVezerlesChanged,
            items: vezerlesOptions,
          ),
          _buildTextField(
              title: 'Rendszám',
              controller: licensePlateController,
              textCapitalization: TextCapitalization.characters,
              icon: Icons.pin,
              shouldValidate: true),
          _buildTextField(
              title: 'Alvázszám',
              controller: vinController,
              textCapitalization: TextCapitalization.characters,
              icon: Icons.qr_code,
              optional: true,
              shouldValidate: false),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    bool optional = false,
    bool shouldValidate = true,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    int? maxLength,
  }) {
    return KozosBemenetiKartya(
        icon: icon,
        title: optional ? '$title (opcionális)' : title,
        child: TextFormField(
            controller: controller,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLength: maxLength,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true),
            validator: (value) {
              // ✅ Csak akkor validál, ha shouldValidate = true
              if (!shouldValidate) {
                return null;
              }

              if (!optional && (value == null || value.isEmpty)) {
                return 'Kötelező mező';
              }
              if (title == 'Évjárat' && value != null && value.isNotEmpty &&
                  value.length != 4) {
                return '4 számjegy';
              }
              return null;
            }));
  }

  Widget _buildMakeDropdown() {
    return KozosBemenetiKartya(
      icon: Icons.directions_car,
      title: 'Márka',
      padding: const EdgeInsets.only(left: 16, right: 10, top: 12, bottom: 12),
      child: DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Keresés...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange)),
              ),
            ),
            menuProps: MenuProps(backgroundColor: const Color(0xFF2A2A2A)),
            itemBuilder: (context, item, isSelected) => ListTile(
                title: Text(item,
                    style: TextStyle(
                        color: isSelected ? Colors.orange : Colors.white))),
          ),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            baseStyle: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            dropdownSearchDecoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true),
          ),
          items: supportedCarMakes,
          selectedItem: selectedMake,
          onChanged: onMakeChanged,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Kötelező mező' : null),
    );
  }

  Widget _buildDropdown({
    required String title,
    required IconData icon,
    required String? value,
    required Function(String?)? onChanged,
    required List<String> items,
  }) {
    return KozosBemenetiKartya(
      icon: icon,
      title: title,
      padding: const EdgeInsets.only(left: 16, right: 10, top: 12, bottom: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
            onChanged: onChanged,
            items: items
                .map<DropdownMenuItem<String>>((String value) =>
                DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                .toList()),
      ),
    );
  }
}
