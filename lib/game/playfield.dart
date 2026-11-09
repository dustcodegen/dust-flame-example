import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import 'falling_token.dart';
import 'game_layout.dart';
import 'game_style.dart';
import 'syntax_catch_game.dart';

class Playfield extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        KeyboardHandler,
        HasGameReference<SyntaxCatchGame> {
  Playfield() : super(size: Vector2(GameLayout.width, GameLayout.height)) {
    watchHealthViewModel((health) => _alive = health.state.lives > 0);
    watchChallengeViewModel((challenge) {
      if (_round != challenge.state.round) {
        _clearWave();
        _spawnIn = 0.6;
      }
      _round = challenge.state.round;
      _complete = challenge.state.complete;
    });
  }

  final paddle = RectangleComponent(
    position: Vector2(GameLayout.width / 2, GameLayout.paddleY),
    size: Vector2(88, 12),
    anchor: Anchor.center,
    paint: Paint()..color = GameStyle.mint,
  );
  final _wave = <FallingToken>[];
  final _random = Random(7);
  final _gridPaint = Paint()..color = GameStyle.line;
  double _spawnIn = 0.6;
  double _direction = 0;
  int _round = 0;
  bool _alive = true;
  bool _complete = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(paddle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_alive || _complete) return;
    _moveTo(paddle.x + _direction * 380 * dt);
    if (_wave.isEmpty) {
      _spawnIn -= dt;
      if (_spawnIn <= 0) _spawnWave();
      return;
    }
    for (final token in _wave) {
      final previousY = token.y;
      token.y += (190 + min(_round, 4) * 12) * dt;
      final hit =
          (token.x - paddle.x).abs() < paddle.width / 2 + token.width / 2 &&
          previousY - token.height / 2 <= paddle.y + paddle.height / 2 &&
          token.y + token.height / 2 >= paddle.y - paddle.height / 2;
      if (hit) {
        final accepted = readChallengeViewModel().accept(token.token);
        if (accepted) {
          readScoreViewModel().addPoint();
        } else {
          readHealthViewModel().hit();
        }
        _clearWave();
        _spawnIn = 0.3;
        return;
      }
    }
    if (_wave.every((token) => token.y > GameLayout.despawnY)) {
      _clearWave();
      _spawnIn = 0.3;
    }
  }

  void _spawnWave() {
    final challenge = readChallengeViewModel().state;
    final expected = challenge.expectedToken;
    if (expected == null) return;
    final distractors =
        challenge.challenge.distractors
            .where((token) => token != expected)
            .toSet()
            .toList()
          ..shuffle(_random);
    final choices = [expected, ...distractors.take(2)]..shuffle(_random);
    for (var i = 0; i < choices.length; i++) {
      final token = FallingToken(
        token: choices[i],
        x: GameLayout.laneCenters[i],
      );
      _wave.add(token);
      add(token);
    }
  }

  void _clearWave() {
    for (final token in _wave) {
      token.removeFromParent();
    }
    _wave.clear();
  }

  void _moveTo(double x) => paddle.x = x
      .clamp(GameLayout.paddleMinX, GameLayout.paddleMaxX)
      .toDouble();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_alive && !_complete) _moveTo(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_alive && !_complete) _moveTo(event.localEndPosition.x);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_alive && !_complete) _moveTo(event.localPosition.x);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final left =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final right =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    _direction = (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0);
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      if (!_alive) game.restart();
      if (_alive && _complete) readChallengeViewModel().next();
    }
    return !(left || right || event.logicalKey == LogicalKeyboardKey.space);
  }

  @override
  void render(Canvas canvas) {
    for (final x in GameLayout.laneCenters) {
      for (var y = GameLayout.spawnY; y < GameLayout.floorY; y += 28) {
        canvas.drawCircle(Offset(x, y), 1, _gridPaint);
      }
    }
    canvas.drawLine(
      Offset(GameLayout.gutter, GameLayout.floorY),
      Offset(GameLayout.width - GameLayout.gutter, GameLayout.floorY),
      _gridPaint,
    );
    super.render(canvas);
  }
}
