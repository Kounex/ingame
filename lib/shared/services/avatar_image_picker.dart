import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

abstract class AvatarImagePicker {
  Future<XFile?> pickUploadFile();
  Future<XFile?> pickFromLibrary();
  Future<XFile?> pickFromCamera();
}

class DefaultAvatarImagePicker implements AvatarImagePicker {
  DefaultAvatarImagePicker() : _picker = ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 95,
    );
  }

  @override
  Future<XFile?> pickFromLibrary() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
  }

  @override
  Future<XFile?> pickUploadFile() {
    return openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
          mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          webWildCards: ['image/*'],
        ),
      ],
    );
  }
}

final avatarImagePickerProvider = Provider<AvatarImagePicker>((ref) {
  return DefaultAvatarImagePicker();
});
