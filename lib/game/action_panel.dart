import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'syntax_catch_game.dart';
import 'game_layout.dart';
import 'game_style.dart';

class ActionPanel extends PositionComponent
    with TapCallbacks, HasGameReference<SyntaxCatchGame> {
  ActionPanel({required this.complete})
    : super(
        position: Vector2(
          GameLayout.gameOverBounds.left,
          GameLayout.gameOverBounds.top,
        ),
        size: Vector2(
          GameLayout.gameOverBounds.width,
          GameLayout.gameOverBounds.height,
        ),
        priority: 100,
      );

  final bool complete;
  final _result = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.contentWidth / 2, 64),
    textRenderer: GameStyle.body(),
  );

  static final _panelPaint = Paint()..color = GameStyle.panel;
  static final _buttonPaint = Paint()..color = GameStyle.mint;
  static final _panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      0,
      0,
      GameLayout.gameOverBounds.width,
      GameLayout.gameOverBounds.height,
    ),
    const Radius.circular(GameLayout.dialogRadius),
  );
  static final _button = RRect.fromRectAndRadius(
    GameLayout.restartButtonBounds,
    const Radius.circular(GameLayout.panelRadius),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      TextComponent(
        text: complete ? 'Code complete' : 'Out of lives',
        anchor: Anchor.topCenter,
        position: Vector2(GameLayout.contentWidth / 2, 22),
        textRenderer: GameStyle.display(),
      ),
      _result,
      TextComponent(
        text: complete ? 'Next code' : 'Try again',
        anchor: Anchor.center,
        position: Vector2(
          GameLayout.restartButtonBounds.center.dx,
          GameLayout.restartButtonBounds.center.dy,
        ),
        textRenderer: GameStyle.button(),
      ),
      TextComponent(
        text: 'Or press Space',
        anchor: Anchor.topCenter,
        position: Vector2(GameLayout.contentWidth / 2, 174),
        textRenderer: GameStyle.caption(),
      ),
    ]);
  }

  @override
  void onMount() {
    super.onMount();
    final points = readScoreViewModel().state.points;
    _result.text =
        '$points ${points == 1 ? 'point' : 'points'} · '
        'Round ${readChallengeViewModel().state.round + 1}';
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      GameLayout.restartButtonBounds.contains(Offset(point.x, point.y));

  @override
  void onTapUp(TapUpEvent event) {
    if (!containsLocalPoint(event.localPosition)) return;
    if (complete) {
      readChallengeViewModel().next();
    } else {
      game.restart();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_panel, _panelPaint);
    canvas.drawRRect(_button, _buttonPaint);
    super.render(canvas);
  }
}
