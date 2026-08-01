import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// SPEC §6/§13.1 — downscales (never upscales) so the long edge is ≤ [maxLongEdge], and
/// always re-encodes to JPEG regardless of source format (the declared `contentType` is
/// always `image/jpeg` — SPEC §13.1's dependency note — so the bytes must actually be
/// JPEG). Pure: no I/O, takes and returns bytes. Returns `null` if [bytes] can't be
/// decoded — notably HEIC/HEIF, which the pure-Dart `image` package doesn't support
/// (SPEC §13.1's flagged limitation), or any other malformed/truncated input (some of
/// `image`'s format sniffers throw on a too-short buffer rather than returning null —
/// caught here so it's still a clean `null`, not an uncaught exception). Callers surface
/// this as `photoProcessingFailed`, not a silent pass-through of unresized/mislabeled
/// bytes.
///
/// If [maxBytes] is given and quality-85 encoding still exceeds it (confirmed to happen
/// on a genuinely detailed/noisy photo even at `maxLongEdge` — this isn't hypothetical),
/// quality steps down by 10 (floor 30) until the budget is met or the floor is hit,
/// whichever first — the server's own `UPLOAD_MAX_BYTES` HEAD check (§6) is still the
/// backstop if even the floor doesn't fit, but this makes that rejection the exception
/// rather than a routine occurrence for detailed photos.
Uint8List? resizeForUpload(
  Uint8List bytes, {
  required int maxLongEdge,
  int quality = 85,
  int? maxBytes,
  int qualityFloor = 30,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  final longEdge = decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longEdge <= maxLongEdge
      ? decoded
      : decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxLongEdge, interpolation: img.Interpolation.average)
          : img.copyResize(decoded, height: maxLongEdge, interpolation: img.Interpolation.average);

  var q = quality;
  var encoded = img.encodeJpg(resized, quality: q);
  while (maxBytes != null && encoded.lengthInBytes > maxBytes && q > qualityFloor) {
    q -= 10;
    encoded = img.encodeJpg(resized, quality: q);
  }
  return encoded;
}
