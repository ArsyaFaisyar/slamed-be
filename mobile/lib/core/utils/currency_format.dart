/// "1500000.00" -> "Rp 1.500.000". Null atau kosong -> null.
String? formatRupiah(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = double.tryParse(raw.trim());
  if (v == null) return raw;
  final digits = v.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $buf';
}