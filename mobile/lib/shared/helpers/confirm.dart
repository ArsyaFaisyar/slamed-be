import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog konfirmasi Batal/[confirmLabel]. Mengembalikan true jika dikonfirmasi.
Future<bool> confirmDialog({
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final r = await Get.dialog(
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
        TextButton(onPressed: () => Get.back(result: true), child: Text(confirmLabel)),
      ],
    ),
  );
  return r == true;
}