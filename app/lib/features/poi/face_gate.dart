import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// SPEC §6 — on-device face-detection gate, run before upload for both the camera and
/// gallery POI-creation paths. Owning this small interface (instead of depending on
/// `FaceDetector` directly) keeps the controller unit-testable without ML Kit's platform
/// channel, which requires a real device/emulator to run (same rationale as `SecureStore`).
abstract class FaceGate {
  /// Returns true if at least one face is detected in the image at [imagePath].
  Future<bool> hasFace(String imagePath);
}

class MlKitFaceGate implements FaceGate {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  @override
  Future<bool> hasFace(String imagePath) async {
    final faces = await _detector.processImage(InputImage.fromFilePath(imagePath));
    return faces.isNotEmpty;
  }
}
