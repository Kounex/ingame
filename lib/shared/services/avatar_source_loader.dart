import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

abstract class AvatarSourceLoader {
  XFile fromBytes(
    Uint8List bytes, {
    required String filename,
    String? contentType,
  });

  Future<XFile> loadRemoteImage(
    String url, {
    String? suggestedFilename,
  });
}

class DioAvatarSourceLoader implements AvatarSourceLoader {
  DioAvatarSourceLoader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  XFile fromBytes(
    Uint8List bytes, {
    required String filename,
    String? contentType,
  }) {
    return XFile.fromData(
      bytes,
      name: filename,
      mimeType: contentType ?? lookupMimeType(filename, headerBytes: bytes),
    );
  }

  @override
  Future<XFile> loadRemoteImage(
    String url, {
    String? suggestedFilename,
  }) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    final body = response.data;
    if (body == null || body.isEmpty) {
      throw StateError('Remote avatar image is empty');
    }

    final bytes = Uint8List.fromList(body);
    final contentTypeHeader = response.headers.value(Headers.contentTypeHeader);
    final contentType = contentTypeHeader?.split(';').first.trim();
    final uri = Uri.tryParse(url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : null;
    final filename = suggestedFilename ??
        (lastSegment?.isNotEmpty == true ? lastSegment! : 'avatar-download');

    return fromBytes(bytes, filename: filename, contentType: contentType);
  }
}

final avatarSourceLoaderProvider = Provider<AvatarSourceLoader>((ref) {
  return DioAvatarSourceLoader();
});
