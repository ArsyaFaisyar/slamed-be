import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';

enum LkhEditState {
  /// Status Belum: boleh diubah dan boleh ditandai DONE.
  editable,

  /// Status DONE: kembalikan ke Belum dulu sebelum diubah.
  needsRevert,

  /// Milik sales lain.
  notOwner,
}

LkhEditState lkhEditState({required Lkh lkh, required String? role, required int? userId}) {
  if (role == Roles.sales && lkh.salesId != userId) return LkhEditState.notOwner;
  return lkh.isDone ? LkhEditState.needsRevert : LkhEditState.editable;
}