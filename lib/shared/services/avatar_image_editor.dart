import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/avatar_editor_dialog.dart';

typedef AvatarSourceCallback = Future<Uint8List?> Function();

sealed class AvatarEditResult {
  const AvatarEditResult();
}

class AvatarEditSave extends AvatarEditResult {
  const AvatarEditSave({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

class AvatarEditRemoval extends AvatarEditResult {
  const AvatarEditRemoval();
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
