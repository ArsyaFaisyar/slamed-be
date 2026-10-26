import 'package:flutter/widgets.dart';

enum MetricTone { info, success, warning, danger }

class RoleMetric {
  const RoleMetric(this.label, this.value, this.icon, {this.tone = MetricTone.info});
  final String label, value;
  final IconData icon;
  final MetricTone tone;
}

class RoleListItem {
  const RoleListItem(this.title, this.subtitle, {this.badge, this.tone = MetricTone.info});
  final String title, subtitle;
  final String? badge;
  final MetricTone tone;
}

class RoleSection {
  const RoleSection(this.title, this.items);
  final String title;
  final List<RoleListItem> items;
}

/// Isi Beranda untuk role non-lapangan.
class RoleDashboardData {
  const RoleDashboardData({
    required this.title,
    required this.subtitle,
    this.metrics = const [],
    this.sections = const [],
    this.isSample = true,
  });

  final String title, subtitle;
  final List<RoleMetric> metrics;
  final List<RoleSection> sections;

  /// True bila data contoh (belum berasal dari backend).
  final bool isSample;

  static const empty = RoleDashboardData(
    title: 'Ringkasan',
    subtitle: 'Ringkasan untuk peran ini belum tersedia.',
    isSample: false,
  );
}