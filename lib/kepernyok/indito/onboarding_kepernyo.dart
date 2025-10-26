// lib/kepernyok/indito/onboarding_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingKepernyo extends StatefulWidget {
  const OnboardingKepernyo({super.key});

  @override
  State<OnboardingKepernyo> createState() => _OnboardingKepernyoState();
}

class _OnboardingKepernyoState extends State<OnboardingKepernyo> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.directions_car,
      'title': 'Üdvözlünk az Olajfolt-ban! 🚗',
      'subtitle': 'A te személyes karbantartási asszisztensed',
      'description':
      'Az Olajfolt segít nyomon követni járműved összes karbantartási eseményét.',
    },
    {
      'icon': Icons.add_circle,
      'title': 'Lépés 1: Jármű Hozzáadása',
      'subtitle': 'Kezdj egy új járművel',
      'description':
      'Nyomj az "+" gombra és add meg járműved adatait:\n\n'
          '✓ Márka, modell, évjárat\n'
          '✓ Rendszám, VIN szám\n'
          '✓ Jelenlegi km állás\n'
          '✓ Opcionálisan: karbantartási emlékeztetők',
    },
    {
      'icon': Icons.edit,
      'title': 'Lépés 2: Emlékeztetők Beállítása',
      'subtitle': 'Válaszd ki, miről szeretnél értesítést',
      'description':
      'A jármű hozzáadásakor bekapcsolhatod az emlékeztetőket:\n\n'
          '🔧 Olajcsere, szűrők cseréje\n'
          '🏁 Műszaki vizsgák\n'
          '⚙️ Egyéb szervizek\n\n'
          'Ezek később is módosíthatók a Beállítások alatt!',
    },
    {
      'icon': Icons.notifications_active,
      'title': 'Lépés 3: Értesítések',
      'subtitle': 'Sosem maradsz le szervizről',
      'description':
      '📱 KM alapú értesítések: 1000 km-rel az esedékesség előtt\n\n'
          '📅 Műszaki vizsga: 1 hónap és 1 hét előtte\n\n'
          '💡 Minden szervizről csak 1x értesítünk - nem flood!\n\n'
          'Frissítsd a km-t az appban, hogy pontosak maradjanak!',
    },
    {
      'icon': Icons.analytics,
      'title': 'Lépés 4: Kövesd Nyomon',
      'subtitle': 'Karbantartási napló',
      'description':
      'Minden egyes szerviz után add meg:\n\n'
          '• Az elvégzett munka leírása\n'
          '• A km-állás abban az időpontban\n'
          '• Az ár (opcionális)\n'
          '• A dátum\n\n'
          'Ezt később a szerviznapló alatt találod!',
    },
    {
      'icon': Icons.check_circle,
      'title': 'Kész vagy! 🎉',
      'subtitle': 'Kezdd el az alkalmazás használatát',
      'description':
      'Pár tipp:\n\n'
          '💾 CSV-be exportálhatod az adataidat\n'
          '📄 PDF-et készíthetsz egy járműről\n'
          '🔧 A beállítások alatt módosíthatod az értesítéseket\n\n'
          'Sok sikert! 🚗✨',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // === PROGRESS BAR ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _pages.length,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade700,
                  valueColor:
                  AlwaysStoppedAnimation(Colors.orange.shade400),
                ),
              ),
            ),

            // === MAIN CONTENT ===
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.shade400.withOpacity(0.2),
                          ),
                          child: Icon(
                            page['icon'],
                            size: 50,
                            color: Colors.orange.shade400,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          page['subtitle'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          page['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // === NAVIGATION ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Vissza gomb
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Vissza',
                        style: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 70),

                  // Számláló
                  Text(
                    '${_currentPage + 1} / ${_pages.length}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),

                  // Következő / Befejezés gomb
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Kezdésnek! 🚀'
                          : 'Következő',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
