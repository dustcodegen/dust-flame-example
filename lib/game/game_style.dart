import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

abstract final class GameStyle {
  static const background = Color(0xFF081A20);
  static const panel = Color(0xFF102A32);
  static const line = Color(0xFF21434A);
  static const mint = Color(0xFF9EF5CD);
  static const gold = Color(0xFFFFD166);
  static const coral = Color(0xFFFF7870);
  static const white = Color(0xFFE8F2EF);
  static const muted = Color(0xFF86A4A8);

  static TextPaint text(double size, Color color, {bool bold = false}) =>
      TextPaint(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      );
}
