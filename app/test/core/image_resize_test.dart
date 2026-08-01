import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wanderpost/core/image_resize.dart';

Uint8List _jpg(int width, int height) => img.encodeJpg(img.Image(width: width, height: height));

/// A flat color compresses to near-nothing regardless of quality — real photos don't.
/// This noisy gradient gives the JPEG encoder genuine work to do, so quality actually
/// affects output size, exercising the adaptive-quality path below.
Uint8List _noisyJpg(int width, int height, {int quality = 85}) {
  final image = img.Image(width: width, height: height);
  final rand = Random(7);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, rand.nextInt(256), rand.nextInt(256), rand.nextInt(256));
    }
  }
  return img.encodeJpg(image, quality: quality);
}

void main() {
  test('an image already within maxLongEdge is left the same size', () {
    final bytes = _jpg(100, 60);

    final result = resizeForUpload(bytes, maxLongEdge: 2048);

    final decoded = img.decodeImage(result!)!;
    expect(decoded.width, 100);
    expect(decoded.height, 60);
  });

  test('a landscape image over maxLongEdge is downscaled, aspect ratio preserved', () {
    final bytes = _jpg(4000, 2000);

    final result = resizeForUpload(bytes, maxLongEdge: 1000);

    final decoded = img.decodeImage(result!)!;
    expect(decoded.width, 1000);
    expect(decoded.height, 500);
  });

  test('a portrait image over maxLongEdge caps the height, not the width', () {
    final bytes = _jpg(1000, 4000);

    final result = resizeForUpload(bytes, maxLongEdge: 1000);

    final decoded = img.decodeImage(result!)!;
    expect(decoded.height, 1000);
    expect(decoded.width, 250);
  });

  test('never upscales an image already under maxLongEdge', () {
    final bytes = _jpg(200, 100);

    final result = resizeForUpload(bytes, maxLongEdge: 2048);

    final decoded = img.decodeImage(result!)!;
    expect(decoded.width, 200);
    expect(decoded.height, 100);
  });

  test('a non-JPEG source (PNG) is re-encoded to JPEG regardless of contentType label', () {
    final pngBytes = img.encodePng(img.Image(width: 50, height: 50));

    final result = resizeForUpload(pngBytes, maxLongEdge: 2048);

    // JPEG magic bytes: FF D8 FF.
    expect(result![0], 0xFF);
    expect(result[1], 0xD8);
    expect(result[2], 0xFF);
  });

  test('undecodable bytes (e.g. HEIC, or garbage) return null', () {
    final result = resizeForUpload(Uint8List.fromList([1, 2, 3]), maxLongEdge: 2048);

    expect(result, isNull);
  });

  test('steps quality down when the default-quality encode exceeds maxBytes', () {
    final bytes = _noisyJpg(300, 300);
    final baseline = resizeForUpload(bytes, maxLongEdge: 2048)!;
    final budget = (baseline.lengthInBytes * 0.6).round();

    final result = resizeForUpload(bytes, maxLongEdge: 2048, maxBytes: budget)!;

    expect(result.lengthInBytes, lessThanOrEqualTo(budget));
    // Dimensions are untouched by quality stepping — only encoding changed.
    final decoded = img.decodeImage(result)!;
    expect(decoded.width, 300);
    expect(decoded.height, 300);
  });

  test('does not lower quality when already under maxBytes', () {
    final bytes = _noisyJpg(100, 100);

    final withoutBudget = resizeForUpload(bytes, maxLongEdge: 2048);
    final withGenerousBudget = resizeForUpload(bytes, maxLongEdge: 2048, maxBytes: 50_000_000);

    expect(withGenerousBudget, equals(withoutBudget));
  });

  test('gives up at the quality floor rather than looping forever on an impossible budget', () {
    final bytes = _noisyJpg(300, 300);

    final result = resizeForUpload(bytes, maxLongEdge: 2048, maxBytes: 1, qualityFloor: 30);

    // Still returns a valid (if over-budget) JPEG — the server's own HEAD check is the
    // backstop, not an exception or a null here.
    expect(result, isNotNull);
    expect(img.decodeImage(result!), isNotNull);
  });
}
