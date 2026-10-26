import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/domain/lkh_edit_rules.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/domain/rkh_edit_rules.dart';

Rkh _rkh({String status = 'OPEN', int salesId = 3}) => Rkh.fromJson({
      'id': 1, 'sales_id': salesId, 'customer_id': 2, 'project_id': 1,
      'tanggal_rencana': '2026-10-20', 'tanggal_pelaksanaan': '2026-10-20',
      'judul_kegiatan': 'k', 'rencana_kegiatan': 'r', 'tipe_aktivitas': 'Kunjungan',
      'estimasi_biaya_harian': '0.00', 'status': status,
    });

Lkh _lkh({String status = 'NOT_YET', int salesId = 3}) => Lkh.fromJson({
      'id': 1, 'rkh_id': 1, 'sales_id': salesId, 'tanggal_kunjungan': '2026-10-20',
      'hasil_kunjungan': 'ok', 'nama_pic': 'Budi', 'nomor_pic': '0812', 'status_lkh': status,
    });

void main() {
  String? lock(Rkh r, {bool hasLkh = false, String? role = Roles.sales, int? userId = 3}) =>
      rkhLockReason(rkh: r, hasLkh: hasLkh, role: role, userId: userId);

  group('kunci RKH', () {
    test('belum ada LKH dan masih terbuka: boleh diubah', () {
      expect(lock(_rkh()), isNull);
      expect(lock(_rkh(status: 'DRAFT')), isNull); // data lama
    });

    test('sudah ada LKH: terkunci', () {
      expect(lock(_rkh(), hasLkh: true), contains('LKH'));
    });

    test('berstatus CLOSED tanpa LKH terdeteksi: terkunci', () {
      expect(lock(_rkh(status: 'CLOSED')), contains('selesai'));
      expect(lock(_rkh(status: 'closed')), contains('selesai'));
    });

    test('LKH lebih diutamakan daripada status', () {
      expect(lock(_rkh(status: 'CLOSED'), hasLkh: true), contains('memiliki LKH'));
    });

    test('sales tidak boleh mengubah RKH sales lain', () {
      expect(lock(_rkh(salesId: 9)), contains('sales lain'));
    });

    test('peran lain tidak dibatasi kepemilikan di sisi app', () {
      expect(lock(_rkh(salesId: 9), role: Roles.spv, userId: 2), isNull);
    });
  });

  group('status ubah LKH', () {
    LkhEditState state(Lkh l, {String? role = Roles.sales, int? userId = 3}) =>
        lkhEditState(lkh: l, role: role, userId: userId);

    test('status Belum: boleh diubah', () {
      expect(state(_lkh()), LkhEditState.editable);
    });

    test('status DONE: harus dikembalikan ke Belum dulu', () {
      expect(state(_lkh(status: 'DONE')), LkhEditState.needsRevert);
      expect(state(_lkh(status: 'done')), LkhEditState.needsRevert);
    });

    test('sales tidak boleh mengubah LKH sales lain, apa pun statusnya', () {
      expect(state(_lkh(salesId: 9)), LkhEditState.notOwner);
      expect(state(_lkh(salesId: 9, status: 'DONE')), LkhEditState.notOwner);
    });

    test('peran lain mengikuti status', () {
      expect(state(_lkh(salesId: 9), role: Roles.spv, userId: 2), LkhEditState.editable);
      expect(state(_lkh(salesId: 9, status: 'DONE'), role: Roles.spv, userId: 2), LkhEditState.needsRevert);
    });
  });
}