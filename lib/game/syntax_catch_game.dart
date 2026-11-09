import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../state.dart';
import 'game_layout.dart';
import 'game_hud.dart';
import 'game_style.dart';
import 'playfield.dart';

class SyntaxCatchGame extends FlameGame<World>
    with HasKeyboardHandlerComponents<World> {
  factory SyntaxCatchGame() => SyntaxCatchGame._(World());

  SyntaxCatchGame._(World world)
    : super(
        world: world,
        camera: CameraComponent.withFixedResolution(
          world: world,
          width: GameLayout.width,
          height: GameLayout.height,
        ),
      ) {
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  ViewModelScope? _session;

  @override
  Color backgroundColor() => GameStyle.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    restart();
  }

  void restart() {
    _session?.removeFromParent();
    final session = ViewModelScope(children: [Playfield(), GameHud()]);
    _session = session;
    world.add(session);
  }

  @override
  void onRemove() {
    world.removeAll(world.children);
    processLifecycleEvents();
    super.onRemove();
  }
}
