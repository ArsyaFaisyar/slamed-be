import 'package:flutter/material.dart';
import 'package:slamed_app/core/utils/date_format.dart';

/// Kolom tanggal yang membuka date picker saat disentuh. Bungkus dengan Obx bila
/// [value] reaktif. Isi [onClear] agar tanggal opsional bisa dikosongkan.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.icon = Icons.event_outlined,
    this.placeholder = 'Belum diatur',
    this.helperText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;
  final String placeholder;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final d = value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          suffixIcon: (onClear != null && d != null)
              ? IconButton(
                  onPressed: onClear,
                  tooltip: 'Hapus tanggal',
                  icon: const Icon(Icons.close_rounded, size: 20),
                )
              : null,
        ),
        child: Text(d == null ? placeholder : formatDate(d)),
      ),
    );
  }
}