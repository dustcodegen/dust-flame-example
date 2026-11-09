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
    _shape = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4));
    _trail = List.generate(
      3,
      (index) =>
          Rect.fromLTWH(size.x / 2 - 1, -30 + index * 10, 2, 4 + index * 2),
    );
  }

  final String token;
  late final RRect _shape;
  late final List<Rect> _trail;
  static final _trailPaints = [
    for (final alpha in [45, 90, 150])
      Paint()..color = GameStyle.muted.withAlpha(alpha),
  ];
  final _fill = Paint()..color = GameStyle.panel;
  final _border = Paint()
    ..color = GameStyle.line
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    for (var index = 0; index < _trail.length; index++) {
      canvas.drawRect(_trail[index], _trailPaints[index]);
    }
    canvas.drawRRect(_shape, _fill);
    canvas.drawRRect(_shape, _border);
    super.render(canvas);
  }
}
