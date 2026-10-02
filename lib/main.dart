import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'fr/jump_screen.dart' as fr;
import 'en/jump_screen.dart' as en;

// ═══════════════════════════════════════════════════════════════════════════
// RÉTRO JUMP — application autonome (même jeu que dans Foclabroc Remote)
// Langue : français si le téléphone est en français, anglais sinon.
// Le jeu existe en deux bibliothèques (lib/fr et lib/en) copiées telles quelles
// depuis Foclabroc Remote : seule la version de la langue choisie est affichée.
// ═══════════════════════════════════════════════════════════════════════════

bool get _isFrench =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase() == 'fr';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Écran toujours allumé (le jeu peut se jouer à l'inclinaison, sans toucher l'écran)
  await WakelockPlus.enable();
  runApp(const RetroJumpApp());
}

class RetroJumpApp extends StatelessWidget {
  const RetroJumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _isFrench ? 'Rétro Jump' : 'Retro Jump',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE02020),
          surface: const Color(0xFF1C2230),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C2230),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161A22),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 14),
          bodyMedium: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFFE02020),
          thumbColor: const Color(0xFFE02020),
          overlayColor: const Color(0xFFE02020).withOpacity(0.2),
          inactiveTrackColor: Colors.white12,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE02020),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: _isFrench ? const fr.JumpScreen() : const en.JumpScreen(),
    );
  }
}
