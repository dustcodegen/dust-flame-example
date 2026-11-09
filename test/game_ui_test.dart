import 'package:dust_flame_example/game/action_panel.dart';
import 'package:dust_flame_example/game/game_hud.dart';
import 'package:dust_flame_example/game/game_layout.dart';
import 'package:dust_flame_example/game/playfield.dart';
import 'package:dust_flame_example/game/syntax_catch_game.dart';
import 'package:dust_flame_example/main.dart';
import 'package:dust_flame_example/state.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SyntaxCatchGame> _loadGame(WidgetTester tester) async {
  await tester.pumpWidget(const SyntaxCatchApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 32));
  return tester
      .state<GameWidgetState<SyntaxCatchGame>>(
        find.byType(GameWidget<SyntaxCatchGame>),
      )
      .currentGame;
}

Playfield _playfield(SyntaxCatchGame game) =>
    game.world.descendants().whereType<Playfield>().single;

void main() {
  testWidgets('target progress updates and restart requires button tap-up', (
    tester,
  ) async {
    final game = await _loadGame(tester);
    final playfield = _playfield(game);
    final challenge = playfield.readChallengeViewModel();
    challenge.accept(challenge.state.expectedToken!);
    challenge.accept(challenge.state.expectedToken!);
    challenge.accept(challenge.state.expectedToken!);
    final hud = game.world.descendants().whereType<GameHud>().single;
    final labels = hud
        .descendants()
        .whereType<TextComponent>()
        .map((text) => text.text)
        .toList();
    expect(labels, contains('3 / ${challenge.state.challenge.parts.length}'));
    expect(labels, contains('NEXT  ${challenge.state.expectedToken}'));

    final health = playfield.readHealthViewModel();
    health.hit();
    health.hit();
    health.hit();
    await tester.pump(const Duration(milliseconds: 32));
    final panel = game.world.descendants().whereType<ActionPanel>().single;
    final hostBounds = tester.getRect(find.byType(GameWidget<SyntaxCatchGame>));
    final scale = hostBounds.width / GameLayout.width;
    Offset screenPoint(double x, double y) =>
        Offset(hostBounds.left + x * scale, hostBounds.top + y * scale);

    await tester.tapAt(screenPoint(panel.x + 12, panel.y + 12));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_playfield(game), same(playfield));

    final buttonCenter = GameLayout.restartButtonBounds.center;
    final press = await tester.startGesture(
      screenPoint(panel.x + buttonCenter.dx, panel.y + buttonCenter.dy),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(_playfield(game), same(playfield));
    await press.up();
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_playfield(game), isNot(same(playfield)));
    expect(_playfield(game).readChallengeViewModel().state.matched, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('advancing completed code with Space removes the success panel', (
    tester,
  ) async {
    final game = await _loadGame(tester);
    final challenge = _playfield(game).readChallengeViewModel();
    while (!challenge.state.complete) {
      challenge.accept(challenge.state.expectedToken!);
    }
    await tester.pump(const Duration(milliseconds: 32));
    final panel = game.world.descendants().whereType<ActionPanel>().single;
    expect(panel.complete, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 32));
    expect(game.world.descendants().whereType<ActionPanel>(), isEmpty);
    expect(challenge.state.complete, isFalse);
    expect(challenge.state.round, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
