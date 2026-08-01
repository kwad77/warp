import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Uploads bytes to an R2 presigned PUT URL (SPEC §6). Deliberately NOT routed through
/// [ApiClient]'s Dio instance: that instance's interceptor unconditionally attaches our
/// bearer token to every request, which has no business going to a third-party storage
/// host. A small interface (matching the `SecureStore`/`FaceGate` pattern) keeps the
/// controller unit-testable without a real network call.
abstract class PhotoUploader {
  Future<void> upload(String url, Uint8List bytes, {required String contentType});
}

class HttpPhotoUploader implements PhotoUploader {
  @override
  Future<void> upload(String url, Uint8List bytes, {required String contentType}) async {
    final dio = Dio();
    await dio.put<void>(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }
}
