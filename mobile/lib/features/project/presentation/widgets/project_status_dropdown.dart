import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';
import 'package:slamed_app/features/project/presentation/widgets/project_status_label.dart';

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