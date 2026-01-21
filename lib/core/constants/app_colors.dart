import 'package:flutter/material.dart';

/// App color palette based on Angkor-inspired design
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color deepPurple = Color(0xFF1A0A2E);
  static const Color royalPurple = Color(0xFF2D1B4E);
  static const Color templeGold = Color(0xFFD4AF37);
  static const Color warmGold = Color(0xFFFFD700);

  // Backgrounds
  static const Color background = deepPurple;
  static const Color surface = royalPurple;
  static const Color surfaceLight = Color(0xFF3D2B5E);

  // Board Colors
  static const Color lightSquare = Color(0xFF8B7355);
  static const Color darkSquare = Color(0xFF4A3728);

  // Highlights
  static const Color selectedSquare = Color(0x80FFD700);
  static const Color validMove = Color(0x664ADE80);
  static const Color lastMove = Color(0x66D4AF37); // Light gold for previous move
  static const Color checkHighlight = Color(0x99EF4444); // Light red for king in check

  // Semantic Colors
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF808080);

  // Piece Colors
  static const Color whitePiece = Color(0xFFF5F5F5);
  static const Color whitePieceShadow = Color(0xFFE0E0E0);
  static const Color goldPiece = Color(0xFFD4AF37);
  static const Color goldPieceShadow = Color(0xFFB8860B);
}
