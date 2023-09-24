library moxxmpp_color;

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:hsluv/extensions.dart';

/// The default saturation to use.
const _defaultSaturation = 50;

/// The default lightness to use.
const _defaultLightness = 50;

/// Implementation of the algorithm in XEP-0392. [hashBytes] are the bytes
/// of the SHA-1 hash of the input.
Color _computeColor(
  List<int> hashBytes, {
  double? saturation,
  double? lightness,
}) {
  final bytes = hashBytes.sublist(0, 2);
  final angle = (bytes.last << 8 + bytes.first).toDouble() / 65565;
  return hsluvToRGBColor([
    angle * 360,
    (saturation ?? _defaultSaturation).remainder(360),
    (lightness ?? _defaultLightness).remainder(360),
  ]);
}

/// Like [consistentColor], but synchronous.
Color consistentColorSync(
  String input, {
  double? saturation,
  double? lightness,
}) {
  return _computeColor(
    Sha1().toSync().hashSync(utf8.encode(input)).bytes,
    saturation: saturation,
    lightness: lightness,
  );
}

/// Compute the color based on the algorithm described in XEP-0392.
/// [saturation] and [lightness] can be used to supply values to use
/// instead of the default.
Future<Color> consistentColor(
  String input, {
  double? saturation,
  double? lightness,
}) async {
  return _computeColor(
    (await Sha1().hash(utf8.encode(input))).bytes,
    saturation: saturation,
    lightness: lightness,
  );
}
