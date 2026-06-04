import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../services/avatar_image_editor.dart';
import 'app_toast.dart';

class AvatarEditorDialog extends StatefulWidget {
  const AvatarEditorDialog({
    super.key,
    required this.sourceBytes,
    required this.sourceFilename,
  });

  final Uint8List sourceBytes;
  final String sourceFilename;

  @override
  State<AvatarEditorDialog> createState() => _AvatarEditorDialogState();
}

class _AvatarEditorDialogState extends State<AvatarEditorDialog> {
  final _editorController = ImageEditorController();
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final result = _buildEditResult();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, context.l10n.avatarEditorUploadFailed);
      }
    }
  }

  AvatarEditResult _buildEditResult() {
    final editorState = _editorController.state;
    final cropRect = _editorController.getCropRect();
    final rawImageData = editorState?.rawImageData;
    if (editorState == null || cropRect == null || rawImageData == null) {
      throw StateError('Avatar editor is not ready');
    }

    final decoded = img.decodeImage(rawImageData);
    if (decoded == null) {
      throw StateError('Unable to decode avatar image');
    }

    final left = cropRect.left.round().clamp(0, decoded.width - 1);
    final top = cropRect.top.round().clamp(0, decoded.height - 1);
    final right = cropRect.right.round().clamp(left + 1, decoded.width);
    final bottom = cropRect.bottom.round().clamp(top + 1, decoded.height);
    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );

    return AvatarEditResult(
      bytes: Uint8List.fromList(img.encodeJpg(cropped, quality: 90)),
      filename: 'avatar.jpg',
      contentType: 'image/jpeg',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      title: Text(context.l10n.avatarEditorCropTitle),
      content: SizedBox(
        width: 420,
        child: AspectRatio(
          aspectRatio: 1,
          child: ExtendedImage.memory(
            widget.sourceBytes,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.editor,
            cacheRawData: true,
            initEditorConfigHandler: (_) {
              return EditorConfig(
                maxScale: 8.0,
                cropAspectRatio: 1.0,
                cropRectPadding: const EdgeInsets.all(20),
                hitTestSize: 20,
                initCropRectType: InitCropRectType.imageRect,
                controller: _editorController,
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('avatar-editor-cancel'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('avatar-editor-save'),
          onPressed: _isSaving ? null : _save,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}
