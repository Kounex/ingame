import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/services/avatar_image_editor.dart';
import 'package:ingame/shared/services/avatar_image_picker.dart';
import 'package:ingame/shared/services/avatar_source_loader.dart';
import 'package:ingame/shared/services/avatar_upload_service.dart';
import 'package:ingame/shared/widgets/editable_avatar_field.dart';
import 'package:ingame/shared/widgets/user_avatar.dart';

class _FakeAvatarImagePicker implements AvatarImagePicker {
  _FakeAvatarImagePicker({
    this.uploadResult,
    this.libraryResult,
    this.cameraResult,
  });

  final XFile? uploadResult;
  final XFile? libraryResult;
  final XFile? cameraResult;
  int uploadCalls = 0;
  int libraryCalls = 0;
  int cameraCalls = 0;

  @override
  Future<XFile?> pickFromCamera() async {
    cameraCalls++;
    return cameraResult;
  }

  @override
  Future<XFile?> pickFromLibrary() async {
    libraryCalls++;
    return libraryResult;
  }

  @override
  Future<XFile?> pickUploadFile() async {
    uploadCalls++;
    return uploadResult;
  }
}

class _FakeAvatarSourceLoader implements AvatarSourceLoader {
  _FakeAvatarSourceLoader(this.result);

  final XFile? result;
  final List<String> loadedUrls = [];

  @override
  XFile fromBytes(
    Uint8List bytes, {
    required String filename,
    String? contentType,
  }) {
    return XFile.fromData(bytes, name: filename, mimeType: contentType);
  }

  @override
  Future<XFile> loadRemoteImage(
    String url, {
    String? suggestedFilename,
  }) async {
    loadedUrls.add(url);
    return result ?? XFile.fromData(Uint8List.fromList([1]), name: suggestedFilename);
  }
}

class _FakeAvatarImageEditor implements AvatarImageEditor {
  _FakeAvatarImageEditor(this.result);

  final AvatarEditResult? result;
  Uint8List? lastSourceBytes;
  String? lastSourceFilename;
  AvatarSourceCallback? lastOnChangeSource;
  bool? lastShowRemove;

  @override
  Future<AvatarEditResult?> editSquareAvatar(
    BuildContext context, {
    required Uint8List sourceBytes,
    required String sourceFilename,
    AvatarSourceCallback? onChangeSource,
    bool showRemove = false,
  }) async {
    lastSourceBytes = sourceBytes;
    lastSourceFilename = sourceFilename;
    lastOnChangeSource = onChangeSource;
    lastShowRemove = showRemove;
    return result;
  }
}

class _RecordingAvatarUploadService extends AvatarUploadService {
  _RecordingAvatarUploadService({required this.target})
    : super(dio: Dio());

  final AvatarUploadTarget target;
  String? lastFilename;
  String? lastContentType;
  int? lastByteSize;
  Uint8List? lastUploadedBytes;

  @override
  Future<AvatarUploadTarget> prepareUpload({
    required String filename,
    required String contentType,
    required int byteSize,
  }) async {
    lastFilename = filename;
    lastContentType = contentType;
    lastByteSize = byteSize;
    return target;
  }

  @override
  Future<void> uploadBinary({
    required AvatarUploadTarget target,
    required Uint8List bytes,
    required String filename,
    ProgressCallback? onSendProgress,
  }) async {
    lastUploadedBytes = bytes;
    onSendProgress?.call(bytes.length, bytes.length);
  }
}

