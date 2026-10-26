import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/features/profile/domain/profile_rules.dart';

Uint8List _bytes(List<int> head, {int length = 64}) {
  final b = Uint8List(length);
  b.setRange(0, head.length, head);
  return b;
}

final _jpeg = [0xFF, 0xD8, 0xFF, 0xE0];
final _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
List<int> get _webp => [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50];
List<int> get _heic => [0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63];

void main() {
  String? pw(String lama, String baru, String konf) =>
      validatePasswordChange(lama: lama, baru: baru, konfirmasi: konf);

  test('password valid', () => expect(pw('lama123', 'baru456', 'baru456'), isNull));
  test('kolom kosong', () => expect(pw('', 'baru456', 'baru456'), 'Lengkapi semua kolom.'));
  test('terlalu pendek', () => expect(pw('lama123', 'abc12', 'abc12'), contains('minimal 6')));
  test('tepat 6 karakter lolos', () => expect(pw('lama123', 'abc123', 'abc123'), isNull));
  test('konfirmasi berbeda', () => expect(pw('lama123', 'baru456', 'baru457'), contains('tidak sama')));
  test('sama dengan password lama', () => expect(pw('sama123', 'sama123', 'sama123'), contains('berbeda')));

  test('format dideteksi dari isi file', () {
    expect(sniffImage(_bytes(_jpeg)), ImageKind.jpeg);
    expect(sniffImage(_bytes(_png)), ImageKind.png);
    expect(sniffImage(_bytes(_webp)), ImageKind.webp);
    expect(sniffImage(_bytes([0x47, 0x49, 0x46, 0x38])), isNull); // GIF
    expect(sniffImage(const <int>[]), isNull);
  });

  test('tipe konten dan ekstensi', () {
    expect(ImageKind.jpeg.mime, 'image/jpeg');
    expect(ImageKind.jpeg.ext, 'jpg');
    expect(ImageKind.png.mime, 'image/png');
    expect(ImageKind.webp.ext, 'webp');
  });

  test('foto valid', () {
    expect(validateProfilePhoto(_bytes(_jpeg)), isNull);
    expect(validateProfilePhoto(_bytes(_png)), isNull);
    expect(validateProfilePhoto(_bytes(_webp)), isNull);
  });

  test('foto kosong, GIF, dan HEIC ditolak dengan pesan berbeda', () {
    expect(validateProfilePhoto(const <int>[]), contains('kosong'));
    expect(validateProfilePhoto(_bytes([0x47, 0x49, 0x46, 0x38])), contains('JPG'));
    expect(validateProfilePhoto(_bytes(_heic)), contains('HEIC'));
  });

  test('batas 5 MB', () {
    const max = 5 * 1024 * 1024;
    expect(validateProfilePhoto(_bytes(_jpeg, length: max)), isNull);
    expect(validateProfilePhoto(_bytes(_jpeg, length: max + 1)), contains('5 MB'));
  });
}