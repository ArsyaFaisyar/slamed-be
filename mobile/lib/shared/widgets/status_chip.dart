import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.fg = AppColors.infoFg, this.bg = AppColors.infoBg});
  const StatusChip.success(this.label, {super.key})
      : fg = AppColors.successFg,
        bg = AppColors.successBg;
  const StatusChip.warning(this.label, {super.key})
      : fg = AppColors.warningFg,
        bg = AppColors.warningBg;
  const StatusChip.danger(this.label, {super.key})
      : fg = AppColors.dangerFg,
        bg = AppColors.dangerBg;

  /// Chip untuk status prospek: DONE hijau, LOSE merah, lainnya biru.
  static StatusChip forProspect(String s) {
    switch (s.toUpperCase()) {
      case 'DONE':
        return StatusChip.success(s);
      case 'LOSE':
        return StatusChip.danger(s);
      default:
        return StatusChip(s);
    }
  }

  final String label;
  final Color fg, bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

/// Warna aksen kartu menurut status prospek.
Color prospectAccent(String? s) {
  switch (s?.toUpperCase()) {
    case 'DONE':
      return AppColors.successFg;
    case 'LOSE':
      return AppColors.dangerFg;
    default:
      return AppColors.infoFg;
  }
}