Uint8List _pngBytes() => Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
  0xB1, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  Future<void> pumpAvatarField(
    WidgetTester tester, {
    String? initialAvatarUrl,
    required ValueChanged<String?> onChanged,
    List<Object> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: EditableAvatarField(
              initialAvatarUrl: initialAvatarUrl,
              displayName: 'Ready Player',
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('editable avatar field can update the avatar from a URL', (
    tester,
  ) async {
    final loader = _FakeAvatarSourceLoader(
      XFile.fromData(
        _pngBytes(),
        name: 'avatar.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(
      AvatarEditSave(
        bytes: Uint8List.fromList([9, 8, 7]),
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );
    String? changedAvatarUrl;

    await pumpAvatarField(
      tester,
      onChanged: (value) => changedAvatarUrl = value,
      overrides: [
        avatarSourceLoaderProvider.overrideWithValue(loader),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editable-avatar-action-url')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editable-avatar-url-input')),
      'https://cdn.test/avatar.webp',
    );
    await tester.tap(find.byKey(const Key('editable-avatar-url-save')));
    await tester.pumpAndSettle();

    expect(loader.loadedUrls, ['https://cdn.test/avatar.webp']);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastUploadedBytes, Uint8List.fromList([9, 8, 7]));
    expect(changedAvatarUrl, 'https://cdn.test/avatar.jpg');
  });

  testWidgets('editor removal result clears the current avatar', (
    tester,
  ) async {
    final editor = _FakeAvatarImageEditor(const AvatarEditRemoval());
    final loader = _FakeAvatarSourceLoader(
      XFile.fromData(
        _pngBytes(),
        name: 'current.png',
        mimeType: 'image/png',
      ),
    );
    String? changedAvatarUrl = 'https://cdn.test/original.webp';

    await pumpAvatarField(
      tester,
      initialAvatarUrl: changedAvatarUrl,
      onChanged: (value) => changedAvatarUrl = value,
      overrides: [
        avatarSourceLoaderProvider.overrideWithValue(loader),
        avatarImageEditorProvider.overrideWithValue(editor),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();

    expect(changedAvatarUrl, isNull);
    expect(editor.lastShowRemove, isTrue);
  });

  testWidgets('upload photo uses injected editor result and uploads it', (
    tester,
  ) async {
    final picker = _FakeAvatarImagePicker(
      uploadResult: XFile.fromData(
        _pngBytes(),
        name: 'picked.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(
      AvatarEditSave(
        bytes: Uint8List.fromList([9, 8, 7]),
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );
    String? changedAvatarUrl;

    await pumpAvatarField(
      tester,
      onChanged: (value) => changedAvatarUrl = value,
      overrides: [
        avatarImagePickerProvider.overrideWithValue(picker),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editable-avatar-action-upload')));
    await tester.pumpAndSettle();

    expect(picker.uploadCalls, 1);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastFilename, 'avatar.jpg');
    expect(uploadService.lastContentType, 'image/jpeg');
    expect(uploadService.lastByteSize, 3);
    expect(uploadService.lastUploadedBytes, Uint8List.fromList([9, 8, 7]));
    expect(changedAvatarUrl, 'https://cdn.test/avatar.jpg');
  });

  testWidgets('upload photo cancel keeps the current avatar unchanged', (
    tester,
  ) async {
    final picker = _FakeAvatarImagePicker(
      uploadResult: XFile.fromData(
        _pngBytes(),
        name: 'picked.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(null);
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );
    String? changedAvatarUrl;

    await pumpAvatarField(
      tester,
      onChanged: (value) => changedAvatarUrl = value,
      overrides: [
        avatarImagePickerProvider.overrideWithValue(picker),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editable-avatar-action-upload')));
    await tester.pumpAndSettle();

    expect(picker.uploadCalls, 1);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastFilename, isNull);
    expect(changedAvatarUrl, isNull);
  });

  testWidgets('existing avatar tap edits current image directly', (tester) async {
    final loader = _FakeAvatarSourceLoader(
      XFile.fromData(
        _pngBytes(),
        name: 'steam.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(
      AvatarEditSave(
        bytes: Uint8List.fromList([6, 6, 6]),
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );
    String? changedAvatarUrl = 'https://steamcdn.test/avatar.webp';

    await pumpAvatarField(
      tester,
      initialAvatarUrl: changedAvatarUrl,
      onChanged: (value) => changedAvatarUrl = value,
      overrides: [
        avatarSourceLoaderProvider.overrideWithValue(loader),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();

    expect(loader.loadedUrls, ['https://steamcdn.test/avatar.webp']);
    expect(find.byKey(const Key('editable-avatar-action-upload')), findsNothing);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastUploadedBytes, Uint8List.fromList([6, 6, 6]));
    expect(changedAvatarUrl, 'https://cdn.test/avatar.jpg');
  });

  testWidgets('editor receives onChangeSource callback for existing avatar', (
    tester,
  ) async {
    final editor = _FakeAvatarImageEditor(null);
    final loader = _FakeAvatarSourceLoader(
      XFile.fromData(
        _pngBytes(),
        name: 'current.png',
        mimeType: 'image/png',
      ),
    );

    await pumpAvatarField(
      tester,
      initialAvatarUrl: 'https://cdn.test/original.webp',
      onChanged: (_) {},
      overrides: [
        avatarSourceLoaderProvider.overrideWithValue(loader),
        avatarImageEditorProvider.overrideWithValue(editor),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();

    expect(editor.lastOnChangeSource, isNotNull);
    expect(editor.lastShowRemove, isTrue);
  });

  testWidgets('photo library uses picker and routes through editor on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final picker = _FakeAvatarImagePicker(
      libraryResult: XFile.fromData(
        _pngBytes(),
        name: 'library.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(
      AvatarEditSave(
        bytes: Uint8List.fromList([7, 7, 7]),
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );

    await pumpAvatarField(
      tester,
      onChanged: (_) {},
      overrides: [
        avatarImagePickerProvider.overrideWithValue(picker),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editable-avatar-action-library')));
    await tester.pumpAndSettle();

    expect(picker.libraryCalls, 1);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastUploadedBytes, Uint8List.fromList([7, 7, 7]));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('take photo uses picker and routes through editor on mobile', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final picker = _FakeAvatarImagePicker(
      cameraResult: XFile.fromData(
        _pngBytes(),
        name: 'camera.png',
        mimeType: 'image/png',
      ),
    );
    final editor = _FakeAvatarImageEditor(
      AvatarEditSave(
        bytes: Uint8List.fromList([5, 5, 5]),
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final uploadService = _RecordingAvatarUploadService(
      target: const AvatarUploadTarget(
        uploadUrl: 'https://upload.test',
        uploadFields: {'key': 'value'},
        objectKey: 'users/u1/avatars/a.jpg',
        avatarUrl: 'https://cdn.test/avatar.jpg',
        expiresInSeconds: 300,
        maxFileSizeBytes: 2097152,
        allowedContentTypes: ['image/jpeg'],
      ),
    );

    await pumpAvatarField(
      tester,
      onChanged: (_) {},
      overrides: [
        avatarImagePickerProvider.overrideWithValue(picker),
        avatarImageEditorProvider.overrideWithValue(editor),
        avatarUploadServiceProvider.overrideWithValue(uploadService),
      ],
    );

    await tester.tap(find.byKey(const Key('editable-avatar-field-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editable-avatar-action-camera')));
    await tester.pumpAndSettle();

    expect(picker.cameraCalls, 1);
    expect(editor.lastSourceBytes, isNotNull);
    expect(uploadService.lastUploadedBytes, Uint8List.fromList([5, 5, 5]));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('editable avatar field exposes a click cursor on desktop/web', (
    tester,
  ) async {
    await pumpAvatarField(tester, onChanged: (_) {});

    final mouseRegions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
    expect(
      mouseRegions.any((region) => region.cursor == SystemMouseCursors.click),
      isTrue,
    );
  });

  testWidgets('user avatar falls back to initials when a remote image fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            imageUrl: 'https://cdn.test/missing-avatar.webp',
            displayName: 'Ready Player',
            size: 64,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('RP'), findsOneWidget);
  });
}
