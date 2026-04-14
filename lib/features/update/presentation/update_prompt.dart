import 'package:flutter/material.dart';
import 'package:flutter_cicd/features/update/domain/app_update_info.dart';

class UpdatePrompt extends StatelessWidget {
  const UpdatePrompt({
    super.key,
    required this.updateInfo,
    this.onConfirm,
    this.onCancel,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(updateInfo.title),
      content: Text(updateInfo.description),
      actions: [
        if (!updateInfo.mandatory)
          TextButton(
            onPressed: onCancel,
            child: const Text('稍后再说'),
          ),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
