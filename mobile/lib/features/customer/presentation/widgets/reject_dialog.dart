import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog alasan penolakan. Mengembalikan teks alasan, atau null jika dibatalkan.
Future<String?> askRejectionReason(String namaInstansi) async {
  final r = await Get.dialog(_RejectDialog(namaInstansi));
  return r is String ? r : null;
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog(this.nama);
  final String nama;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) {
      setState(() => _error = 'Alasan penolakan wajib diisi.');
      return;
    }
    Get.back(result: t);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Tolak pengajuan?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('"${widget.nama}"', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(labelText: 'Alasan penolakan', errorText: _error, counterText: ''),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          TextButton(onPressed: _submit, child: const Text('Tolak')),
        ],
      );
}