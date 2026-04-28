import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color forestGreen = Color(0xFF1B4332);
  static const Color harvestAmber = Color(0xFFF59E0B);
  static const Color soilBrown = Color(0xFF92400E);
  static const Color offWhite = Color(0xFFFDF6EC);
  static const Color bgDark = Color(0xFF0D1B0E);
  static const Color cardDark = Color(0xFF142B18);
  static const Color greenMid = Color(0xFF2D6A4F);

  // Urgency colors
  static const Color urgencyRed = Color(0xFFEF4444);
  static const Color urgencyYellow = Color(0xFFF59E0B);
  static const Color urgencyGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF3B82F6);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: forestGreen,
      secondary: harvestAmber,
      surface: cardDark,
      error: urgencyRed,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}
