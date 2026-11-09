import 'package:dust_flame_example/game/action_panel.dart';
import 'package:dust_flame_example/game/falling_token.dart';
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

Future<SyntaxCatchGame> _loadGame(
  WidgetTester tester, {
  bool start = true,
}) async {
  await tester.pumpWidget(const SyntaxCatchApp());
  await _pumpGameFrames(tester);
  final game = tester
      .state<GameWidgetState<SyntaxCatchGame>>(
        find.byType(GameWidget<SyntaxCatchGame>),
      )
      .currentGame;
  if (start) {
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpGameFrames(tester);
  }
  return game;
}

Future<void> _pumpGameFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
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
    expect(
      labels,
      contains('3 / ${challenge.state.challenge.parts.length} collected'),
    );
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

    final buttonCenter = panel.buttonBounds.center;
    final press = await tester.startGesture(
      screenPoint(panel.x + buttonCenter.dx, panel.y + buttonCenter.dy),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(_playfield(game), same(playfield));
    await press.up();
    await _pumpGameFrames(tester);
    expect(_playfield(game), isNot(same(playfield)));
    expect(_playfield(game).readChallengeViewModel().state.matched, 0);
    expect(_playfield(game).readChallengeViewModel().state.started, isFalse);
    expect(
      game.world.descendants().whereType<ActionPanel>().single.ready,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('next code waits for another explicit start', (tester) async {
    final game = await _loadGame(tester);
    final challenge = _playfield(game).readChallengeViewModel();
    while (!challenge.state.complete) {
      challenge.accept(challenge.state.expectedToken!);
    }
    await tester.pump(const Duration(milliseconds: 32));
    final panel = game.world.descendants().whereType<ActionPanel>().single;
    expect(panel.complete, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpGameFrames(tester);
    expect(
      game.world.descendants().whereType<ActionPanel>().single.ready,
      isTrue,
    );
    expect(challenge.state.complete, isFalse);
    expect(challenge.state.round, 1);
    expect(challenge.state.started, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpGameFrames(tester);
    expect(challenge.state.started, isTrue);
    expect(game.world.descendants().whereType<ActionPanel>(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('long language labels fit their stat column', (tester) async {
    final game = await _loadGame(tester, start: false);
    final challenge = _playfield(game).readChallengeViewModel();
    expect(challenge.chooseLanguage('JavaScript'), isTrue);
    expect(challenge.state.challenge.language, 'JavaScript');
    final hud = game.world.descendants().whereType<GameHud>().single;
    final language = hud.children.whereType<TextComponent>().singleWhere(
      (text) => text.text == 'JAVASCRIPT',
    );
    final columnWidth =
        GameLayout.contentWidth / GameLayout.statCenters.length -
        GameLayout.codeInset;
    expect(
      language.width * language.scale.x,
      lessThanOrEqualTo(columnWidth + 0.01),
    );
    expect(language.scale.x, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reading phase stays idle until Start rain is tapped', (
    tester,
  ) async {
    final game = await _loadGame(tester, start: false);
    final playfield = _playfield(game);
    await tester.pump(const Duration(seconds: 4));
    final challenge = playfield.readChallengeViewModel();
    expect(challenge.state.started, isFalse);
    expect(challenge.state.matched, 0);
    expect(playfield.readHealthViewModel().state.lives, 3);
    expect(playfield.children.whereType<FallingToken>(), isEmpty);
    final panel = game.world.descendants().whereType<ActionPanel>().single;
    expect(panel.ready, isTrue);
    final host = tester.getRect(find.byType(GameWidget<SyntaxCatchGame>));
    final scale = host.width / GameLayout.width;
    final button = panel.buttonBounds.center;
    await tester.tapAt(
      Offset(
        host.left + (panel.x + button.dx) * scale,
        host.top + (panel.y + button.dy) * scale,
      ),
    );
    await _pumpGameFrames(tester);
    expect(challenge.state.started, isTrue);
    expect(game.world.descendants().whereType<ActionPanel>(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('language tiles select on release and keep the reading phase', (
    tester,
  ) async {
    final game = await _loadGame(tester, start: false);
    final playfield = _playfield(game);
    final challenge = playfield.readChallengeViewModel();
    final panel = game.world.descendants().whereType<ActionPanel>().single;
    final host = tester.getRect(find.byType(GameWidget<SyntaxCatchGame>));
    final scale = host.width / GameLayout.width;
    Offset screenPoint(Vector2 point) => Offset(
      host.left + (panel.x + point.x) * scale,
      host.top + (panel.y + point.y) * scale,
    );
    for (final (bounds, language) in [
      (GameLayout.languagePreviousBounds, 'SQL'),
      (GameLayout.languageNextBounds, 'Dart'),
    ]) {
      await tester.tapAt(
        screenPoint(Vector2(bounds.center.dx, bounds.center.dy)),
      );
      await _pumpGameFrames(tester);
      expect(challenge.state.challenge.language, language);
      expect(challenge.state.started, isFalse);
    }
    for (final name in ['Go', 'Python']) {
      final label = panel.children.whereType<TextComponent>().singleWhere(
        (text) => text.text == name.toUpperCase(),
      );
      final before = challenge.state.challenge.language;
      final press = await tester.startGesture(screenPoint(label.position));
      await tester.pump(const Duration(milliseconds: 16));
      expect(challenge.state.challenge.language, before);
      await press.up();
      await _pumpGameFrames(tester);
      expect(challenge.state.challenge.language, name);
      expect(challenge.state.started, isFalse);
      expect(challenge.state.matched, 0);
      expect(
        game.world.descendants().whereType<ActionPanel>().single,
        same(panel),
      );
      expect(playfield.children.whereType<FallingToken>(), isEmpty);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _pumpGameFrames(tester);
    expect(challenge.state.challenge.language, 'JavaScript');
    expect(challenge.state.started, isFalse);
    final button = panel.buttonBounds.center;
    await tester.tapAt(screenPoint(Vector2(button.dx, button.dy)));
    await _pumpGameFrames(tester);
    expect(challenge.state.started, isTrue);
    expect(challenge.state.challenge.language, 'JavaScript');
    expect(game.world.descendants().whereType<ActionPanel>(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
