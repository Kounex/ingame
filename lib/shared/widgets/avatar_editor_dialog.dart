import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/utils/extensions.dart';
import '../services/avatar_image_editor.dart';
import 'app_toast.dart';

class AvatarEditorDialog extends StatefulWidget {
  const AvatarEditorDialog({
    super.key,
    required this.sourceBytes,
    required this.sourceFilename,
    this.onChangeSource,
    this.showRemove = false,
  });

  final Uint8List sourceBytes;
  final String sourceFilename;
  final AvatarSourceCallback? onChangeSource;
  final bool showRemove;

  @override
  State<AvatarEditorDialog> createState() => _AvatarEditorDialogState();
}

class _AvatarEditorDialogState extends State<AvatarEditorDialog> {
  ImageEditorController _editorController = ImageEditorController();
  bool _isSaving = false;
  late Uint8List _currentBytes;
  int _sourceVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.sourceBytes;
  }

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

  AvatarEditSave _buildEditResult() {
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

    return AvatarEditSave(
      bytes: Uint8List.fromList(img.encodeJpg(cropped, quality: 90)),
      filename: 'avatar.jpg',
      contentType: 'image/jpeg',
    );
  }

  Future<void> _handleChangeSource() async {
    final newBytes = await widget.onChangeSource?.call();
    if (newBytes == null || !mounted) return;
    setState(() {
      _currentBytes = newBytes;
      _sourceVersion++;
      _editorController = ImageEditorController();
    });
  }

  void _handleRemove() {
    Navigator.of(context).pop(const AvatarEditRemoval());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.avatarEditorCropTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ExtendedImage.memory(
                _currentBytes,
                key: ValueKey(_sourceVersion),
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
            if (widget.onChangeSource != null || widget.showRemove) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onChangeSource != null)
                    TextButton.icon(
                      onPressed: _isSaving ? null : _handleChangeSource,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(context.l10n.avatarEditorChangePhoto),
                    ),
                  if (widget.onChangeSource != null && widget.showRemove)
                    const SizedBox(width: 16),
                  if (widget.showRemove)
                    TextButton.icon(
                      onPressed: _isSaving ? null : _handleRemove,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(context.l10n.avatarEditorRemovePhoto),
                    ),
                ],
              ),
            ],
          ],
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
