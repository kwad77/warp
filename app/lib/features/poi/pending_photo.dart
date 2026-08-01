/// A camera-captured or gallery-picked image awaiting the face-detection gate and,
/// if it passes, upload (SPEC §6/§13.1). `contentType` MUST be in
/// `SPEC_CONSTANTS.photos.ALLOWED_MIME` (`image/jpeg` or `image/webp`).
class PendingPhoto {
  final String path;
  final String contentType;

  const PendingPhoto({required this.path, required this.contentType});
}
