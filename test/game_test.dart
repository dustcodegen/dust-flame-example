import 'package:dust_flame_example/game/action_panel.dart';
import 'package:dust_flame_example/game/falling_token.dart';
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

Future<SyntaxCatchGame> loadGame(WidgetTester tester) async {
  await tester.pumpWidget(const SyntaxCatchApp());
  await pumpFrames(tester, 4);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await pumpFrames(tester, 2);
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
  for (var frame = 0; frame < 160; frame++) {
    final drops = playfield.children
        .whereType<FallingToken>()
        .where((token) => token.isMounted && !token.isRemoving)
        .toList();
    if (drops.isNotEmpty) {
      final nearest = drops.reduce((a, b) => a.y > b.y ? a : b);
      final catchIt =
          (nearest.token == challenge.state.expectedToken) == correct;
      final x = catchIt
          ? nearest.x
          : nearest.x < GameLayout.width / 2
          ? GameLayout.paddleMaxX
          : GameLayout.paddleMinX;
      await tester.tapAt(gamePoint(tester, x, GameLayout.paddleY - 60));
    }
    await pumpFrames(tester, 1);
    if (challenge.state.matched != matched || health.state.lives != lives) {
      return;
    }
  }
  fail('The chosen token did not reach the paddle.');
}

void main() {
  testWidgets(
    'keyboard chooses a language before starting and locks it in play',
    (tester) async {
      await tester.pumpWidget(const SyntaxCatchApp());
      await pumpFrames(tester, 4);
      final game = tester
          .state<GameWidgetState<SyntaxCatchGame>>(
            find.byType(GameWidget<SyntaxCatchGame>),
          )
          .currentGame;
      final challenge = playfieldOf(game).readChallengeViewModel();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      expect(challenge.state.challenge.language, 'Rust');
      expect(challenge.state.started, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      expect(challenge.state.started, isTrue);
      expect(challenge.state.challenge.language, 'Rust');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(challenge.state.challenge.language, 'Rust');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a stalled frame cannot rush the rain through the catcher', (
    tester,
  ) async {
    final game = await loadGame(tester);
    final playfield = playfieldOf(game);
    await pumpFrames(tester, 20);
    final drops = playfield.children.whereType<FallingToken>().toList();
    expect(drops, isNotEmpty);
    final positions = drops.map((token) => token.y).toList();
    game.update(5);
    for (var index = 0; index < drops.length; index++) {
      expect(drops[index].y - positions[index], closeTo(19, 0.01));
    }
    expect(playfield.readHealthViewModel().state.lives, 3);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tokens rain individually and skipped pieces return for free', (
    tester,
  ) async {
    final game = await loadGame(tester);
    final playfield = playfieldOf(game);
    final seen = <FallingToken>{};
    final expected = playfield.readChallengeViewModel().state.expectedToken;
    var repeated = 0;
    var consecutiveWrongDrops = 0;
    var lastSpawn = -100;
    var sawOverlappingDrops = false;
    for (var frame = 0; frame < 200; frame++) {
      final drops = playfield.children
          .whereType<FallingToken>()
          .where((token) => token.isMounted && !token.isRemoving)
          .toList();
      final added = drops.where((token) => !seen.contains(token)).toList();
      expect(added.length, lessThanOrEqualTo(1));
      if (added.isNotEmpty) {
        expect(frame - lastSpawn, greaterThanOrEqualTo(10));
        lastSpawn = frame;
        seen.addAll(added);
        repeated += added.where((token) => token.token == expected).length;
        consecutiveWrongDrops = added.single.token == expected
            ? 0
            : consecutiveWrongDrops + 1;
        expect(consecutiveWrongDrops, lessThanOrEqualTo(2));
      }
      sawOverlappingDrops |= drops.length > 1;
      if (drops.isNotEmpty) {
        final nearest = drops.reduce((a, b) => a.y > b.y ? a : b);
        await tester.tapAt(
          gamePoint(
            tester,
            nearest.x < GameLayout.width / 2
                ? GameLayout.paddleMaxX
                : GameLayout.paddleMinX,
            GameLayout.paddleY - 60,
          ),
        );
      }
      await pumpFrames(tester, 1);
    }
    expect(seen.length, greaterThan(10));
    expect(sawOverlappingDrops, isTrue);
    expect(repeated, greaterThanOrEqualTo(2));
    expect(playfield.readChallengeViewModel().state.matched, 0);
    expect(playfield.readHealthViewModel().state.lives, 3);
    expect(playfield.readScoreViewModel().state.points, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
      expect(challenge.state.started, isFalse);
      expect(
        game.world.descendants().whereType<ActionPanel>().single.ready,
        isTrue,
      );
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
        expect(
          playfield.children.whereType<TextComponent>().single.text,
          contains(
            'need ${playfield.readChallengeViewModel().state.expectedToken}',
          ),
        );
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
