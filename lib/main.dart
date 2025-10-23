// lib/main.dart
import 'package:car_maintenance_app/kepernyok/indito/indito_kepernyo.dart';
import 'package:car_maintenance_app/szolgaltatasok/ertesites_szolgaltatas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  // Biztosítja, hogy a Flutter motor inicializálva legyen, mielőtt bármi futna.
  WidgetsFlutterBinding.ensureInitialized();

  // Beállítja az alapértelmezett nyelvet a formázásokhoz (pl. dátumok)
  Intl.defaultLocale = 'hu_HU';
  await initializeDateFormatting();

  // Inicializálja az értesítési szolgáltatást
  final ErtesitesSzolgaltatas ertesitesSzolgaltatas = ErtesitesSzolgaltatas();
  await ertesitesSzolgaltatas.init();
  await ertesitesSzolgaltatas.requestPermissions();

  // Elindítja az alkalmazást
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olajfolt Szerviz-napló',

      // Magyar nyelv beállítása a beépített Flutter widgetekhez (pl. naptár)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('hu', 'HU'),
      ],
      locale: const Locale('hu', 'HU'),

      // === A TELJES, MINDENT FELÜLÍRÓ TÉMA BEÁLLÍTÁSA ===
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        // Ez a fő színpaletta
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',

        // A lila kurzor és kijelölés színeinek felülírása narancsra
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.orange,
          selectionColor: Colors.orange.withOpacity(0.3),
          selectionHandleColor: Colors.orange,
        ),

        // === ITT A MEGOLDÁS A DIALÓGUSOKBAN LÉVŐ LILA GOMBOKRA ===
        // A szöveges gombok (TextButton) központi stílusát itt írjuk felül.
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            // A gomb szövegének színe narancs lesz a lila helyett.
            foregroundColor: Colors.orange,
          ),
        ),
        // ========================================================
      ),

      home: const InditoKepernyo(),
      debugShowCheckedModeBanner: false,
    );
  }
}
