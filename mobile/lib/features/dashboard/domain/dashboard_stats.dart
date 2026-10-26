import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';

enum DashboardPeriod { week, month, all }

/// Ringkasan LKH; hanya ada bila data LKH berhasil dimuat.
class LkhSummary {
  const LkhSummary({required this.count, required this.done});
  final int count, done;
  int get notYet => count - done;
}

/// Perhitungan target. Berdasar RKH; LKH opsional. Kelas murni agar mudah diuji.
class DashboardStats {
  const DashboardStats({
    required this.rkhTotal,
    required this.rkhDone,
    required this.overdue,
    required this.today,
    required this.doneIds,
    this.lkh,
  });

  final int rkhTotal, rkhDone;
  int get rkhOpen => rkhTotal - rkhDone;

  /// RKH yang tanggalnya sudah lewat dan belum selesai, terlama lebih dulu
  /// (tidak dibatasi periode).
  final List<Rkh> overdue;

  /// RKH yang jadwalnya hari ini.
  final List<Rkh> today;

  /// ID RKH yang dianggap selesai (status CLOSED atau sudah punya LKH).
  final Set<int> doneIds;

  /// Null bila LKH tidak dimuat.
  final LkhSummary? lkh;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isClosed(Rkh r) => r.status.toUpperCase() == 'CLOSED';

  /// Minggu dihitung Senin sampai Minggu.
  static bool inPeriod(DateTime d, DashboardPeriod p, DateTime now) {
    if (p == DashboardPeriod.all) return true;
    final t = _day(now);
    final DateTime start;
    final DateTime end;
    if (p == DashboardPeriod.week) {
      start = DateTime(t.year, t.month, t.day - (t.weekday - DateTime.monday));
      end = DateTime(start.year, start.month, start.day + 6);
    } else {
      start = DateTime(t.year, t.month, 1);
      end = DateTime(t.year, t.month + 1, 0);
    }
    final x = _day(d);
    return !x.isBefore(start) && !x.isAfter(end);
  }

  factory DashboardStats.compute({
    required List<Rkh> rkh,
    List<Lkh>? lkh,
    required DashboardPeriod period,
    required DateTime now,
  }) {
    final t = _day(now);
    final doneIds = <int>{
      for (final r in rkh)
        if (isClosed(r)) r.id,
      if (lkh != null)
        for (final l in lkh) l.rkhId,
    };
    final rkhIn = rkh.where((r) => inPeriod(r.tanggalPelaksanaan, period, now)).toList();

    LkhSummary? summary;
    if (lkh != null) {
      final lkhIn = lkh.where((l) => inPeriod(l.tanggalKunjungan, period, now)).toList();
      summary = LkhSummary(count: lkhIn.length, done: lkhIn.where((l) => l.isDone).length);
    }

    final overdue = rkh.where((r) => _day(r.tanggalPelaksanaan).isBefore(t) && !doneIds.contains(r.id)).toList()
      ..sort((a, b) => a.tanggalPelaksanaan.compareTo(b.tanggalPelaksanaan));

    return DashboardStats(
      rkhTotal: rkhIn.length,
      rkhDone: rkhIn.where((r) => doneIds.contains(r.id)).length,
      overdue: overdue,
      today: rkh.where((r) => _day(r.tanggalPelaksanaan) == t).toList(),
      doneIds: doneIds,
      lkh: summary,
    );
  }
}