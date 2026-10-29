import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/project/domain/status_color.dart';
import 'package:slamed_app/shared/widgets/status_dot.dart';

/// Warna status project dari backend; warna utama app bila kosong atau tidak dikenali.
Color projectStatusColor(String? warna) => statusColor(warna) ?? AppColors.primary;

/// Titik warna + nama status.
class ProjectStatusLabel extends StatelessWidget {
  const ProjectStatusLabel({super.key, required this.nama, this.warna, this.style, this.maxLines});
  final String nama;
  final String? warna;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Row(children: [
        StatusDot(color: projectStatusColor(warna)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            nama,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ]);
}