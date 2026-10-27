import 'package:flutter/painting.dart';

/// Mengurai `warna` status: nama umum ("Red") atau hex (#RGB / #RRGGBB). Null bila tidak dikenali.
Color? statusColor(String? raw) {
  final s = raw?.trim().toLowerCase();
  if (s == null || s.isEmpty) return null;
  const names = {
    'red': 0xFFEF4444,
    'orange': 0xFFF97316,
    'yellow': 0xFFEAB308,
    'green': 0xFF22C55E,
    'blue': 0xFF3B82F6,
    'purple': 0xFFA855F7,
    'pink': 0xFFEC4899,
    'gray': 0xFF9CA3AF,
    'grey': 0xFF9CA3AF,
  };
  final named = names[s];
  if (named != null) return Color(named);

  var h = s.startsWith('#') ? s.substring(1) : s;
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}