import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'game_layout.dart';
import 'game_style.dart';

class FallingToken extends PositionComponent {
  FallingToken({required this.token, required double x})
    : super(position: Vector2(x, GameLayout.spawnY), anchor: Anchor.center) {
    final label = TextComponent(
      text: token,
      textRenderer: GameStyle.token(color: GameStyle.white),
    );
    size = Vector2(label.width + 24, 42);
    label.anchor = Anchor.center;
    label.position = size / 2;
    add(label);
    _shape = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(9));
  }

  final String token;
  late final RRect _shape;
  final _fill = Paint()..color = GameStyle.panel;
  final _border = Paint()
    ..color = GameStyle.line
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_shape, _fill);
    canvas.drawRRect(_shape, _border);
    super.render(canvas);
  }
}
