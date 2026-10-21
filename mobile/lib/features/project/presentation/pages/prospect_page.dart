import 'package:flutter/material.dart';
import 'package:slamed_app/shared/widgets/coming_soon.dart';

class ProspectPage extends StatelessWidget {
  const ProspectPage({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoon(
        title: 'Prospek',
        note: 'Daftar project per status akan tampil di sini.',
        icon: Icons.trending_up_rounded,
      );
}