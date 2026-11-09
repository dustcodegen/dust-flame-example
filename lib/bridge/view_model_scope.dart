import 'package:dust_flutter/state.dart';
import 'package:flame/components.dart';

/// A stable generated identity and factory for one lazily created ViewModel.
final class ViewModelKey<VM extends ViewModelBase<Object?, ViewModelArgs>> {
  const ViewModelKey(this.create);

  final VM Function() create;
}

typedef _AnyViewModel = ViewModelBase<Object?, ViewModelArgs>;

// Pending children are absent from Component.children until they mount.
final _watchers = Expando<Map<Object, Component>>('ViewModel watchers');

/// Owns the ViewModels first requested by components in this subtree.
class ViewModelScope extends Component {
  ViewModelScope({super.children, super.key});

  final _models = <ViewModelKey<_AnyViewModel>, _AnyViewModel>{};

  VM _read<VM extends ViewModelBase<Object?, ViewModelArgs>>(
    ViewModelKey<VM> key,
  ) {
    if (!isMounted || isRemoving) {
      throw StateError('Read ViewModels from a mounted ViewModelScope.');
    }
    final existing = _models[key];
    if (existing != null) return existing as VM;

    final model = key.create();
    _models[key] = model;
    scheduleMicrotask(() async {
      if (!isMounted || isRemoving || !identical(_models[key], model)) return;
      try {
        await model.init();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Flame ViewModel scope',
            context: ErrorDescription('$VM initialization failed'),
          ),
        );
      }
    });
    return model;
  }

  @override
  void onRemove() {
    final models = _models.values.toList().reversed;
    _models.clear();
    for (final model in models) {
      model.dispose();
    }
    super.onRemove();
  }
}

/// Typed lookup and lifecycle-bound state observation for Flame components.
extension ComponentViewModels on Component {
  VM readViewModel<VM extends ViewModelBase<Object?, ViewModelArgs>>(
    ViewModelKey<VM> key,
  ) => _findScope(this)._read(key);

  /// Observes the current value and later changes while this component mounts.
  ///
  /// Registration is safe in constructors and loading hooks.
  /// Calling this again with the same key replaces this component's callback.
  void watchViewModel<VM extends ViewModelBase<Object?, ViewModelArgs>>(
    ViewModelKey<VM> key,
    void Function(VM viewModel) onChanged,
  ) {
    final watchers = _watchers[this] ??= <Object, Component>{};
    final existing = watchers[key] as _ViewModelWatcher<VM>?;
    if (existing != null) {
      existing.replaceCallback(onChanged);
      if (existing.parent == null) add(existing);
      return;
    }
    final watcher = _ViewModelWatcher(key, onChanged);
    watchers[key] = watcher;
    add(watcher);
  }
}

ViewModelScope _findScope(Component component) {
  final scope = component.findParent<ViewModelScope>(includeSelf: true);
  if (scope == null) {
    throw StateError('No ViewModelScope surrounds ${component.runtimeType}.');
  }
  return scope;
}

class _ViewModelWatcher<VM extends ViewModelBase<Object?, ViewModelArgs>>
    extends Component {
  _ViewModelWatcher(this.modelKey, this._onChanged);

  final ViewModelKey<VM> modelKey;
  void Function(VM viewModel) _onChanged;
  VM? _model;

  void replaceCallback(void Function(VM viewModel) callback) {
    final previous = _onChanged;
    _onChanged = callback;
    try {
      if (_model != null) _notify();
    } catch (_) {
      _onChanged = previous;
      rethrow;
    }
  }

  @override
  void onMount() {
    super.onMount();
    final model = readViewModel(modelKey);
    _model = model;
    model.addListener(_notify);
    try {
      _notify();
    } catch (_) {
      model.removeListener(_notify);
      _model = null;
      rethrow;
    }
  }

  void _notify() {
    final model = _model;
    if (model != null) _onChanged(model);
  }

  @override
  void onRemove() {
    _model?.removeListener(_notify);
    _model = null;
    super.onRemove();
  }
}
