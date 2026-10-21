import 'package:flutter/material.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/empty_state.dart';

/// Penampung layar yang belum dibuat.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.note, this.icon = Icons.hourglass_empty_rounded});
  final String title;
  final String note;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      AppScaffold(title: title, body: EmptyState(icon: icon, title: 'Segera hadir', subtitle: note));
}