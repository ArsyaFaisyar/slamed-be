import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';

/// Alasan RKH tidak boleh diubah; null bila boleh. Backend tidak membatasi
/// (PATCH tetap diterima), jadi aturan ini ditegakkan di app.
String? rkhLockReason({
  required Rkh rkh,
  required bool hasLkh,
  required String? role,
  required int? userId,
}) {
  if (role == Roles.sales && rkh.salesId != userId) return 'RKH ini milik sales lain.';
  if (hasLkh) return 'RKH ini sudah memiliki LKH sehingga terkunci dan tidak dapat diubah.';
  if (rkh.status.toUpperCase() == 'CLOSED') return 'RKH sudah berstatus selesai dan tidak dapat diubah.';
  return null;
}