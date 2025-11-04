import 'package:flutter/material.dart';

extension ColorExtension on Color {
  String toHexString({bool alpha = false, bool short = false}) {
    final rr = (r * 0xFF).floor() & 0xFF;
    final gg = (g * 0xFF).floor() & 0xFF;
    final bb = (b * 0xFF).floor() & 0xFF;
    final aa = (a * 0xFF).floor() & 0xFF;

    final isShort = short &&
        ((rr >> 4) == (rr & 0xF)) &&
        ((gg >> 4) == (gg & 0xF)) &&
        ((bb >> 4) == (bb & 0xF)) &&
        (!alpha || (aa >> 4) == (aa & 0xF));

    if (isShort) {
      final rgb = (rr & 0xF).toRadixString(16) +
          (gg & 0xF).toRadixString(16) +
          (bb & 0xF).toRadixString(16);

      return alpha ? (aa & 0xF).toRadixString(16) + rgb : rgb;
    } else {
      final rgb = rr.toRadixString(16).padLeft(2, '0') +
          gg.toRadixString(16).padLeft(2, '0') +
          bb.toRadixString(16).padLeft(2, '0');

      return alpha ? aa.toRadixString(16).padLeft(2, '0') + rgb : rgb;
    }
  }

  Color getTextContrastColor() {
    return computeLuminance() > 0.88 ? Colors.grey.shade900 : Colors.white;
  }
}