import 'package:flutter/services.dart';

/// "1500000" -> "1.500.000". [digits] harus hanya berisi angka.
String groupThousands(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Angka dengan titik ribuan: 1500000 -> "1.500.000".
String formatNumber(num n) => '${n < 0 ? '-' : ''}${groupThousands(n.round().abs().toString())}';

/// "1500000.00" -> "Rp 1.500.000". Null atau kosong -> null; teks bukan angka dikembalikan apa adanya.
String? formatRupiah(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = double.tryParse(raw.trim());
  if (v == null) return raw;
  return 'Rp ${formatNumber(v)}';
}

/// Hanya digit dari teks kolom ("1.500.000" -> "1500000"). Kosong menjadi "0".
/// Dipakai saat mengirim ke server.
String rupiahDigits(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  return d.isEmpty ? '0' : d.replaceFirst(RegExp(r'^0+(?=\d)'), '');
}

/// Isi awal kolom dari nilai server ("1500000.00" -> "1.500.000"). Nol atau kosong -> "".
String rupiahInputText(String? raw) {
  final v = double.tryParse((raw ?? '').trim());
  if (v == null || v.round() <= 0) return '';
  return groupThousands(v.round().toString());
}

/// Memformat isian angka menjadi pemisah ribuan saat diketik. Hanya digit yang
/// diterima; kursor dipertahankan saat mengedit di tengah angka.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter({this.maxDigits = 12});
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final all = text.replaceAll(RegExp(r'\D'), '');
    var digits = all.replaceFirst(RegExp(r'^0+(?=\d)'), ''); // buang nol di depan
    final removedZeros = all.length - digits.length;
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = groupThousands(digits);

    // Pertahankan posisi kursor: hitung digit di sebelah kirinya, lalu cari posisinya
    // pada teks yang sudah diformat.
    final end = newValue.selection.end;
    final rawCursor = (end < 0 || end > text.length) ? text.length : end;
    final left = (text.substring(0, rawCursor).replaceAll(RegExp(r'\D'), '').length - removedZeros)
        .clamp(0, digits.length)
        .toInt();
    var count = 0, idx = 0;
    while (idx < formatted.length && count < left) {
      if (formatted[idx] != '.') count++;
      idx++;
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: idx));
  }
}