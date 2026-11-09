import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'action_panel.dart';
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
      _round.text = 'ROUND ${state.round + 1}';
      _targetTitle.text = state.complete
          ? 'Code complete'
          : 'NEXT  ${state.expectedToken}';
      _targetTitle.textRenderer = GameStyle.caption(
        color: state.complete ? GameStyle.mint : GameStyle.gold,
      );
      _matched.text = '${state.matched} / ${state.challenge.parts.length}';
      _code.show(state.challenge.parts, state.matched);
      _complete = state.complete;
      _updatePanel();
    });
  }

  final _score = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.statCenters[0], 100),
    textRenderer: GameStyle.numeric(color: GameStyle.gold),
  );
  final _health = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.statCenters[1], 100),
    textRenderer: GameStyle.numeric(color: GameStyle.coral),
  );
  final _language = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.statCenters[2], 100),
    textRenderer: GameStyle.numeric(color: GameStyle.mint),
  );
  final _round = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameLayout.statCenters[2], 143),
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
  final _code = _CodePreview();
  int _lives = 3;
  bool _complete = false;
  ActionPanel? _panel;

  static final _panelPaint = Paint()..color = GameStyle.panel;
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
        text: 'Catch the next token. Wrong picks cost a life.',
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
        text: 'Drag or use the arrow keys / A D',
        anchor: Anchor.center,
        position: Vector2(GameLayout.width / 2, GameLayout.footerY),
        textRenderer: GameStyle.body(),
      ),
    ]);
  }

  TextComponent _label(String label, double x) => TextComponent(
    text: label,
    anchor: Anchor.topCenter,
    position: Vector2(x, 143),
    textRenderer: GameStyle.caption(),
  );

  void _updatePanel() {
    if (_lives > 0 && !_complete) {
      _panel?.removeFromParent();
      _panel = null;
      return;
    }
    final complete = _lives > 0 && _complete;
    if (_panel?.complete == complete) return;
    _panel?.removeFromParent();
    final panel = ActionPanel(complete: complete);
    _panel = panel;
    add(panel);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_statsPanel, _panelPaint);
    canvas.drawRRect(_codePanel, _panelPaint);
    super.render(canvas);
  }
}

class _CodePreview extends PositionComponent {
  _CodePreview()
    : super(
        position: Vector2(
          GameLayout.gutter + GameLayout.codeInset,
          GameLayout.codeTop,
        ),
        size: Vector2(GameLayout.codeWidth, GameLayout.codeHeight),
      );

  TextPainter? _painter;

  void show(List<CodePart> parts, int matched) {
    final spans = <TextSpan>[];
    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      final color = index < matched
          ? GameStyle.mint
          : index == matched
          ? GameStyle.gold
          : GameStyle.muted;
      spans.add(TextSpan(text: part.before));
      spans.add(
        TextSpan(
          text: part.text,
          style: TextStyle(color: color),
        ),
      );
    }
    _painter?.dispose();
    _painter = TextPainter(
      text: TextSpan(style: GameStyle.code, children: spans),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: GameLayout.codeWidth);
  }

  @override
  void render(Canvas canvas) {
    _painter?.paint(canvas, Offset.zero);
    super.render(canvas);
  }

  @override
  void onRemove() {
    _painter?.dispose();
    _painter = null;
    super.onRemove();
  }
}
