import 'package:flutter/material.dart';

/// True jika [d] jatuh di dalam [r] (batas awal dan akhir ikut, jam diabaikan).
bool dateInRange(DateTime d, DateTimeRange r) {
  final day = DateTime(d.year, d.month, d.day);
  final start = DateTime(r.start.year, r.start.month, r.start.day);
  final end = DateTime(r.end.year, r.end.month, r.end.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

/// Dialog pilih rentang tanggal; null jika dibatalkan.
Future<DateTimeRange?> pickDateRange(BuildContext context, DateTimeRange? current) {
  final now = DateTime.now();
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 3),
    lastDate: DateTime(now.year + 2, 12, 31),
    initialDateRange: current,
    helpText: 'Pilih rentang tanggal',
    saveText: 'Terapkan',
  );
}