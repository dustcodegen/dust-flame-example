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
        _clearRain();
        _spawnIn = 0.6;
      }
      _wrongDrops = 0;
      _round = challenge.state.round;
      _complete = challenge.state.complete;
      _started = challenge.state.started;
    });
  }

  final paddle = RectangleComponent(
    position: Vector2(GameLayout.width / 2, GameLayout.paddleY),
    size: Vector2(88, 12),
    anchor: Anchor.center,
    paint: Paint()..color = GameStyle.mint,
  );
  final _rain = <FallingToken>[];
  final _random = Random(7);
  final _gridPaint = Paint()..color = GameStyle.line.withAlpha(110);
  final _feedback = TextComponent(
    anchor: Anchor.center,
    position: Vector2(GameLayout.width / 2, GameLayout.floorY + 18),
    textRenderer: GameStyle.caption(),
  );
  double _spawnIn = 0.6;
  double _direction = 0;
  double _feedbackFor = 0;
  int _round = 0;
  int _wrongDrops = 0;
  bool _alive = true;
  bool _complete = false;
  bool _started = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await paddle.addAll([
      for (final x in [0.0, paddle.width - 4])
        RectangleComponent(
          position: Vector2(x, -5),
          size: Vector2(4, paddle.height + 10),
          paint: paddle.paint,
        ),
    ]);
    await addAll([paddle, _feedback]);
  }

  @override
  void update(double dt) {
    // A stalled frame must not sweep several drops through the catcher.
    dt = min(dt, 0.1);
    super.update(dt);
    if (_feedbackFor > 0) {
      _feedbackFor -= dt;
      if (_feedbackFor <= 0) {
        _feedback.text = '';
        paddle.paint.color = GameStyle.mint;
      }
    }
    if (!_alive || !_started || _complete) return;
    _moveTo(paddle.x + _direction * 380 * dt);
    for (var index = 0; index < _rain.length;) {
      final token = _rain[index];
      final previousY = token.y;
      token.y += 190 * dt;
      final hit =
          (token.x - paddle.x).abs() < paddle.width / 2 + token.width / 2 &&
          previousY - token.height / 2 <= paddle.y + paddle.height / 2 &&
          token.y + token.height / 2 >= paddle.y - paddle.height / 2;
      if (hit) {
        _rain.removeAt(index).removeFromParent();
        final expected = readChallengeViewModel().state.expectedToken;
        final accepted = readChallengeViewModel().accept(token.token);
        if (accepted) {
          readScoreViewModel().addPoint();
          _showFeedback('Caught ${token.token} · +1', GameStyle.mint);
        } else {
          readHealthViewModel().hit();
          _showFeedback(
            'Caught ${token.token} · need $expected',
            GameStyle.coral,
          );
        }
        if (!_alive || _complete) {
          _clearRain();
          return;
        }
      } else if (token.y > GameLayout.despawnY) {
        if (token.token == readChallengeViewModel().state.expectedToken &&
            _feedbackFor <= 0) {
          _showFeedback(
            'Missed ${token.token} · it will return',
            GameStyle.gold,
          );
        }
        _rain.removeAt(index).removeFromParent();
      } else {
        index++;
      }
    }
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      _spawnDrop();
      _spawnIn = 0.75;
    }
  }

  void _spawnDrop() {
    final challenge = readChallengeViewModel().state;
    final expected = challenge.expectedToken;
    if (expected == null) return;
    String choice;
    if (_wrongDrops == 2 || _random.nextInt(3) == 0) {
      choice = expected;
      _wrongDrops = 0;
    } else {
      final distractors = challenge.challenge.distractors
          .where((token) => token != expected)
          .toSet()
          .toList();
      choice = distractors[_random.nextInt(distractors.length)];
      _wrongDrops++;
    }
    final token = FallingToken(
      token: choice,
      x: GameLayout.laneCenters[_random.nextInt(GameLayout.laneCenters.length)],
    );
    _rain.add(token);
    add(token);
  }

  void _clearRain() {
    for (final token in _rain) {
      token.removeFromParent();
    }
    _rain.clear();
    _wrongDrops = 0;
  }

  void _showFeedback(String message, Color color) {
    _feedback.text = message;
    _feedback.textRenderer = GameStyle.caption(color: color);
    paddle.paint.color = color;
    _feedbackFor = 1.2;
  }

  void _moveTo(double x) => paddle.x = x
      .clamp(GameLayout.paddleMinX, GameLayout.paddleMaxX)
      .toDouble();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_alive && _started && !_complete) _moveTo(event.localPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_alive && _started && !_complete) _moveTo(event.localEndPosition.x);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_alive && _started && !_complete) _moveTo(event.localPosition.x);
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
    final choiceStep = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => -1,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => 1,
      _ => 0,
    };
    if (event is KeyDownEvent && _alive && !_started && choiceStep != 0) {
      final challenge = readChallengeViewModel();
      final languages = syntaxChallenges
          .map((item) => item.language)
          .toSet()
          .toList();
      final current = languages.indexOf(challenge.state.challenge.language);
      challenge.chooseLanguage(
        languages[(current + choiceStep) % languages.length],
      );
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      if (!_alive) {
        game.restart();
      } else if (_complete) {
        readChallengeViewModel().next();
      } else if (!_started) {
        readChallengeViewModel().start();
      }
    }
    return !(left || right || event.logicalKey == LogicalKeyboardKey.space);
  }

  @override
  void render(Canvas canvas) {
    for (final x in GameLayout.laneCenters) {
      canvas.drawLine(
        Offset(x, GameLayout.spawnY),
        Offset(x, GameLayout.floorY),
        _gridPaint,
      );
    }
    canvas.drawLine(
      Offset(GameLayout.gutter, GameLayout.floorY),
      Offset(GameLayout.width - GameLayout.gutter, GameLayout.floorY),
      _gridPaint,
    );
    super.render(canvas);
  }
}
