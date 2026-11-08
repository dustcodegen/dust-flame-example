import 'package:flutter/painting.dart';

import 'package:flame/components.dart';

import 'game_style.dart';

class FallingItem extends CircleComponent {
  FallingItem({required this.isCoin, required double x})
    : super(
        position: Vector2(x, 188),
        radius: isCoin ? 9 : 12,
        anchor: Anchor.center,
        paint: Paint()..color = isCoin ? GameStyle.gold : GameStyle.coral,
      );

  final bool isCoin;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final mark = Paint()
      ..color = GameStyle.background
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (isCoin) {
      canvas.drawLine(Offset(radius, 4), Offset(radius, radius * 2 - 4), mark);
    } else {
      canvas.drawLine(const Offset(7, 7), const Offset(17, 17), mark);
      canvas.drawLine(const Offset(17, 7), const Offset(7, 17), mark);
    }
  }
}
