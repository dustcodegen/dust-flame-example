import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/syntax_catch_game.dart';
import 'game/game_style.dart';
import 'game/game_layout.dart';

void main() => runApp(const SyntaxCatchApp());

class SyntaxCatchApp extends StatelessWidget {
  const SyntaxCatchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Syntax Catch',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: GameStyle.background,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: GameLayout.width / GameLayout.height,
            child: ClipRect(
              child: GameWidget<SyntaxCatchGame>.controlled(
                gameFactory: SyntaxCatchGame.new,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
