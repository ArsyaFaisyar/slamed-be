import 'package:flutter/material.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/dashboard/domain/role_dashboard_data.dart';

/// Data contoh per role. Ganti dengan pemanggilan repository saat endpoint tersedia.
abstract final class DummyRoleDashboard {
  static RoleDashboardData forRole(String? role) => switch (role) {
        Roles.superadmin => _superadmin,
        Roles.ppic => _ppic,
        Roles.adminMarketing => _adminMarketing,
        Roles.adminKeuangan => _adminKeuangan,
        _ => RoleDashboardData.empty,
      };

  static const _superadmin = RoleDashboardData(
    title: 'Ringkasan Sistem',
    subtitle: 'Pengelolaan pengguna dan data master',
    metrics: [
      RoleMetric('Total pengguna', '24', Icons.groups_outlined),
      RoleMetric('Pengguna aktif', '22', Icons.verified_user_outlined, tone: MetricTone.success),
      RoleMetric('Nonaktif', '2', Icons.person_off_outlined, tone: MetricTone.warning),
      RoleMetric('Login hari ini', '11', Icons.login_rounded),
    ],
    sections: [
      RoleSection('Pengguna per role', [
        RoleListItem('Sales', 'Tim penjualan lapangan', badge: '12'),
        RoleListItem('SPV', 'Supervisor marketing', badge: '3'),
        RoleListItem('PPIC', 'Pengadaan dan harga', badge: '2'),
        RoleListItem('Admin Marketing', 'Dokumen dan pengiriman', badge: '3'),
        RoleListItem('Admin Keuangan', 'Biaya, pajak, cashback', badge: '2'),
        RoleListItem('Superadmin', 'Administrator sistem', badge: '2'),
      ]),
      RoleSection('Aktivitas terbaru', [
        RoleListItem('Akun baru dibuat', 'sales07 · Sales · Hari ini 09.12'),
        RoleListItem('Reset password', 'ppic01 · Hari ini 08.40', badge: 'Reset', tone: MetricTone.warning),
        RoleListItem('Role diubah', 'marketing02 · Kemarin 16.05'),
      ]),
    ],
  );

  static const _ppic = RoleDashboardData(
    title: 'Antrean PPIC',
    subtitle: 'Permintaan RAB dan penetapan harga dari Sales',
    metrics: [
      RoleMetric('Permintaan baru', '6', Icons.inbox_outlined, tone: MetricTone.warning),
      RoleMetric('Diproses', '4', Icons.sync_rounded),
      RoleMetric('Selesai bulan ini', '18', Icons.task_alt_rounded, tone: MetricTone.success),
      RoleMetric('Melewati SLA', '2', Icons.timer_off_outlined, tone: MetricTone.danger),
    ],
    sections: [
      RoleSection('Permintaan terbaru', [
        RoleListItem('RAB Perangkat Jaringan LAN', 'PT Maju Jaya Abadi · Sales Demo', badge: 'Baru', tone: MetricTone.warning),
        RoleListItem('Setting harga Router Edge', 'Dinas Kominfo Jawa Barat · Sales Demo', badge: 'Diproses'),
        RoleListItem('RAB Modernisasi Data Center', 'Bank Pembangunan Daerah Jateng', badge: 'Melewati SLA', tone: MetricTone.danger),
      ]),
    ],
  );

  static const _adminMarketing = RoleDashboardData(
    title: 'Administrasi Marketing',
    subtitle: 'Dokumen, pengiriman, dan laporan SLA',
    metrics: [
      RoleMetric('Dokumen masuk', '9', Icons.move_to_inbox_outlined),
      RoleMetric('Menunggu kirim', '3', Icons.outgoing_mail, tone: MetricTone.warning),
      RoleMetric('Terkirim bulan ini', '27', Icons.mark_email_read_outlined, tone: MetricTone.success),
      RoleMetric('SLA tepat waktu', '92%', Icons.speed_rounded, tone: MetricTone.success),
    ],
    sections: [
      RoleSection('Perlu ditindaklanjuti', [
        RoleListItem('Kirim penawaran revisi R-1', 'PT Maju Jaya Abadi', badge: 'Hari ini', tone: MetricTone.warning),
        RoleListItem('Verifikasi dokumen cashback', 'PT Telco Solusindo Perkasa', badge: 'Menunggu', tone: MetricTone.warning),
        RoleListItem('Terima SPK', 'Politeknik Negeri Elektronika', badge: 'Baru'),
      ]),
    ],
  );

  static const _adminKeuangan = RoleDashboardData(
    title: 'Administrasi Keuangan',
    subtitle: 'Pengajuan biaya, pajak, dan cashback',
    metrics: [
      RoleMetric('Pengajuan biaya', '8', Icons.receipt_long_outlined, tone: MetricTone.warning),
      RoleMetric('Permintaan pajak', '3', Icons.request_quote_outlined),
      RoleMetric('Cashback diproses', '5', Icons.savings_outlined),
      RoleMetric('Disetujui bulan ini', '21', Icons.check_circle_outline, tone: MetricTone.success),
    ],
    sections: [
      RoleSection('Menunggu persetujuan', [
        RoleListItem('Biaya kunjungan harian', 'Sales Demo · Rp 150.000', badge: 'Menunggu', tone: MetricTone.warning),
        RoleListItem('Permintaan faktur pajak', 'PT Astra Multifinance Tbk', badge: 'Baru'),
        RoleListItem('Cashback proyek CCTV', 'PT Pelabuhan Nusantara III', badge: 'Diproses'),
      ]),
    ],
  );
}