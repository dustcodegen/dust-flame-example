import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/coin_dodge_game.dart';
import 'game/game_style.dart';

void main() => runApp(const CoinDodgeApp());

class CoinDodgeApp extends StatelessWidget {
  const CoinDodgeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Coin Dodge',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: GameStyle.background,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 360 / 640,
            child: ClipRect(
              child: GameWidget<CoinDodgeGame>.controlled(
                gameFactory: CoinDodgeGame.new,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
