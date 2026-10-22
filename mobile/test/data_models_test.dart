import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/core/utils/jwt_utils.dart';
import 'package:slamed_app/features/auth/data/models/app_user.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh_create.dart';

String _fakeJwt(Map<String, dynamic> payload) {
  String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc(payload)}.sig';
}

void main() {
  // Contoh respons asli dari backend lokal.
  test('AppUser membaca respons login/profil', () {
    final u = AppUser.fromJson({
      'id': 1, 'nama': 'Super Admin Demo', 'username': 'superadmin',
      'email': 'superadmin@demo.com', 'role': 'SUPERADMIN', 'foto_profil': null,
    });
    expect(u.role, 'SUPERADMIN');
    expect(u.fotoProfil, isNull);
  });

  test('Rkh membaca respons backend (biaya berupa string, zona waktu +07:00)', () {
    final r = Rkh.fromJson({
      'id': 1, 'sales_id': 3, 'customer_id': 2, 'project_id': 1,
      'tanggal_rencana': '2026-10-20', 'tanggal_pelaksanaan': '2026-10-20',
      'judul_kegiatan': 'Presentasi produk', 'rencana_kegiatan': 'Kunjungan',
      'tipe_aktivitas': 'Kunjungan', 'estimasi_biaya_harian': '150000.00',
      'status': 'DRAFT', 'created_at': '2026-10-20T08:22:58.765070+07:00',
    });
    expect(r.status, 'DRAFT');
    expect(r.estimasiBiayaHarian, '150000.00');
  });

  test('Lkh menerima koordinat bilangan bulat', () {
    final l = Lkh.fromJson({
      'id': 1, 'rkh_id': 1, 'sales_id': 3, 'tanggal_kunjungan': '2026-10-20',
      'hasil_kunjungan': 'ok', 'status_prospek': 'DONE', 'latitude': 20, 'longitude': 21,
    });
    expect(l.latitude, 20.0);
    expect(l.longitude, 21.0);
  });

  test('RkhCreate memakai yyyy-MM-dd dan tanpa sales_id', () {
    final json = RkhCreate(
      customerId: 1, projectId: 1,
      tanggalRencana: DateTime(2026, 10, 20), tanggalPelaksanaan: DateTime(2026, 10, 21),
      judulKegiatan: 'a', rencanaKegiatan: 'b', tipeAktivitas: 'Kunjungan',
    ).toJson();
    expect(json['tanggal_pelaksanaan'], '2026-10-21');
    expect(json.containsKey('sales_id'), isFalse);
  });

  test('toApiDate dan formatDate', () {
    expect(toApiDate(DateTime(2026, 1, 5)), '2026-01-05');
    expect(formatDate(DateTime(2026, 1, 5)), '05/01/2026');
  });

  test('jwtExpired', () {
    expect(jwtExpired(_fakeJwt({'sub': '1', 'role': 'SALES', 'exp': 1})), isTrue);
    expect(jwtExpired(_fakeJwt({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})), isFalse);
    expect(jwtExpired('bukan-jwt'), isFalse);
  });
}