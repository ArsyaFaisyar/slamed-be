import 'package:flutter/material.dart';

/// Mengubah "#RRGGBB", "#RGB", "RRGGBB", atau "0xAARRGGBB" menjadi [Color].
/// Mengembalikan null jika formatnya tidak dikenali.
Color? parseHexColor(String? s) {
  if (s == null) return null;
  var h = s.trim();
  if (h.isEmpty) return null;
  if (h.startsWith('#')) {
    h = h.substring(1);
  } else if (h.toLowerCase().startsWith('0x')) {
    h = h.substring(2);
  }
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}