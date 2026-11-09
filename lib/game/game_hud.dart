import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'action_panel.dart';
import 'code_preview.dart';
import 'game_layout.dart';
import 'game_style.dart';

class GameHud extends Component {
  GameHud() {
    watchScoreViewModel((score) {
      _score.text = '${score.state.points}'.padLeft(2, '0');
    });
    watchHealthViewModel((health) {
      _lives = health.state.lives;
      _health.text = '$_lives / 3';
      _updatePanel();
    });
    watchChallengeViewModel((challenge) {
      final state = challenge.state;
      _language.text = state.challenge.language.toUpperCase();
      final labelWidth =
          GameLayout.contentWidth / GameLayout.statCenters.length -
          GameLayout.codeInset;
      _language.scale.setAll(
        (labelWidth / _language.width).clamp(0.0, 1.0).toDouble(),
      );
      _round.text = 'LESSON ${state.round + 1}';
      _targetTitle.text = state.complete
          ? 'Code complete'
          : 'NEXT  ${state.expectedToken}';
      _targetTitle.textRenderer = GameStyle.caption(
        color: state.complete ? GameStyle.mint : GameStyle.gold,
      );
      _matched.text =
          '${state.matched} / ${state.challenge.parts.length} collected';
      _code.show(state.challenge.parts, state.matched);
      _started = state.started;
      _complete = state.complete;
      _updatePanel();
    });
  }

  final _score = TextComponent(
    anchor: Anchor.center,
    position: Vector2(GameLayout.statCenters[0], 132),
    textRenderer: GameStyle.numeric(color: GameStyle.gold),
  );
  final _health = TextComponent(
    anchor: Anchor.center,
    position: Vector2(GameLayout.statCenters[1], 132),
    textRenderer: GameStyle.numeric(color: GameStyle.coral),
  );
  final _language = TextComponent(
    anchor: Anchor.center,
    position: Vector2(GameLayout.statCenters[2], 132),
    textRenderer: GameStyle.language(),
  );
  final _round = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.statCenters[2], 99),
    textRenderer: GameStyle.caption(),
  );
  final _targetTitle = TextComponent(
    position: Vector2(GameLayout.gutter + GameLayout.codeInset, 196),
    textRenderer: GameStyle.caption(color: GameStyle.gold),
  );
  final _matched = TextComponent(
    anchor: Anchor.topRight,
    position: Vector2(
      GameLayout.width - GameLayout.gutter - GameLayout.codeInset,
      196,
    ),
    textRenderer: GameStyle.caption(),
  );
  final _code = CodePreview();
  int _lives = 3;
  bool _started = false;
  bool _complete = false;
  ActionPanel? _panel;

  static final _panelPaint = Paint()..color = GameStyle.panel;
  static final _borderPaint = Paint()
    ..color = GameStyle.line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _statsPanel = RRect.fromRectAndRadius(
    GameLayout.statsBounds,
    const Radius.circular(GameLayout.panelRadius),
  );
  static final _codePanel = RRect.fromRectAndRadius(
    GameLayout.codeBounds,
    const Radius.circular(GameLayout.panelRadius),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      TextComponent(
        text: 'SYNTAX CATCH',
        position: Vector2(GameLayout.gutter, 24),
        textRenderer: GameStyle.display(),
      ),
      TextComponent(
        text: 'Catch NEXT. Let other tokens fall.',
        position: Vector2(GameLayout.gutter, 63),
        textRenderer: GameStyle.body(),
      ),
      _score,
      _health,
      _language,
      _label('SCORE', GameLayout.statCenters[0]),
      _label('LIVES', GameLayout.statCenters[1]),
      _round,
      _targetTitle,
      _matched,
      _code,
      TextComponent(
        text: 'ARROW KEYS / A D / DRAG TO MOVE',
        anchor: Anchor.center,
        position: Vector2(GameLayout.width / 2, GameLayout.footerY),
        textRenderer: GameStyle.caption(),
      ),
    ]);
  }

  TextComponent _label(String label, double x) => TextComponent(
    text: label,
    anchor: Anchor.topCenter,
    position: Vector2(x, 99),
    textRenderer: GameStyle.caption(),
  );

  void _updatePanel() {
    if (_lives > 0 && _started && !_complete) {
      _panel?.removeFromParent();
      _panel = null;
      return;
    }
    final ready = _lives > 0 && !_started;
    final complete = _lives > 0 && _complete;
    if (_panel?.complete == complete && _panel?.ready == ready) return;
    _panel?.removeFromParent();
    final panel = ActionPanel(complete: complete, ready: ready);
    _panel = panel;
    add(panel);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_statsPanel, _panelPaint);
    canvas.drawRRect(_statsPanel, _borderPaint);
    canvas.drawRRect(_codePanel, _panelPaint);
    canvas.drawRRect(_codePanel, _borderPaint);
    final columnWidth = GameLayout.contentWidth / 3;
    for (var column = 1; column < 3; column++) {
      final x = GameLayout.gutter + columnWidth * column;
      canvas.drawLine(Offset(x, 100), Offset(x, 148), _borderPaint);
    }
    super.render(canvas);
  }
}
