import 'package:flutter/material.dart';

class KozosBemenetiKartya extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child; //
  final EdgeInsets? padding;

  const KozosBemenetiKartya({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Amikor a kártyára kattintunk, megkeressük a benne lévő első beviteli mezőt,
        // és automatikusan ráadjuk a fókuszt, hogy a felhasználó gépelhessen.
        // Ezzel oldjuk meg a "nehézkes kattintás" problémáját.
        FocusScope.of(context).requestFocus(Focus
            .of(context)
            .children
            .first);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFF1E1E1E),
        // Sötét háttér a kártyának
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: Colors.white.withOpacity(0.1), width: 1), // Finom keret
        ),
        child: Padding(
          padding: padding ??
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Itt jelenik meg a TextFormField vagy a DropdownSearch,
                    // ami a `child` paraméterben érkezik.
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}