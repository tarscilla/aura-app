import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:google_fonts/google_fonts.dart";
import "package:firebase_core/firebase_core.dart";
import "package:provider/provider.dart";

import "firebase_options.dart";
import "package:my_app/pages/auth_gate.dart";
import "package:my_app/services/theme_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeService = ThemeService();
  await themeService.carregarTema();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,

          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFF7F9),
            primaryColor: const Color(0xFFF08A9C),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF08A9C),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF211B20),
            primaryColor: const Color(0xFFF08A9C),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF08A9C),
              brightness: Brightness.dark,
              surface: const Color(0xFF30262D),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),

          home: const AuthGate(),
        );
      },
    );
  }
}
