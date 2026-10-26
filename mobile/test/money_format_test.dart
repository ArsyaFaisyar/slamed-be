import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/core/utils/money_format.dart';

void main() {
  test('format rupiah', () {
    expect(formatRupiah('150000.00'), 'Rp 150.000');
    expect(formatRupiah('0'), 'Rp 0');
    expect(formatRupiah('1234567'), 'Rp 1.234.567');
    expect(formatRupiah('abc'), 'Rp 0');
  });
}