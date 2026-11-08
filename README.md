# Coin Dodge

A small playable Flutter + Flame repository for reviewing Dust-style scoped state.
Drag the paddle or use Left/Right (A/D) to catch gold coins and avoid coral hazards.
Five coins advances the level. Three hits ends the run. Tap Play Again or press
Space to start a fresh session.

Run with Flutter 3.44.1 / Dart 3.12.1 and Dust CLI 0.3.1.
The native runner targets macOS 12 or newer.

```sh
flutter pub get
dart run tool/generate.dart
flutter run -d macos
```

Web is also included. Use `flutter run -d chrome` or `flutter build web`.
The game uses native Flame shapes and text, with no external asset downloads.

Start review at `lib/game/coin_dodge_game.dart`. Its single `ViewModelScope`
contains the playfield and HUD. The game has no list of ViewModel registrations.
`lib/state/game_models.dart` declares independent coin, health, and level models.
Flame components use generated `readCoinsViewModel()` and
`watchCoinsViewModel(...)` helpers, with the same pattern for health and level.

The proposed Flame integration lives locally in `lib/bridge/view_model_scope.dart`.
Each nearest scope lazily creates one model per generated descriptor and retains
it until that scope is removed. Restarting creates a fresh scope. Component
watchers unsubscribe on removal or reparenting. The game removes its scoped
subtree and flushes Flame lifecycle events when leaving the widget tree.
Movement, spawning, and collision checks remain in Flame's frame loop. The three
ViewModels emit only meaningful coin, health, and level changes.

The example-only `tool/generate.dart` reads the handwritten model AST and emits
`lib/state/game_access.generated.dart`, including stable descriptors and named
Flame helpers. It then runs `dust build` to generate the usual state equality
and ViewModel bases. This generator is a review spike for an addition to Dust. These
Flame helpers and the scope container are local prototype APIs.

The local generator accepts public, concrete, non-generic ViewModels with an
unnamed constructor callable without arguments. Models with required dependencies
receive a diagnostic so their construction contract can be reviewed explicitly.
The falling-item sequence uses a fixed seed to make review runs repeatable.

```sh
dart run tool/generate.dart
dust check
flutter analyze
flutter test
flutter build macos --debug
flutter build web
```

Tests cover scope isolation, lazy creation, watcher cleanup and rebinding,
generator validation, and gameplay state/reset behavior. The repository contains
macOS and web runners and is independent of the Dust source repository.
