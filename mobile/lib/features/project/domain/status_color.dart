import 'package:flutter/painting.dart';
import 'package:slamed_app/core/utils/color_utils.dart';

const _names = {
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

Color? statusColor(String? raw) {
  final s = raw?.trim().toLowerCase();
  if (s == null || s.isEmpty) return null;
  final named = _names[s];
  return named != null ? Color(named) : parseHexColor(s);
}