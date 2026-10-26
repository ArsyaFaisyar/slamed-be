import 'package:flutter/material.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';

/// Bilah bawah mode ubah: Batal + Simpan.
class EditBar extends StatelessWidget {
  const EditBar({super.key, required this.busy, required this.onCancel, required this.onSave});
  final bool busy;
  final VoidCallback onCancel, onSave;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(onPressed: busy ? null : onCancel, child: const Text('Batal')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PrimaryButton(label: 'Simpan', icon: Icons.check_rounded, loading: busy, onPressed: onSave),
            ),
          ]),
        ),
      );
}