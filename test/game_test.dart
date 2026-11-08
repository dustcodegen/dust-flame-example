import 'package:dust_flame_example/game/coin_dodge_game.dart';
import 'package:dust_flame_example/game/falling_item.dart';
import 'package:dust_flame_example/game/game_hud.dart';
import 'package:dust_flame_example/game/playfield.dart';
import 'package:dust_flame_example/main.dart';
import 'package:dust_flame_example/state/game_access.generated.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<CoinDodgeGame> loadGame(WidgetTester tester) async {
  await tester.pumpWidget(const CoinDodgeApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 32));
  return tester
      .state<GameWidgetState<CoinDodgeGame>>(
        find.byType(GameWidget<CoinDodgeGame>),
      )
      .currentGame;
}

Playfield playfieldOf(CoinDodgeGame game) =>
    game.world.descendants().whereType<Playfield>().single;

void main() {
  testWidgets('three states are independent and restart starts a fresh scope', (
    tester,
  ) async {
    final game = await loadGame(tester);
    final playfield = playfieldOf(game);
    final coins = playfield.readCoinsViewModel();
    final health = playfield.readHealthViewModel();
    final level = playfield.readLevelViewModel();
    expect(coins.state.count, 0);
    expect(health.state.lives, 3);
    expect(level.state.number, 1);

    coins.collect();
    expect(health.state.lives, 3);
    expect(level.state.number, 1);
    health.hit();
    expect(coins.state.count, 1);
    expect(level.state.number, 1);
    level.advance();
    expect(coins.state.count, 1);
    expect(health.state.lives, 2);

    health.hit();
    health.hit();
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.world.descendants().whereType<GameOverPanel>(), hasLength(1));

    game.restart();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final restarted = playfieldOf(game);
    expect(restarted.readCoinsViewModel(), isNot(same(coins)));
    expect(restarted.readCoinsViewModel().state.count, 0);
    expect(restarted.readHealthViewModel().state.lives, 3);
    expect(restarted.readLevelViewModel().state.number, 1);
    expect(game.world.descendants().whereType<GameOverPanel>(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'tap input moves the paddle and a hazard collision loses a life',
    (tester) async {
      final game = await loadGame(tester);
      final playfield = playfieldOf(game);
      final host = tester.getRect(find.byType(GameWidget<CoinDodgeGame>));
      final scale = host.width / 360;
      await tester.tapAt(
        Offset(host.left + 280 * scale, host.top + 500 * scale),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(playfield.paddle.x, closeTo(280, 1));

      await tester.pump(const Duration(milliseconds: 800));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final item = playfield.children.whereType<FallingItem>().first;
      expect(item.isCoin, isFalse);
      await tester.tapAt(
        Offset(host.left + item.x * scale, host.top + 500 * scale),
      );
      await tester.pump(const Duration(milliseconds: 16));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(playfield.readHealthViewModel().state.lives, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('catching five coins advances the level through gameplay', (
    tester,
  ) async {
    final game = await loadGame(tester);
    final playfield = playfieldOf(game);
    final host = tester.getRect(find.byType(GameWidget<CoinDodgeGame>));
    final scale = host.width / 360;
    for (var frame = 0; frame < 650; frame++) {
      final items = playfield.children.whereType<FallingItem>().toList()
        ..sort((a, b) => b.y.compareTo(a.y));
      if (items.isNotEmpty) {
        final next = items.first;
        final target = next.isCoin ? next.x : (next.x < 180 ? 318.0 : 42.0);
        await tester.tapAt(
          Offset(host.left + target * scale, host.top + 500 * scale),
        );
      }
      await tester.pump(const Duration(milliseconds: 60));
      if (playfield.readCoinsViewModel().state.count >= 5) break;
    }
    expect(playfield.readCoinsViewModel().state.count, greaterThanOrEqualTo(5));
    expect(
      playfield.readLevelViewModel().state.number,
      greaterThanOrEqualTo(2),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
