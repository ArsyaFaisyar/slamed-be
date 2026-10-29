import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/features/lkh/presentation/widgets/lkh_detail_view.dart';
import 'package:slamed_app/features/lkh/presentation/widgets/lkh_edit_view.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/edit_bar.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';

class LkhDetailPage extends GetView<LkhDetailController> {
  const LkhDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final editing = c.editing.value;
      final isDone = c.lkh.value.isDone;
      final working = c.busy.value || c.capturing.value;
      return AppScaffold(
        title: editing ? 'Ubah LKH' : 'Detail LKH',
        actions: [
          if (!editing && c.canEdit)
            IconButton(onPressed: working ? null : c.requestEdit, tooltip: 'Ubah', icon: const Icon(Icons.edit_outlined)),
        ],
        bottomBar: editing
            ? EditBar(busy: c.busy.value, onCancel: c.cancelEdit, onSave: c.save)
            : (isDone || !c.canEdit)
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: PrimaryButton(
                        label: c.hasFoto ? 'Tandai selesai' : 'Lengkapi foto',
                        icon: c.hasFoto ? Icons.check_circle_outline : Icons.photo_camera_outlined,
                        loading: working,
                        onPressed: c.hasFoto ? c.markDone : c.changePhoto,
                      ),
                    ),
                  ),
        body: editing ? LkhEditView(c: c) : LkhDetailView(c: c),
      );
    });
  }
}