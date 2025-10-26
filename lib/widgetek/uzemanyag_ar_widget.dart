import 'package:car_maintenance_app/szolgaltatasok/uzemanyag_ar_szolgaltatas.dart';
import 'package:flutter/material.dart';

class UzemanyagArWidget extends StatefulWidget {
  const UzemanyagArWidget({super.key});

  @override
  State<UzemanyagArWidget> createState() => _UzemanyagArWidgetState();
}

class _UzemanyagArWidgetState extends State<UzemanyagArWidget> {
  // A lekérdezés logikája ide kerül át a képernyőről
  final UzemanyagArSzolgaltatas _arSzolgaltatas = UzemanyagArSzolgaltatas();
  Future<UzemanyagArak?>? _fuelPricesFuture;

  @override
  void initState() {
    super.initState();
    _fuelPricesFuture = _arSzolgaltatas.fetchFuelPrices();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UzemanyagArak?>(
      future: _fuelPricesFuture,
      builder: (context, snapshot) {
        // Töltés közben egy egyszerű animációt mutatunk
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
                child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        // Hiba esetén vagy ha nincs adat, egy hibaüzenetet jelenítünk meg
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.red.withOpacity(0.2),
            child: const Text(
              'Az üzemanyagárak jelenleg nem elérhetők.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // === ITT VAN AZ ÚJ, DIZÁJNOS MEGJELENÍTÉS ===
        final arak = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Enyhén eltérő sötét szín
            border: Border(top: BorderSide(
                color: Colors.amber.withOpacity(0.5), width: 1.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPriceColumn(
                label: '95-ös Benzin',
                price: arak.benzinAr,
                iconText: '95', // A te ötleted!
                iconColor: Colors.green.shade400,
              ),
              _buildPriceColumn(
                label: 'Gázolaj',
                price: arak.gazolajAr,
                iconText: 'D', // A te ötleted!
                iconColor: Colors.blue.shade400,
              ),
            ],
          ),
        );
      },
    );
  }

  // Segédfüggvény egy ár-oszlop felépítéséhez, az új ikonnal
  Widget _buildPriceColumn({
    required String label,
    required double price,
    required String iconText,
    required Color iconColor,
  }) {
    return Row(
      children: [
        // Az új, stilizált ikon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              iconText,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // A szöveges rész
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${price.toStringAsFixed(0)} Ft/l',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
