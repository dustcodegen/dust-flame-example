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

  static TextPaint display({Color color = white}) =>
      _text(28, color, weight: FontWeight.w700);

  static TextPaint numeric({required Color color}) =>
      _text(30, color, family: 'monospace', weight: FontWeight.w700);

  static TextPaint body({Color color = muted}) => _text(13, color);

  static TextPaint caption({Color color = muted}) =>
      _text(12, color, family: 'monospace');

  static TextPaint button({Color color = background}) =>
      _text(16, color, weight: FontWeight.w700);

  static TextPaint token({Color color = white}) =>
      _text(18, color, family: 'monospace', weight: FontWeight.w700);

  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.4,
    color: muted,
  );

  static TextPaint _text(
    double size,
    Color color, {
    String? family,
    FontWeight weight = FontWeight.w400,
  }) => TextPaint(
    style: TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
    ),
  );
}
