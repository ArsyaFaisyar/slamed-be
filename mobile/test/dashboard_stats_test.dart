import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/features/dashboard/domain/dashboard_stats.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';

Rkh _rkh(int id, String date, {String status = 'OPEN'}) => Rkh.fromJson({
      'id': id, 'sales_id': 3, 'customer_id': 2, 'project_id': 1,
      'tanggal_rencana': date, 'tanggal_pelaksanaan': date,
      'judul_kegiatan': 'k$id', 'rencana_kegiatan': 'r', 'tipe_aktivitas': 'Kunjungan',
      'estimasi_biaya_harian': '0.00', 'status': status,
    });

Lkh _lkh(int id, int rkhId, String date, {String status = 'NOT_YET'}) => Lkh.fromJson({
      'id': id, 'rkh_id': rkhId, 'sales_id': 3, 'tanggal_kunjungan': date,
      'hasil_kunjungan': 'ok', 'nama_pic': 'Budi', 'nomor_pic': '0812', 'status_lkh': status,
    });

void main() {
  // Rabu, 21 Oktober 2026. Minggu ini = Senin 19 s.d. Minggu 25 Oktober.
  final now = DateTime(2026, 10, 21);
  final rkh = [
    _rkh(1, '2026-10-20', status: 'CLOSED'), // minggu ini, selesai
    _rkh(2, '2026-10-19'), // minggu ini, terlewat
    _rkh(3, '2026-10-26'), // di luar minggu ini, masih bulan ini
    _rkh(4, '2026-10-21'), // hari ini
    _rkh(5, '2026-09-30'), // bulan lalu, terlewat
  ];

  DashboardStats stats(DashboardPeriod p, {List<Lkh>? lkh}) =>
      DashboardStats.compute(rkh: rkh, lkh: lkh, period: p, now: now);

  test('periode minggu ini tanpa LKH', () {
    final s = stats(DashboardPeriod.week);
    expect(s.rkhTotal, 3);
    expect(s.rkhDone, 1);
    expect(s.rkhOpen, 2);
    expect(s.lkh, isNull);
  });

  test('periode bulan ini dan semua', () {
    expect(stats(DashboardPeriod.month).rkhTotal, 4);
    expect(stats(DashboardPeriod.all).rkhTotal, 5);
  });

  test('terlewat: belum selesai, tidak dibatasi periode, terlama lebih dulu', () {
    expect(stats(DashboardPeriod.week).overdue.map((e) => e.id).toList(), [5, 2]);
  });

  test('agenda hari ini', () {
    expect(stats(DashboardPeriod.week).today.map((e) => e.id).toList(), [4]);
  });

  test('status CLOSED tidak peka huruf besar-kecil', () {
    final s = DashboardStats.compute(
      rkh: [_rkh(1, '2026-10-20', status: 'closed')],
      period: DashboardPeriod.week,
      now: now,
    );
    expect(s.rkhDone, 1);
  });

  test('LKH opsional: RKH yang punya LKH ikut dihitung selesai', () {
    final s = stats(DashboardPeriod.week, lkh: [_lkh(10, 2, '2026-10-20')]);
    expect(s.rkhDone, 2);
    expect(s.overdue.map((e) => e.id).toList(), [5]);
    expect(s.lkh!.count, 1);
  });

  test('DONE dan Belum DONE dihitung dari status_lkh', () {
    final s = stats(DashboardPeriod.week, lkh: [
      _lkh(10, 1, '2026-10-20', status: 'DONE'),
      _lkh(11, 2, '2026-10-19'),
      _lkh(12, 4, '2026-10-21', status: 'done'),
    ]);
    expect(s.lkh!.count, 3);
    expect(s.lkh!.done, 2);
    expect(s.lkh!.notYet, 1);
  });
}