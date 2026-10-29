import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';
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

/// Dropdown status project. [statuses] sudah disaring aturan "tidak boleh mundur"
/// (lihat allowedStatusTargets).
class ProjectStatusDropdown extends StatelessWidget {
  const ProjectStatusDropdown({
    super.key,
    required this.statuses,
    required this.value,
    required this.onChanged,
    this.helperText = 'Status tidak dapat dimundurkan ke tahap sebelumnya.',
  });

  final List<ProjectStatus> statuses;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String helperText;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        decoration: InputDecoration(
          labelText: 'Status project',
          prefixIcon: const Icon(Icons.flag_outlined),
          helperText: helperText,
          helperMaxLines: 2,
        ),
        items: [
          for (final s in statuses)
            DropdownMenuItem(
              value: s.id,
              child: ProjectStatusLabel(nama: s.nama, warna: s.warna, maxLines: 1),
            ),
        ],
        onChanged: onChanged,
      );
}