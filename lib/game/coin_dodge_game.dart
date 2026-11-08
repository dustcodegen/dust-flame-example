import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../bridge/view_model_scope.dart';
import 'game_hud.dart';
import 'game_style.dart';
import 'playfield.dart';

class CoinDodgeGame extends FlameGame<World>
    with HasKeyboardHandlerComponents<World> {
  factory CoinDodgeGame() => CoinDodgeGame._(World());

  CoinDodgeGame._(World world)
    : super(
        world: world,
        camera: CameraComponent.withFixedResolution(
          world: world,
          width: 360,
          height: 640,
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
