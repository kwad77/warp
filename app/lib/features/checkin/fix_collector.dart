import '../../models/gps_fix.dart';

/// SPEC §5.1/§5.3/§13.2 — collects `minFixes..maxFixes` fixes from [fixes], stopping once
/// `maxFixes` is reached, or once `minFixes` is reached AND the span between the first and
/// latest fix's own `capturedAt` is at least [minSpan], or once that span reaches
/// [maxWindow] (whichever comes first). Pure over the fixes' own timestamps — no
/// wall-clock reads — so it's fully unit-testable against a synthetic stream; the caller
/// applies a real wall-clock timeout to the underlying device stream separately, so a
/// stalled GPS feed can't hang this forever.
Future<List<GpsFix>> collectFixes(
  Stream<GpsFix> fixes, {
  required int minFixes,
  required int maxFixes,
  required Duration minSpan,
  required Duration maxWindow,
}) async {
  final collected = <GpsFix>[];
  await for (final fix in fixes) {
    collected.add(fix);
    final span = fix.capturedAt.difference(collected.first.capturedAt);
    if (collected.length >= maxFixes) break;
    if (collected.length >= minFixes && span >= minSpan) break;
    if (span >= maxWindow) break;
  }
  return collected;
}
