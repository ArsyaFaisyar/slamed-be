import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Placeholder berdenyut saat daftar dimuat.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.count,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => Container(
            height: 118,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
          ),
        ),
      );
}