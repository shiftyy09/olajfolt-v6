import 'package:flutter/material.dart';
import 'kozos_menu_kartya.dart';

class EmlekeztetoKapcsoloWidget extends StatelessWidget {
  final bool isEnabled;
  final Function(bool) onToggle;

  const EmlekeztetoKapcsoloWidget({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return KozosMenuKartya(
      icon: Icons.handyman_outlined,
      title: "Karbantartási emlékeztetők",
      subtitle: "Automatikus értesítések beállítása",
      color: Colors.orange,
      onTap: () => onToggle(!isEnabled),
      trailing: Switch(
        value: isEnabled,
        onChanged: onToggle,
        activeColor: Colors.orange,
        inactiveThumbColor: Colors.grey,
      ),
    );
  }
}