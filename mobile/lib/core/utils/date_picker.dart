import 'package:flutter/material.dart';
Future<DateTime?> pickDateInRange(
  BuildContext context, {
  DateTime? initial,
  DateTime? fallbackInitial,
  required DateTime first,
  required DateTime last,
}) {
  var lo = DateUtils.dateOnly(first);
  var hi = DateUtils.dateOnly(last);
  final cur = initial == null ? null : DateUtils.dateOnly(initial);
  if (cur != null) {
    if (cur.isBefore(lo)) lo = cur;
    if (cur.isAfter(hi)) hi = cur;
  }
  var start = cur ?? (fallbackInitial == null ? lo : DateUtils.dateOnly(fallbackInitial));
  if (start.isBefore(lo)) start = lo;
  if (start.isAfter(hi)) start = hi;
  return showDatePicker(context: context, initialDate: start, firstDate: lo, lastDate: hi);
}