import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/avatar_editor_dialog.dart';

class AvatarEditResult {
  const AvatarEditResult({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

abstract class AvatarImageEditor {
  Future<AvatarEditResult?> editSquareAvatar(
    BuildContext context, {
    required Uint8List sourceBytes,
    required String sourceFilename,
  });
}

class DialogAvatarImageEditor implements AvatarImageEditor {
  const DialogAvatarImageEditor();

  @override
  Future<AvatarEditResult?> editSquareAvatar(
    BuildContext context, {
    required Uint8List sourceBytes,
    required String sourceFilename,
  }) {
    return showDialog<AvatarEditResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AvatarEditorDialog(
        sourceBytes: sourceBytes,
        sourceFilename: sourceFilename,
      ),
    );
  }
}

final avatarImageEditorProvider = Provider<AvatarImageEditor>((ref) {
  return const DialogAvatarImageEditor();
});
