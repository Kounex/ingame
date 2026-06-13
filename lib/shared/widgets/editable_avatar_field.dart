import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:mime/mime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../services/avatar_image_editor.dart';
import '../services/avatar_image_picker.dart';
import '../services/avatar_source_loader.dart';
import '../services/avatar_upload_service.dart';
import 'app_toast.dart';
import 'tappable.dart';
import 'user_avatar.dart';

enum _AvatarAction { photoLibrary, uploadPhoto, takePhoto, useUrl, remove }

class EditableAvatarField extends ConsumerStatefulWidget {
  const EditableAvatarField({
    super.key,
    this.initialAvatarUrl,
    required this.displayName,
    required this.onChanged,
    this.size = 100,
  });

  final String? initialAvatarUrl;
  final String displayName;
  final ValueChanged<String?> onChanged;
  final double size;

  @override
  ConsumerState<EditableAvatarField> createState() =>
      _EditableAvatarFieldState();
}

class _EditableAvatarFieldState extends ConsumerState<EditableAvatarField> {
  Uint8List? _previewBytes;
  String? _avatarUrl;
  bool _isUploading = false;
  double? _uploadProgress;
  bool _hasLocalEdits = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.initialAvatarUrl;
  }

  @override
  void didUpdateWidget(covariant EditableAvatarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasLocalEdits) return;
    if (oldWidget.initialAvatarUrl != widget.initialAvatarUrl) {
      _avatarUrl = widget.initialAvatarUrl;
      _previewBytes = null;
    }
  }

  bool get _hasAvatar =>
      _previewBytes != null || (_avatarUrl?.isNotEmpty ?? false);

  Future<void> _openSourceChooser() async {
    final action = context.isMobile
        ? await showModalBottomSheet<_AvatarAction>(
            context: context,
            useRootNavigator: true,
            backgroundColor: AppColors.backgroundLight,
            builder: (_) =>
                SafeArea(child: Wrap(children: _buildActionTiles())),
          )
        : await showDialog<_AvatarAction>(
            context: context,
            useRootNavigator: true,
            builder: (_) => AlertDialog(
              title: Text(context.l10n.avatarEditorActionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildActionTiles(),
              ),
            ),
          );

    if (action == null || !mounted) return;

    switch (action) {
      case _AvatarAction.photoLibrary:
        await _pickFromLibrary();
        break;
      case _AvatarAction.uploadPhoto:
        await _pickUploadedFile();
        break;
      case _AvatarAction.takePhoto:
        await _takePhoto();
        break;
      case _AvatarAction.useUrl:
        await _showUrlDialog();
        break;
      case _AvatarAction.remove:
        _removeAvatar();
        break;
    }
  }

  List<Widget> _buildActionTiles({bool includeRemove = true}) {
    final tiles = <Widget>[
      if (!kIsWeb && _isMobilePlatform)
        _actionTile(
          key: const Key('editable-avatar-action-library'),
          icon: Icons.photo_library_outlined,
          label: context.l10n.avatarEditorPhotoLibrary,
          action: _AvatarAction.photoLibrary,
        ),
      _actionTile(
        key: const Key('editable-avatar-action-upload'),
        icon: Icons.upload_file_outlined,
        label: context.l10n.avatarEditorUploadPhoto,
        action: _AvatarAction.uploadPhoto,
      ),
      if (!kIsWeb && _isMobilePlatform)
        _actionTile(
          key: const Key('editable-avatar-action-camera'),
          icon: Icons.photo_camera_outlined,
          label: context.l10n.avatarEditorTakePhoto,
          action: _AvatarAction.takePhoto,
        ),
      _actionTile(
        key: const Key('editable-avatar-action-url'),
        icon: Icons.link_outlined,
        label: context.l10n.avatarEditorUseUrl,
        action: _AvatarAction.useUrl,
      ),
      if (includeRemove && _hasAvatar)
        _actionTile(
          key: const Key('editable-avatar-action-remove'),
          icon: Icons.delete_outline,
          label: context.l10n.avatarEditorRemovePhoto,
          action: _AvatarAction.remove,
        ),
    ];

    return tiles;
  }

  bool get _isMobilePlatform {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  Widget _actionTile({
    required Key key,
    required IconData icon,
    required String label,
    required _AvatarAction action,
  }) {
    return Builder(
      builder: (tileContext) => ListTile(
        key: key,
        leading: Icon(icon, color: AppColors.textPrimary),
        title:
            Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        onTap: () => Navigator.of(tileContext).pop(action),
      ),
    );
  }

  Future<void> _pickFromLibrary() async {
    final picker = ref.read(avatarImagePickerProvider);
    final file = await picker.pickFromLibrary();
    if (file == null || !mounted) return;
    await _editAndUploadSourceFile(file);
  }

  Future<void> _pickUploadedFile() async {
    final picker = ref.read(avatarImagePickerProvider);
    final file = await picker.pickUploadFile();
    if (file == null || !mounted) return;
    await _editAndUploadSourceFile(file);
  }

  Future<void> _takePhoto() async {
    final picker = ref.read(avatarImagePickerProvider);
    final file = await picker.pickFromCamera();
    if (file == null || !mounted) return;
    await _editAndUploadSourceFile(file);
  }

  Future<void> _editAndUploadSourceFile(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final originalMime =
        lookupMimeType(file.name, headerBytes: originalBytes) ?? '';
    if (!const {
      'image/jpeg',
      'image/png',
      'image/webp',
    }.contains(originalMime)) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.avatarEditorInvalidFileType);
      return;
    }

    final sourceLoader = ref.read(avatarSourceLoaderProvider);
    final normalizedFile = sourceLoader.fromBytes(
      originalBytes,
      filename: file.name.isEmpty ? 'avatar-upload' : file.name,
      contentType: originalMime,
    );
    if (!mounted) return;
    final editor = ref.read(avatarImageEditorProvider);
    final result = await editor.editSquareAvatar(
      context,
      sourceBytes: originalBytes,
      sourceFilename: normalizedFile.name,
      onChangeSource: _acquireNewSourceBytes,
    );
    if (!mounted) return;

    switch (result) {
      case AvatarEditSave(:final bytes, :final filename, :final contentType):
        await _uploadBytes(bytes, filename: filename, contentType: contentType);
      case AvatarEditRemoval():
        _removeAvatar();
      case null:
        break;
    }
  }

  Future<void> _editCurrentAvatar() async {
    XFile? sourceFile;
    final sourceLoader = ref.read(avatarSourceLoaderProvider);

    if (_previewBytes != null) {
      sourceFile = sourceLoader.fromBytes(
        _previewBytes!,
        filename: 'current-avatar.jpg',
        contentType:
            lookupMimeType('current-avatar.jpg', headerBytes: _previewBytes!) ??
            'image/jpeg',
      );
    } else if (_avatarUrl?.isNotEmpty == true) {
      try {
        sourceFile = await sourceLoader.loadRemoteImage(
          _avatarUrl!,
          suggestedFilename: 'current-avatar',
        );
      } catch (_) {
        if (!mounted) return;
        AppToast.error(context, context.l10n.avatarEditorUploadFailed);
        return;
      }
    }

    if (sourceFile == null || !mounted) return;

    final originalBytes = await sourceFile.readAsBytes();
    final originalMime =
        lookupMimeType(sourceFile.name, headerBytes: originalBytes) ?? '';
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(originalMime)) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.avatarEditorInvalidFileType);
      return;
    }

    if (!mounted) return;
    final editor = ref.read(avatarImageEditorProvider);
    final result = await editor.editSquareAvatar(
      context,
      sourceBytes: originalBytes,
      sourceFilename: sourceFile.name.isEmpty ? 'current-avatar' : sourceFile.name,
      onChangeSource: _acquireNewSourceBytes,
      showRemove: true,
    );
    if (!mounted) return;

    switch (result) {
      case AvatarEditSave(:final bytes, :final filename, :final contentType):
        await _uploadBytes(bytes, filename: filename, contentType: contentType);
      case AvatarEditRemoval():
        _removeAvatar();
      case null:
        break;
    }
  }

  Future<void> _uploadBytes(
    Uint8List bytes, {
    required String filename,
    required String contentType,
  }) async {
    final service = ref.read(avatarUploadServiceProvider);
    final previousAvatarUrl = _avatarUrl;
    final previousPreviewBytes = _previewBytes;

    setState(() {
      _previewBytes = bytes;
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final target = await service.prepareUpload(
        filename: filename,
        contentType: contentType,
        byteSize: bytes.length,
      );

      await service.uploadBinary(
        target: target,
        bytes: bytes,
        filename: filename,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _uploadProgress = sent / total);
        },
      );

      if (!mounted) return;
      setState(() {
        _avatarUrl = target.avatarUrl;
        _previewBytes = bytes;
        _isUploading = false;
        _uploadProgress = null;
        _hasLocalEdits = true;
      });
      widget.onChanged(target.avatarUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarUrl = previousAvatarUrl;
        _previewBytes = previousPreviewBytes;
        _isUploading = false;
        _uploadProgress = null;
      });
      AppToast.error(context, context.l10n.avatarEditorUploadFailed);
    }
  }

  Future<String?> _showUrlInputDialog() async {
    final controller = TextEditingController(text: _avatarUrl ?? '');
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.avatarEditorUseUrlTitle),
          content: TextField(
            key: const Key('editable-avatar-url-input'),
            controller: controller,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.avatarEditorUrlLabel,
              hintText: context.l10n.avatarEditorUrlHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              key: const Key('editable-avatar-url-save'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUrlDialog() async {
    final url = await _showUrlInputDialog();
    if (!mounted || url == null) return;

    if (url.isEmpty) {
      _removeAvatar();
      return;
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      AppToast.error(context, context.l10n.avatarEditorInvalidUrl);
      return;
    }

    try {
      final sourceLoader = ref.read(avatarSourceLoaderProvider);
      final sourceFile = await sourceLoader.loadRemoteImage(
        url,
        suggestedFilename: parsed.pathSegments.isNotEmpty
            ? parsed.pathSegments.last
            : 'avatar-url',
      );
      if (!mounted) return;
      await _editAndUploadSourceFile(sourceFile);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.avatarEditorUploadFailed);
    }
  }

  Future<Uint8List?> _acquireNewSourceBytes() async {
    final action = context.isMobile
        ? await showModalBottomSheet<_AvatarAction>(
            context: context,
            useRootNavigator: true,
            backgroundColor: AppColors.backgroundLight,
            builder: (_) => SafeArea(
              child: Wrap(children: _buildActionTiles(includeRemove: false)),
            ),
          )
        : await showDialog<_AvatarAction>(
            context: context,
            useRootNavigator: true,
            builder: (_) => AlertDialog(
              title: Text(context.l10n.avatarEditorActionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildActionTiles(includeRemove: false),
              ),
            ),
          );

    if (action == null || !mounted) return null;

    XFile? file;
    switch (action) {
      case _AvatarAction.photoLibrary:
        file = await ref.read(avatarImagePickerProvider).pickFromLibrary();
      case _AvatarAction.uploadPhoto:
        file = await ref.read(avatarImagePickerProvider).pickUploadFile();
      case _AvatarAction.takePhoto:
        file = await ref.read(avatarImagePickerProvider).pickFromCamera();
      case _AvatarAction.useUrl:
        final url = await _showUrlInputDialog();
        if (!mounted || url == null || url.isEmpty) return null;
        final parsed = Uri.tryParse(url);
        if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
          AppToast.error(context, context.l10n.avatarEditorInvalidUrl);
          return null;
        }
        try {
          final sourceLoader = ref.read(avatarSourceLoaderProvider);
          file = await sourceLoader.loadRemoteImage(
            url,
            suggestedFilename: parsed.pathSegments.isNotEmpty
                ? parsed.pathSegments.last
                : 'avatar-url',
          );
        } catch (_) {
          if (!mounted) return null;
          AppToast.error(context, context.l10n.avatarEditorUploadFailed);
          return null;
        }
      case _AvatarAction.remove:
        return null;
    }

    if (file == null || !mounted) return null;

    final bytes = await file.readAsBytes();
    final mime = lookupMimeType(file.name, headerBytes: bytes) ?? '';
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
      if (mounted) {
        AppToast.error(context, context.l10n.avatarEditorInvalidFileType);
      }
      return null;
    }
    return bytes;
  }

  void _removeAvatar() {
    setState(() {
      _avatarUrl = null;
      _previewBytes = null;
      _hasLocalEdits = true;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _uploadProgress == null
        ? null
        : (_uploadProgress! * 100).clamp(0, 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tappable(
          key: const Key('editable-avatar-field-trigger'),
          onTap: _isUploading
              ? null
              : (_hasAvatar ? _editCurrentAvatar : _openSourceChooser),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                imageUrl: _avatarUrl,
                imageBytes: _previewBytes,
                displayName: widget.displayName,
                size: widget.size,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isUploading ? Icons.hourglass_bottom : Icons.camera_alt,
                    size: 16,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isUploading && progressPercent != null) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.avatarEditorUploading(progressPercent),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
