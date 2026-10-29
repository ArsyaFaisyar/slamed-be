import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/presentation/controllers/prospect_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.p, required this.c});
  final Project p;
  final ProspectController c;

  @override
  Widget build(BuildContext context) {
    final color = c.statusColor(p);
    final label = c.statusOf(p);
    final nilai = formatRupiah(p.nilaiProyek);
    final closing = p.estimasiClosing;

    return AppCard(
      accent: color ?? AppColors.infoFg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(p.namaProject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 8),
          color == null ? StatusChip(label) : StatusChip(label, fg: color, bg: color.withValues(alpha: 0.16)),
        ]),
        const SizedBox(height: 10),
        MetaRow(Icons.business_outlined, c.customerName(p.customerId)),
        if (nilai != null) ...[
          const SizedBox(height: 4),
          MetaRow(Icons.payments_outlined, nilai),
        ],
        if (closing != null) ...[
          const SizedBox(height: 4),
          MetaRow(Icons.event_available_outlined, 'Estimasi closing ${formatDate(closing)}'),
        ],
        if ((p.deskripsi ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            p.deskripsi!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ]),
    );
  }
}