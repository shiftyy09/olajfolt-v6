// lib/kepernyok/indito/indito_kepernyo.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../fooldal/fooldal_kepernyo.dart';

class InditoKepernyo extends StatefulWidget {
  const InditoKepernyo({super.key});

  @override
  State<InditoKepernyo> createState() => _InditoKepernyoState();
}

class _InditoKepernyoState extends State<InditoKepernyo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializeApp() async {
    // Elindítjuk az adatbázis betöltését és egy minimális várakozási időt
    final dbFuture = AdatbazisKezelo.instance.database;
    final minDelayFuture =
        Future.delayed(const Duration(milliseconds: 2000)); // 2 másodperc

    // Megvárjuk, amíg mindkettő befejeződik
    await Future.wait([dbFuture, minDelayFuture]);

    // Navigáció, csak ha a képernyő még létezik
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FooldalKepernyo(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // A Column-t kivettem, mert már csak egyetlen widget, a kép van benne.
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/olajfolt.png',
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
        // A Text("Szerviz-napló") és a SizedBox innen lett eltávolítva.
      ),
    );
  }
}
