import 'package:flutter/material.dart';

class AppColors {
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSecondary = Color(0xFF2A2A2A);
  static const Color darkCard = Color(0xFF252525);
  static const Color fireOrange = Color(0xFFFF6B35);
  static const Color lightGray = Color(0xFF2A2A2A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [fireOrange, Color(0xFFFF8A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [darkBackground, Color(0xFF2D2D2D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
