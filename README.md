# Syntax Catch

Catch the next token to complete a Dart or Rust program. The full code is shown
above the playfield. The next token is gold, collected tokens are mint, and each
wave mixes the required token with two distractors. A wrong catch costs a life.
Missing a wave gives you another try. Complete the snippet to continue to the
other language.

Drag or tap to position the catcher, or use Left/Right (A/D). Click the visible
button or press Space to continue after a complete snippet or restart after
three mistakes. The four exercises cover printing text and adding two numbers.

Use Flutter 3.44.1 / Dart 3.12.1 and Dust CLI 0.3.1. The native runner targets
macOS 12 or newer.

```sh
flutter pub get
dart run tool/generate.dart
flutter run -d macos
```

Web is also included. Use `flutter run -d chrome` or `flutter build web`.
The game uses native Flame shapes and text, without asset setup.

The developer entrypoint is `lib/state.dart`. It exports the scope, models,
generated accessors, and challenge definitions. The game creates one lazy scope.

```dart
ViewModelScope(children: [Playfield(), GameHud()])
```

A component registers its typed reaction once in its constructor or `onLoad`.

```dart
watchScoreViewModel((score) => text = '${score.state.points}');
```

Commands use the generated reader, for example `readHealthViewModel().hit()`.
Component constructors never receive ViewModels. `ScoreViewModel`,
`HealthViewModel`, and `ChallengeViewModel` hold three independent immutable
states. Movement and falling-token collision checks stay in Flame's frame loop.

`lib/game/syntax_catch_game.dart` owns the session scope. Each nearest scope
creates one model per stable generated descriptor on first use and retains it
until removal. Restarting creates a new scope. Watcher subscriptions follow the
component lifecycle, including reparenting. The game explicitly removes its
session subtree on detach, including while paused.

`GameLayout` centralizes board geometry and spacing. `GameStyle` centralizes
semantic color use and the type scale. The HUD uses aligned stat columns, a
highlighted code panel, and a next-token cue. The shared action panel has a
48-pixel button that activates on tap completion.

| Token | Role |
| --- | --- |
| Teal background / panel | Game surface and code card |
| Mint | Collected syntax and catcher |
| Gold | Next required token |
| Coral | Remaining lives and mistake state |
| Display / numeric / body / caption / token | Consistent text roles |

The scope runtime in `lib/bridge/view_model_scope.dart` is a local prototype.
`tool/generate.dart` reads `@ViewModel` declarations through the Dart analyzer AST
and emits descriptors plus named Flame read/watch helpers. It then invokes the
published Dust CLI for state equality and ViewModel bases. Flame helpers are
part of this review example and are candidates for later Dust integration.

The local generator supports public, concrete, non-generic ViewModels with an
unnamed constructor callable without arguments. Required dependencies receive a
diagnostic. The choice order uses a fixed random seed for repeatable reviews.

```sh
dart run tool/generate.dart --check
flutter analyze
flutter test
flutter build macos --debug
flutter build web
```

`--check` detects stale generated helpers without writing files, then runs
`dust check`. Tests cover generator validation, lazy scope ownership, watcher
rebinding and cleanup, correct/wrong catches, full-code completion, and reset.
