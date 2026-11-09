import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'game_layout.dart';
import 'game_style.dart';

class CodePreview extends PositionComponent {
  CodePreview()
    : super(
        position: Vector2(
          GameLayout.gutter + GameLayout.codeInset,
          GameLayout.codeTop,
        ),
        size: Vector2(GameLayout.codeWidth, GameLayout.codeHeight + 9),
      );

  static const _gutter = 24.0;
  static final _trackPaint = Paint()..color = GameStyle.line;
  static final _progressPaint = Paint()..color = GameStyle.mint;
  static final _track = Rect.fromLTWH(
    0,
    GameLayout.codeHeight + 6,
    GameLayout.codeWidth,
    3,
  );
  TextPainter? _code;
  TextPainter? _numbers;
  Rect _progress = Rect.zero;

  // shortcut: the board fits four short lines; add scrolling for longer lessons.
  void show(List<CodePart> parts, int matched) {
    final spans = <TextSpan>[];
    var lines = 1;
    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      lines += '\n'.allMatches('${part.before}${part.text}').length;
      spans.add(TextSpan(text: part.before));
      spans.add(
        TextSpan(
          text: part.text,
          style: TextStyle(
            color: index < matched
                ? GameStyle.mint
                : index == matched
                ? GameStyle.gold
                : GameStyle.muted,
            decoration: index == matched ? TextDecoration.underline : null,
            decorationColor: GameStyle.gold,
            decorationThickness: 2,
            backgroundColor: index == matched
                ? GameStyle.gold.withAlpha(24)
                : null,
          ),
        ),
      );
    }
    _code?.dispose();
    _code = TextPainter(
      text: TextSpan(style: GameStyle.code, children: spans),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: GameLayout.codeWidth - _gutter);
    _numbers?.dispose();
    _numbers = TextPainter(
      text: TextSpan(
        text: [for (var line = 1; line <= lines; line++) '$line'].join('\n'),
        style: GameStyle.code.copyWith(color: GameStyle.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _gutter - 8);
    _progress = Rect.fromLTWH(
      _track.left,
      _track.top,
      parts.isEmpty ? 0 : _track.width * matched / parts.length,
      _track.height,
    );
  }

  @override
  void render(Canvas canvas) {
    _numbers?.paint(canvas, Offset.zero);
    _code?.paint(canvas, const Offset(_gutter, 0));
    canvas.drawRect(_track, _trackPaint);
    canvas.drawRect(_progress, _progressPaint);
    super.render(canvas);
  }

  @override
  void onRemove() {
    _code?.dispose();
    _numbers?.dispose();
    _code = null;
    _numbers = null;
    super.onRemove();
  }
}
