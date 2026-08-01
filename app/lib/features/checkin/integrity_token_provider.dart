/// SPEC §5.2/§13.2 — real platform attestation (Play Integrity `decodeIntegrityToken`,
/// App Attest) is scoped out of M1: it needs a Google Cloud/Play Console service account
/// and a paid Apple Developer enrollment, neither obtainable in this environment. This
/// interface is the named seam for it (same treatment as `RekognitionModerationProvider`,
/// SPEC §6) — swap in a real implementation without touching `CheckinController`.
abstract class IntegrityTokenProvider {
  Future<String> token(String nonce);
}

/// The only implementation in M1: matches the server's own `DevIntegrityVerifier` token
/// format exactly, so the check-in flow is exercised end-to-end against a dev server.
class DevIntegrityTokenProvider implements IntegrityTokenProvider {
  @override
  Future<String> token(String nonce) async => 'dev.pass.$nonce';
}
