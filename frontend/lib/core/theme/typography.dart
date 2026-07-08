import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: GoogleFonts.roboto(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
      displayMedium: GoogleFonts.roboto(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0),
      displaySmall: GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0),
      headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0),
      titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    );
  }
}
