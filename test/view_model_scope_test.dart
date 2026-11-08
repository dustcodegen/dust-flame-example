import 'package:dust_flame_example/bridge/view_model_scope.dart';
import 'package:dust_flutter/state.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unmounted scopes never create models', () {
    var creates = 0;
    final key = ViewModelKey(() {
      creates++;
      return _CounterModel();
    });
    final child = Component();
    ViewModelScope(children: [child]);

    expect(() => child.readViewModel(key), throwsStateError);
    expect(creates, 0);
  });

  testWidgets('models are lazy, shared per key, and disposed once', (
    tester,
  ) async {
    var creates = 0;
    final key = ViewModelKey(() {
      creates++;
      return _CounterModel();
    });
    final first = Component();
    final second = Component();
    final scope = ViewModelScope(children: [first, second]);
    final game = _ScopeGame([scope]);
    await _mount(tester, game);
    expect(creates, 0);

    final model = first.readViewModel(key);
    expect(second.readViewModel(key), same(model));
    expect(creates, 1);
    expect(model.initializations, 0);
    await tester.pump();
    expect(model.initializations, 1);

    game.pauseEngine();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(model.disposals, 1);
  });

  testWidgets('separate scopes own separate instances of the same key', (
    tester,
  ) async {
    final key = ViewModelKey(_CounterModel.new);
    final first = Component();
    final second = Component();
    final game = _ScopeGame([
      ViewModelScope(children: [first]),
      ViewModelScope(children: [second]),
    ]);
    await _mount(tester, game);

    final firstModel = first.readViewModel(key);
    final secondModel = second.readViewModel(key);
    expect(firstModel, isNot(same(secondModel)));
    firstModel.setCount(7);
    expect(secondModel.value, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(firstModel.disposals, 1);
    expect(secondModel.disposals, 1);
  });

  testWidgets('watchers rebind on reparent and detach before model disposal', (
    tester,
  ) async {
    final key = ViewModelKey(_CounterModel.new);
    final watching = _WatchingComponent(key);
    final secondReader = Component();
    final firstScope = ViewModelScope(children: [watching]);
    final secondScope = ViewModelScope(children: [secondReader]);
    final game = _ScopeGame([firstScope, secondScope]);
    await _mount(tester, game);

    final firstModel = watching.readViewModel(key);
    firstModel.setCount(1);
    expect(watching.counts, [0, 1]);
    final secondModel = secondReader.readViewModel(key)..setCount(10);

    watching.parent = secondScope;
    game.processLifecycleEvents();
    expect(watching.counts, [0, 1, 10]);
    firstModel.setCount(2);
    secondModel.setCount(11);
    expect(watching.counts, [0, 1, 10, 11]);

    game.pauseEngine();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(firstModel.listenersAtDisposal, isFalse);
    expect(secondModel.listenersAtDisposal, isFalse);
    expect(secondModel.disposals, 1);
  });

  testWidgets('removal before initialization skips pending setup', (
    tester,
  ) async {
    final key = ViewModelKey(_CounterModel.new);
    final child = Component();
    final scope = ViewModelScope(children: [child]);
    final game = _ScopeGame([scope]);
    await _mount(tester, game);

    final model = child.readViewModel(key);
    scope.removeFromParent();
    game.processLifecycleEvents();
    await tester.pump();

    expect(model.initializations, 0);
    expect(model.disposals, 1);
    expect(() => child.readViewModel(key), throwsStateError);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('watching twice before mounting replaces the pending callback', (
    tester,
  ) async {
    final key = ViewModelKey(_CounterModel.new);
    final child = Component();
    final counts = <int>[];
    final game = _ScopeGame([
      ViewModelScope(children: [child]),
    ]);
    await _mount(tester, game);

    child.watchViewModel(key, (_) => counts.add(100));
    child.watchViewModel(key, (model) => counts.add(model.value));
    game.processLifecycleEvents();

    expect(counts, [0]);
    child.readViewModel(key).setCount(1);
    expect(counts, [0, 1]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('constructor and onLoad watches stay lazy until mounting', (
    tester,
  ) async {
    var creates = 0;
    final key = ViewModelKey(() {
      creates++;
      return _CounterModel();
    });
    final constructorChild = _EarlyWatchingComponent(key, duringLoad: false);
    final loadingChild = _EarlyWatchingComponent(key, duringLoad: true);
    final scope = ViewModelScope(children: [constructorChild, loadingChild]);
    final game = _ScopeGame([scope]);
    expect(creates, 0);
    expect(constructorChild.counts, isEmpty);

    await _mount(tester, game);
    expect(creates, 1);
    expect(constructorChild.counts, [0]);
    expect(loadingChild.counts, [0]);
    constructorChild.readViewModel(key).setCount(4);
    expect(constructorChild.counts, [0, 4]);
    expect(loadingChild.counts, [0, 4]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a throwing initial callback rolls back its listener', (
    tester,
  ) async {
    final key = ViewModelKey(_CounterModel.new);
    final child = Component();
    final game = _ScopeGame([
      ViewModelScope(children: [child]),
    ]);
    await _mount(tester, game);
    child.watchViewModel(key, (_) => throw StateError('callback failed'));

    expect(game.processLifecycleEvents, throwsStateError);
    final model = child.readViewModel(key);
    expect(model.isObserved, isFalse);

    child.watchViewModel(key, (_) {});
    game.processLifecycleEvents();
    expect(model.isObserved, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(model.listenersAtDisposal, isFalse);
  });
}

Future<void> _mount(WidgetTester tester, _ScopeGame game) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await tester.pump();
  await tester.pump();
  game.processLifecycleEvents();
}

class _CounterModel extends ViewModelBase<int, ViewModelArgs> {
  _CounterModel() : super(const ViewModelArgs(), initialState: 0);

  int initializations = 0;
  int disposals = 0;
  bool? listenersAtDisposal;

  bool get isObserved => hasListeners;

  void setCount(int count) => emit(count);

  @override
  void onInit() => initializations++;

  @override
  void dispose() {
    listenersAtDisposal = hasListeners;
    disposals++;
    super.dispose();
  }
}

class _WatchingComponent extends Component {
  _WatchingComponent(this.modelKey);

  final ViewModelKey<_CounterModel> modelKey;
  final counts = <int>[];

  @override
  void onMount() {
    super.onMount();
    watchViewModel(modelKey, (model) => counts.add(model.value));
  }
}

class _ScopeGame extends FlameGame<World> {
  _ScopeGame(List<Component> scopedChildren)
    : super(world: World(children: scopedChildren));

  @override
  void onRemove() {
    world.removeAll(world.children);
    processLifecycleEvents();
    super.onRemove();
  }
}

class _EarlyWatchingComponent extends Component {
  _EarlyWatchingComponent(this.modelKey, {required this.duringLoad}) {
    if (!duringLoad) _register();
  }

  final ViewModelKey<_CounterModel> modelKey;
  final bool duringLoad;
  final counts = <int>[];

  void _register() =>
      watchViewModel(modelKey, (model) => counts.add(model.value));

  @override
  void onLoad() {
    if (duringLoad) _register();
  }
}
