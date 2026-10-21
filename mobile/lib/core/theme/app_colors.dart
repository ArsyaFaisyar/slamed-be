import 'package:flutter/material.dart';

/// Palet navy. Warna lama dipertahankan; ditambah lapisan permukaan dan gradasi.
abstract final class AppColors {
  static const bg = Color(0xFF0B0E24);
  static const bgTop = Color(0xFF111742);
  static const surface = Color(0xFF141935);
  static const surfaceHigh = Color(0xFF1B2250);
  static const surfaceNav = Color(0xFF0F1330);
  static const inputFill = Color(0xFF0A0E26);
  static const border = Color(0xFF2F3560);
  static const divider = Color(0xFF272D52);
  static const text = Color(0xFFE8EBF7);
  static const muted = Color(0xFF8F97B8);

  static const primary = Color(0xFF5DA9FF);
  static const primaryDeep = Color(0xFF4A94F5);
  static const onPrimary = Color(0xFF06102A);
  static const glow = Color(0x335DA9FF);
  static const primaryBorder = Color(0x665DA9FF);
  static const shadow = Color(0x66000000);

  static const error = Color(0xFFFF9A9A);
  static const infoFg = Color(0xFF9CC4FF);
  static const infoBg = Color(0xFF1B2F5E);
  static const successFg = Color(0xFF6EE7B7);
  static const successBg = Color(0xFF0E3326);
  static const warningFg = Color(0xFFF5C451);
  static const warningBg = Color(0xFF3A2E10);
  static const dangerFg = Color(0xFFFF9A9A);
  static const dangerBg = Color(0xFF4A1818);

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2048), Color(0xFF131838)],
  );
  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDeep],
  );
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bg],
    stops: [0.0, 0.55],
  );
}