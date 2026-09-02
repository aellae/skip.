import 'package:flutter/material.dart';

/// WCAG relative-luminance contrast ratio between two colors, in [1, 21].
double contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Picks whichever of [light]/[dark] has the higher WCAG contrast ratio
/// against [background] — for choosing legible text/icon color on top of an
/// arbitrary fill (e.g. a status color used as a selected toggle's
/// background) without hardcoding an assumption about that fill's
/// brightness.
Color bestOnColor(
  Color background, {
  Color light = Colors.white,
  Color dark = Colors.black,
}) {
  return contrastRatio(background, light) >= contrastRatio(background, dark)
      ? light
      : dark;
}
