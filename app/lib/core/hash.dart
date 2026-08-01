import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hex SHA-256 — SPEC §5.5's capture-token formula.
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
