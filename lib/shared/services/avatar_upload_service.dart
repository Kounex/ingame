import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/networking/api_client.dart';
import '../../core/networking/api_endpoints.dart';

class AvatarUploadTarget {
  const AvatarUploadTarget({
    required this.uploadUrl,
    required this.uploadFields,
    required this.objectKey,
    required this.avatarUrl,
    required this.expiresInSeconds,
    required this.maxFileSizeBytes,
    required this.allowedContentTypes,
  });

  factory AvatarUploadTarget.fromJson(Map<String, dynamic> json) {
    return AvatarUploadTarget(
      uploadUrl: json['upload_url'] as String,
      uploadFields: Map<String, String>.from(
        json['upload_fields'] as Map<String, dynamic>,
      ),
      objectKey: json['object_key'] as String,
      avatarUrl: json['avatar_url'] as String,
      expiresInSeconds: json['expires_in_seconds'] as int,
      maxFileSizeBytes: json['max_file_size_bytes'] as int,
      allowedContentTypes: (json['allowed_content_types'] as List<dynamic>)
          .cast<String>(),
    );
  }

  final String uploadUrl;
  final Map<String, String> uploadFields;
  final String objectKey;
  final String avatarUrl;
  final int expiresInSeconds;
  final int maxFileSizeBytes;
  final List<String> allowedContentTypes;
}

class AvatarUploadService {
  AvatarUploadService({required this.dio});

  final Dio dio;

  Future<AvatarUploadTarget> prepareUpload({
    required String filename,
    required String contentType,
    required int byteSize,
  }) async {
    final response = await dio.post(
      ApiEndpoints.avatarUploadInit,
      data: {
        'filename': filename,
        'content_type': contentType,
        'byte_size': byteSize,
      },
    );

    return AvatarUploadTarget.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> uploadBinary({
    required AvatarUploadTarget target,
    required Uint8List bytes,
    required String filename,
    ProgressCallback? onSendProgress,
  }) async {
    final uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    final formData = FormData.fromMap({
      ...target.uploadFields,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    await uploadDio.post(
      target.uploadUrl,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        headers: const {'Accept': '*/*'},
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
  }
}

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService(dio: ref.read(dioProvider));
});
