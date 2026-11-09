import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'game_layout.dart';
import 'game_style.dart';
import 'syntax_catch_game.dart';

class ActionPanel extends PositionComponent
    with TapCallbacks, HasGameReference<SyntaxCatchGame> {
  ActionPanel({required this.complete, this.ready = false})
    : super(
        position: Vector2(
          GameLayout.gutter,
          ready ? GameLayout.readyBounds.top : GameLayout.gameOverBounds.top,
        ),
        size: Vector2(
          GameLayout.contentWidth,
          ready
              ? GameLayout.readyBounds.height
              : GameLayout.gameOverBounds.height,
        ),
        priority: 100,
      ) {
    if (ready) {
      watchChallengeViewModel((model) => _showLanguage(model.state.challenge));
    }
  }

  final bool complete;
  final bool ready;
  final _labels = <TextComponent>[];
  final _presses = <int, int>{};
  final _result = TextComponent(
    position: Vector2(32, 54),
    textRenderer: GameStyle.body(),
  );
  String? _selectedLanguage;
  int _pageStart = 0;

  Rect get buttonBounds =>
      ready ? GameLayout.readyButtonBounds : GameLayout.restartButtonBounds;

  static final _languages = syntaxChallenges
      .map((challenge) => challenge.language)
      .toSet()
      .toList(growable: false);
  static final _tiles = List.generate(
    6,
    (index) => RRect.fromRectAndRadius(
      Rect.fromLTWH(32.0 + (index % 3) * 106, 94.0 + (index ~/ 3) * 42, 96, 34),
      const Radius.circular(GameLayout.panelRadius),
    ),
    growable: false,
  );
  static final _panelPaint = Paint()..color = GameStyle.panel;
  static final _tilePaint = Paint()..color = GameStyle.background;
  static final _buttonPaint = Paint()..color = GameStyle.gold;
  static final _selectedPaint = Paint()
    ..color = GameStyle.gold.withValues(alpha: 0.08);
  static final _borderPaint = Paint()
    ..color = GameStyle.line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _selectedBorder = Paint()
    ..color = GameStyle.gold
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _endShape = _shape(GameLayout.gameOverBounds.size);
  static final _readyShape = _shape(GameLayout.readyBounds.size);
  static final _endButton = _buttonShape(GameLayout.restartButtonBounds);
  static final _readyButton = _buttonShape(GameLayout.readyButtonBounds);

  static RRect _shape(Size size) => RRect.fromRectAndRadius(
    Offset.zero & size,
    const Radius.circular(GameLayout.dialogRadius),
  );

  static RRect _buttonShape(Rect bounds) => RRect.fromRectAndRadius(
    bounds,
    const Radius.circular(GameLayout.panelRadius),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (ready) {
      for (var index = 0; index < _tiles.length; index++) {
        final center = _tiles[index].outerRect.center;
        final label = TextComponent(
          text: '',
          anchor: Anchor.center,
          position: Vector2(center.dx, center.dy),
          textRenderer: GameStyle.caption(),
        );
        _labels.add(label);
      }
    }
    await addAll([
      TextComponent(
        text: ready
            ? 'READ THE CODE'
            : complete
            ? 'CODE COMPLETE'
            : 'OUT OF LIVES',
        position: Vector2(32, 20),
        textRenderer: GameStyle.display(
          color: ready
              ? GameStyle.white
              : complete
              ? GameStyle.mint
              : GameStyle.coral,
        ),
      ),
      _result,
      if (ready)
        TextComponent(
          text: 'CHOOSE LANGUAGE',
          position: Vector2(32, 76),
          textRenderer: GameStyle.caption(),
        ),
      ..._labels,
      if (ready)
        for (final (symbol, bounds) in [
          ('‹', GameLayout.languagePreviousBounds),
          ('›', GameLayout.languageNextBounds),
        ])
          TextComponent(
            text: symbol,
            anchor: Anchor.center,
            position: Vector2(bounds.center.dx, bounds.center.dy),
            textRenderer: GameStyle.language(),
          ),
      TextComponent(
        text: ready
            ? 'START RAIN'
            : complete
            ? 'NEXT CODE'
            : 'TRY AGAIN',
        anchor: Anchor.center,
        position: Vector2(buttonBounds.center.dx, buttonBounds.center.dy),
        textRenderer: GameStyle.button(),
      ),
      TextComponent(
        text: ready ? 'L/R CHOOSE / SPACE STARTS' : 'OR PRESS SPACE',
        anchor: Anchor.topCenter,
        position: Vector2(GameLayout.contentWidth / 2, ready ? 268 : 174),
        textRenderer: GameStyle.caption(),
      ),
    ]);
  }

  void _showLanguage(SyntaxChallenge challenge) {
    _selectedLanguage = challenge.language;
    _pageStart =
        (_languages.indexOf(_selectedLanguage!) ~/ _tiles.length) *
        _tiles.length;
    _result.text = '${challenge.language} / ${challenge.title}';
    for (var index = 0; index < _labels.length; index++) {
      final entry = _pageStart + index;
      _labels[index].text = entry < _languages.length
          ? _languages[entry].toUpperCase()
          : '';
      _labels[index].scale.setAll(
        (84 / _labels[index].width).clamp(0.0, 1.0).toDouble(),
      );
      _labels[index].textRenderer = GameStyle.caption(
        color:
            entry < _languages.length && _languages[entry] == _selectedLanguage
            ? GameStyle.gold
            : GameStyle.muted,
      );
    }
  }

  @override
  void onMount() {
    super.onMount();
    final challenge = readChallengeViewModel().state;
    if (ready) {
      _showLanguage(challenge.challenge);
    } else {
      final points = readScoreViewModel().state.points;
      _result.text =
          '$points ${points == 1 ? 'point' : 'points'} / '
          'Lesson ${challenge.round + 1}';
    }
  }

  int? _targetAt(Vector2 point) {
    final location = Offset(point.x, point.y);
    if (buttonBounds.contains(location)) return -1;
    if (ready) {
      if (GameLayout.languagePreviousBounds.contains(location)) return -2;
      if (GameLayout.languageNextBounds.contains(location)) return -3;
      for (var index = 0; index < _tiles.length; index++) {
        if (_pageStart + index < _languages.length &&
            _tiles[index].outerRect.contains(location)) {
          return index;
        }
      }
    }
    return null;
  }

  @override
  bool containsLocalPoint(Vector2 point) => _targetAt(point) != null;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final target = _targetAt(event.localPosition);
    if (target != null) _presses[event.pointerId] = target;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    final target = _presses.remove(event.pointerId);
    if (target == null || target != _targetAt(event.localPosition)) return;
    if (target == -1) {
      if (ready) {
        readChallengeViewModel().start();
      } else if (complete) {
        readChallengeViewModel().next();
      } else {
        game.restart();
      }
      return;
    }
    if (target < -1) {
      final current = _languages.indexOf(_selectedLanguage!);
      readChallengeViewModel().chooseLanguage(
        _languages[(current + (target == -2 ? -1 : 1)) % _languages.length],
      );
    } else {
      readChallengeViewModel().chooseLanguage(_languages[_pageStart + target]);
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _presses.remove(event.pointerId);
    super.onTapCancel(event);
  }

  @override
  void onRemove() {
    _presses.clear();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final panel = ready ? _readyShape : _endShape;
    canvas.drawRRect(panel, _panelPaint);
    canvas.drawRRect(panel, _borderPaint);
    if (ready) {
      for (var index = 0; index < _tiles.length; index++) {
        final entry = _pageStart + index;
        if (entry >= _languages.length) continue;
        final selected = _languages[entry] == _selectedLanguage;
        canvas.drawRRect(_tiles[index], selected ? _selectedPaint : _tilePaint);
        canvas.drawRRect(
          _tiles[index],
          selected ? _selectedBorder : _borderPaint,
        );
      }
      canvas.drawRect(GameLayout.languagePreviousBounds, _borderPaint);
      canvas.drawRect(GameLayout.languageNextBounds, _borderPaint);
    }
    canvas.drawRRect(ready ? _readyButton : _endButton, _buttonPaint);
    super.render(canvas);
  }
}
