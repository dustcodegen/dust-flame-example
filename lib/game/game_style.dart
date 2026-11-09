import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

abstract final class GameStyle {
  static const background = Color(0xFF191C22);
  static const panel = Color(0xFF222731);
  static const line = Color(0xFF39414E);
  static const mint = Color(0xFF87D7E6);
  static const gold = Color(0xFFFFCA7A);
  static const coral = Color(0xFFE98582);
  static const white = Color(0xFFF4EEDF);
  static const muted = Color(0xFFA2AABB);

  static TextPaint display({Color color = white}) =>
      _text(24, color, family: 'monospace', weight: FontWeight.w700);

  static TextPaint numeric({required Color color}) =>
      _text(22, color, family: 'monospace', weight: FontWeight.w700);

  static TextPaint language({Color color = mint}) =>
      _text(18, color, family: 'monospace', weight: FontWeight.w500);

  static TextPaint body({Color color = muted}) => _text(13, color);

  static TextPaint caption({Color color = muted}) =>
      _text(12, color, family: 'monospace');

  static TextPaint button({Color color = background}) =>
      _text(14, color, family: 'monospace', weight: FontWeight.w700);

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
