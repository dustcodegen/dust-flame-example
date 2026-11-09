import 'package:dust_flame_example/game/action_panel.dart';
import 'package:dust_flame_example/game/falling_token.dart';
import 'package:dust_flame_example/game/game_layout.dart';
import 'package:dust_flame_example/game/playfield.dart';
import 'package:dust_flame_example/game/syntax_catch_game.dart';
import 'package:dust_flame_example/main.dart';
import 'package:dust_flame_example/state.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SyntaxCatchGame> loadGame(WidgetTester tester) async {
  await tester.pumpWidget(const SyntaxCatchApp());
  await pumpFrames(tester, 4);
  return tester
      .state<GameWidgetState<SyntaxCatchGame>>(
        find.byType(GameWidget<SyntaxCatchGame>),
      )
      .currentGame;
}

Future<void> pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Playfield playfieldOf(SyntaxCatchGame game) =>
    game.world.descendants().whereType<Playfield>().single;

Offset gamePoint(WidgetTester tester, double x, double y) {
  final host = tester.getRect(find.byType(GameWidget<SyntaxCatchGame>));
  final scale = host.width / GameLayout.width;
  return Offset(host.left + x * scale, host.top + y * scale);
}

Future<void> catchChoice(
  WidgetTester tester,
  Playfield playfield, {
  required bool correct,
}) async {
  final challenge = playfield.readChallengeViewModel();
  final health = playfield.readHealthViewModel();
  final matched = challenge.state.matched;
  final lives = health.state.lives;
  var choices = <FallingToken>[];
  for (var frame = 0; frame < 30; frame++) {
    choices = playfield.children
        .whereType<FallingToken>()
        .where((token) => token.isMounted && !token.isRemoving)
        .toList();
    if (choices.length == 3) break;
    await pumpFrames(tester, 1);
  }
  expect(choices, hasLength(3));
  expect(
    choices.where((token) => token.token == challenge.state.expectedToken),
    hasLength(1),
  );
  final choice = choices.firstWhere(
    (token) => (token.token == challenge.state.expectedToken) == correct,
  );
  await tester.tapAt(gamePoint(tester, choice.x, GameLayout.paddleY - 60));
  for (var frame = 0; frame < 50; frame++) {
    await pumpFrames(tester, 1);
    if (challenge.state.matched != matched || health.state.lives != lives) {
      return;
    }
  }
  fail('The chosen token did not reach the paddle.');
}

void main() {
  testWidgets(
    'correct catches assemble a complete Dart snippet then start Rust',
    (tester) async {
      final game = await loadGame(tester);
      final playfield = playfieldOf(game);
      final challenge = playfield.readChallengeViewModel();
      final count = challenge.state.challenge.parts.length;
      for (var i = 0; i < count; i++) {
        await catchChoice(tester, playfield, correct: true);
      }
      await pumpFrames(tester, 3);
      expect(challenge.state.complete, isTrue);
      expect(playfield.readScoreViewModel().state.points, count);
      expect(playfield.readHealthViewModel().state.lives, 3);
      expect(game.world.descendants().whereType<ActionPanel>(), hasLength(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFrames(tester, 4);
      expect(challenge.state.round, 1);
      expect(challenge.state.challenge.language, 'Rust');
      expect(challenge.state.matched, 0);
      expect(playfield.readScoreViewModel().state.points, count);
      expect(game.world.descendants().whereType<ActionPanel>(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'wrong catches lose lives without advancing code, restart resets each state',
    (tester) async {
      final game = await loadGame(tester);
      final playfield = playfieldOf(game);
      final oldScore = playfield.readScoreViewModel();
      for (var i = 0; i < 3; i++) {
        await catchChoice(tester, playfield, correct: false);
      }
      await pumpFrames(tester, 3);
      expect(playfield.readHealthViewModel().state.lives, 0);
      expect(playfield.readChallengeViewModel().state.matched, 0);
      expect(oldScore.state.points, 0);
      expect(game.world.descendants().whereType<ActionPanel>(), hasLength(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFrames(tester, 4);
      final restarted = playfieldOf(game);
      expect(restarted.readScoreViewModel(), isNot(same(oldScore)));
      expect(restarted.readScoreViewModel().state.points, 0);
      expect(restarted.readHealthViewModel().state.lives, 3);
      expect(restarted.readChallengeViewModel().state.round, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
