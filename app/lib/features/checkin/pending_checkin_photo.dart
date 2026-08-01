/// A photo captured in-app for a photo-mode check-in, awaiting the face-detection gate,
/// upload, and capture-token minting (SPEC §5.5/§13.2). `capturedAt` is the shutter
/// timestamp used verbatim in the capture-token hash and sent to the server — it MUST be
/// recorded at capture time, not re-derived later.
class PendingCheckinPhoto {
  final String path;
  final DateTime capturedAt;

  const PendingCheckinPhoto({required this.path, required this.capturedAt});
}
