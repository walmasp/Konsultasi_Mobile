import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KonselingApp());
}

class KonselingApp extends StatelessWidget {
  const KonselingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konseling Anonim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthScreen(), 
    );
  }
}