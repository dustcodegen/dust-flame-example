import 'dart:math';
import 'package:flutter/painting.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import '../state/game_access.generated.dart';
import 'coin_dodge_game.dart';
import 'falling_item.dart';
import 'game_style.dart';

class Playfield extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        KeyboardHandler,
        HasGameReference<CoinDodgeGame> {
  Playfield() : super(size: Vector2(360, 640)) {
    watchHealthViewModel((health) => _active = health.state.lives > 0);
    watchLevelViewModel((level) => _level = level.state.number);
  }

  final paddle = RectangleComponent(
    position: Vector2(180, 556),
    size: Vector2(72, 14),
    anchor: Anchor.center,
    paint: Paint()..color = GameStyle.mint,
  );
  final _items = <FallingItem>[];
  final _random = Random(7);
  double _spawnIn = 0.8;
  double _direction = 0;
  int _level = 1;
  bool _active = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(paddle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;
    _moveTo(paddle.x + _direction * 340 * dt);
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      final item = FallingItem(
        isCoin: _random.nextDouble() > 0.3,
        x: 30 + _random.nextDouble() * 300,
      );
      _items.add(item);
      add(item);
      _spawnIn += max(0.28, 0.85 - _level * 0.06);
    }
    for (var i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      final previousY = item.y;
      item.y += (155 + _level * 26) * dt;
      final hit =
          (item.x - paddle.x).abs() < paddle.width / 2 + item.radius &&
          previousY - item.radius <= paddle.y + paddle.height / 2 &&
          item.y + item.radius >= paddle.y - paddle.height / 2;
      if (hit || item.y > 590) {
        item.removeFromParent();
        _items.removeAt(i);
        if (hit) _catch(item);
        if (!_active) break;
      }
    }
  }

  void _catch(FallingItem item) {
    if (item.isCoin) {
      final coins = readCoinsViewModel()..collect();
      if (coins.state.count % 5 == 0) readLevelViewModel().advance();
    } else {
      readHealthViewModel().hit();
    }
  }

  void _moveTo(double x) => paddle.x = x.clamp(42, 318).toDouble();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_active) _moveTo(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_active) _moveTo(event.localEndPosition.x);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_active) _moveTo(event.localPosition.x);
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
    if (!_active &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      game.restart();
    }
    return !(left || right || event.logicalKey == LogicalKeyboardKey.space);
  }

  @override
  void render(Canvas canvas) {
    final dots = Paint()..color = GameStyle.line;
    for (var x = 30.0; x < 360; x += 30) {
      for (var y = 160.0; y < 550; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, dots);
      }
    }
    canvas.drawLine(const Offset(24, 584), const Offset(336, 584), dots);
    super.render(canvas);
  }
}
