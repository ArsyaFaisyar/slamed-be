/// "150000.00" -> "Rp 150.000"
String formatRupiah(String raw) {
  final n = double.tryParse(raw)?.round() ?? 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp ${n < 0 ? '-' : ''}$b';
}