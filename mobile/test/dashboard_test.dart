import 'package:flutter_test/flutter_test.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/dashboard/data/dummy_role_dashboard.dart';

void main() {
  test('setiap role non-lapangan punya metrik dan daftar', () {
    for (final r in [Roles.superadmin, Roles.ppic, Roles.adminMarketing, Roles.adminKeuangan]) {
      final d = DummyRoleDashboard.forRole(r);
      expect(d.metrics, isNotEmpty, reason: r);
      expect(d.sections, isNotEmpty, reason: r);
      expect(d.isSample, isTrue, reason: r);
    }
  });

  test('role tak dikenal memakai tampilan kosong', () {
    final d = DummyRoleDashboard.forRole('LAINNYA');
    expect(d.metrics, isEmpty);
    expect(d.isSample, isFalse);
  });

  test('jumlah pengguna per role sama dengan total pengguna', () {
    final d = DummyRoleDashboard.forRole(Roles.superadmin);
    final total = int.parse(d.metrics.first.value);
    final sum = d.sections.first.items.fold<int>(0, (a, e) => a + int.parse(e.badge!));
    expect(sum, total);
  });

  test('pengguna aktif ditambah nonaktif sama dengan total', () {
    final m = DummyRoleDashboard.forRole(Roles.superadmin).metrics;
    expect(int.parse(m[1].value) + int.parse(m[2].value), int.parse(m[0].value));
  });
}