// lib/kepernyok/indito/indito_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../fooldal/fooldal_kepernyo.dart';
import 'onboarding_kepernyo.dart';

class InditoKepernyo extends StatefulWidget {
  const InditoKepernyo({super.key});

  @override
  State<InditoKepernyo> createState() => _InditoKepernyoState();
}

class _InditoKepernyoState extends State<InditoKepernyo> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;

    setState(() {
      _hasCompletedOnboarding = completed;
      _isLoading = false;
    });

    if (mounted) {
      if (!completed) {
        // Onboarding nem volt elvégezve - mutasd meg
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OnboardingKepernyo(),
            fullscreenDialog: true,
          ),
        );

        // Ha befejezték az onboardingot, megy tovább
        if (result == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FooldalKepernyo()),
          );
        }
      } else {
        // Onboarding már elvégezve - megy az főoldalra
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FooldalKepernyo()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: _isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 64,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation(Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Olajfolt betöltése...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        )
            : const SizedBox.shrink(),
      ),
    );
  }
}
