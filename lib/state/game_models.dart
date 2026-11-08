import 'package:dust_dart/derive.dart';
import 'package:dust_flutter/state.dart';

part 'game_models.g.dart';

@Derive([Eq()])
class CoinsState with _$CoinsState {
  const CoinsState({this.count = 0});

  final int count;
}

@ViewModel(state: CoinsState)
class CoinsViewModel extends $CoinsViewModel {
  CoinsViewModel() : super(const ViewModelArgs());

  void collect() => emit(CoinsState(count: state.count + 1));
}

@Derive([Eq()])
class HealthState with _$HealthState {
  const HealthState({this.lives = 3});

  final int lives;
}

@ViewModel(state: HealthState)
class HealthViewModel extends $HealthViewModel {
  HealthViewModel() : super(const ViewModelArgs());

  void hit() {
    if (state.lives > 0) emit(HealthState(lives: state.lives - 1));
  }
}

@Derive([Eq()])
class LevelState with _$LevelState {
  const LevelState({this.number = 1});

  final int number;
}

@ViewModel(state: LevelState)
class LevelViewModel extends $LevelViewModel {
  LevelViewModel() : super(const ViewModelArgs());

  void advance() => emit(LevelState(number: state.number + 1));
}
