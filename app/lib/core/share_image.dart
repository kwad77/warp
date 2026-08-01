import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// SPEC §19 — writes [bytes] to a temp file and hands it to the native share sheet. A
/// real file rather than `XFile.fromData` — some share_plus platform-channel
/// implementations need an actual path, not in-memory bytes, to hand off to the OS.
Future<void> shareImageBytes(
  Uint8List bytes, {
  required String filename,
  String? text,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: text);
}

/// SPEC §19 — captures whatever [key]'s `RepaintBoundary` currently renders as a PNG.
/// Used for all three share targets (map, photo, leaderboard) so each just needs to wrap
/// its shareable content in a `RepaintBoundary` and hold its `GlobalKey`.
Future<Uint8List?> captureRepaintBoundary(GlobalKey key, {double pixelRatio = 2.0}) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
