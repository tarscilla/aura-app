import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:google_fonts/google_fonts.dart";
import "package:firebase_core/firebase_core.dart";
import "firebase_options.dart";
import "package:my_app/pages/auth_gate.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}