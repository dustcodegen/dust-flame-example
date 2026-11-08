import 'package:flutter/painting.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../state/game_access.generated.dart';
import 'coin_dodge_game.dart';
import 'game_style.dart';

class GameHud extends Component {
  GameHud() {
    watchCoinsViewModel((coins) {
      _coinCount = coins.state.count;
      _coins.text = '${coins.state.count}'.padLeft(2, '0');
    });
    watchHealthViewModel((health) {
      _health.text = '${health.state.lives} / 3';
      if (health.state.lives == 0) add(GameOverPanel());
    });
    watchLevelViewModel((level) => _level.text = '${level.state.number}');
  }

  final _coins = TextComponent(
    position: Vector2(40, 102),
    textRenderer: GameStyle.text(30, GameStyle.gold, bold: true),
  );
  final _health = TextComponent(
    position: Vector2(160, 105),
    textRenderer: GameStyle.text(24, GameStyle.coral, bold: true),
  );
  final _level = TextComponent(
    position: Vector2(281, 105),
    textRenderer: GameStyle.text(24, GameStyle.mint, bold: true),
  );
  int _coinCount = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      TextComponent(
        text: 'COIN DODGE',
        position: Vector2(24, 25),
        textRenderer: GameStyle.text(27, GameStyle.white, bold: true),
      ),
      TextComponent(
        text: 'Catch gold. Dodge coral.',
        position: Vector2(24, 63),
        textRenderer: GameStyle.text(12, GameStyle.muted),
      ),
      _coins,
      _health,
      _level,
      _label('COINS', 40),
      _label('LIVES', 160),
      _label('LEVEL', 268),
      TextComponent(
        text: 'DRAG OR USE THE ARROW KEYS',
        anchor: Anchor.center,
        position: Vector2(180, 606),
        textRenderer: GameStyle.text(10, GameStyle.muted),
      ),
      TextComponent(
        text: 'Every 5 coins makes it faster.',
        anchor: Anchor.center,
        position: Vector2(180, 626),
        textRenderer: GameStyle.text(10, GameStyle.muted),
      ),
    ]);
  }

  TextComponent _label(String label, double x) => TextComponent(
    text: label,
    position: Vector2(x, 143),
    textRenderer: GameStyle.text(10, GameStyle.muted),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 92, 312, 74),
        const Radius.circular(12),
      ),
      Paint()..color = GameStyle.panel,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 175, 312, 3),
        const Radius.circular(2),
      ),
      Paint()..color = GameStyle.line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 175, 312 * (_coinCount % 5) / 5, 3),
        const Radius.circular(2),
      ),
      Paint()..color = GameStyle.gold,
    );
    super.render(canvas);
  }
}

class GameOverPanel extends PositionComponent
    with TapCallbacks, HasGameReference<CoinDodgeGame> {
  GameOverPanel()
    : super(position: Vector2(24, 238), size: Vector2(312, 184), priority: 100);

  final _result = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(156, 62),
    textRenderer: GameStyle.text(13, GameStyle.muted),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll([
      TextComponent(
        text: 'NICE RUN.',
        anchor: Anchor.topCenter,
        position: Vector2(156, 24),
        textRenderer: GameStyle.text(26, GameStyle.white, bold: true),
      ),
      _result,
      TextComponent(
        text: 'PLAY AGAIN',
        anchor: Anchor.center,
        position: Vector2(156, 118),
        textRenderer: GameStyle.text(16, GameStyle.background, bold: true),
      ),
      TextComponent(
        text: 'Tap here or press Space',
        anchor: Anchor.topCenter,
        position: Vector2(156, 151),
        textRenderer: GameStyle.text(10, GameStyle.muted),
      ),
    ]);
  }

  @override
  void onMount() {
    super.onMount();
    _result.text =
        '${readCoinsViewModel().state.count} coins / level ${readLevelViewModel().state.number}';
  }

  @override
  void onTapDown(TapDownEvent event) => game.restart();

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(18)),
      Paint()..color = GameStyle.panel,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 98, 248, 40),
        const Radius.circular(10),
      ),
      Paint()..color = GameStyle.mint,
    );
    super.render(canvas);
  }
}
