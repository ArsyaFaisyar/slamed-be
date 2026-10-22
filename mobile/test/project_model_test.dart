import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/features/project/data/models/project.dart';

void main() {
  // Contoh respons asli dari backend lokal.
  test('Project membaca respons backend', () {
    final p = Project.fromJson({
      'id': 1,
      'customer_id': 2,
      'nama_project': 'Pengadaan Perangkat Jaringan LAN & Server',
      'jenis': 'PROSPEK',
      'deskripsi': 'Prospek awal dari kunjungan pertama',
      'status': 'BARU',
      'created_at': '2026-10-20T08:16:46.236529+07:00',
    });
    expect(p.status, 'BARU');
    expect(p.jenis, 'PROSPEK');
    expect(p.customerId, 2);
  });

  test('Project menerima deskripsi kosong', () {
    final p = Project.fromJson({
      'id': 2, 'customer_id': 2, 'nama_project': 'x', 'jenis': 'PROSPEK', 'status': 'BARU', 'deskripsi': null,
    });
    expect(p.deskripsi, isNull);
  });
} 