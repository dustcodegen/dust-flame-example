import 'package:dust_dart/derive.dart';
import 'package:dust_flutter/state.dart';

import 'syntax_challenges.dart';

part 'game_models.g.dart';

@Derive([Eq()])
class ScoreState with _$ScoreState {
  const ScoreState({this.points = 0});

  final int points;
}

@ViewModel(state: ScoreState)
class ScoreViewModel extends $ScoreViewModel {
  ScoreViewModel() : super(const ViewModelArgs());

  void addPoint() => emit(ScoreState(points: state.points + 1));
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
class ChallengeState with _$ChallengeState {
  const ChallengeState({this.round = 0, this.matched = 0});

  final int round;
  final int matched;

  SyntaxChallenge get challenge =>
      syntaxChallenges[round % syntaxChallenges.length];
  bool get complete => matched == challenge.parts.length;
  String? get expectedToken => complete ? null : challenge.parts[matched].text;
}

@ViewModel(state: ChallengeState)
class ChallengeViewModel extends $ChallengeViewModel {
  ChallengeViewModel() : super(const ViewModelArgs());

  bool accept(String token) {
    if (state.complete || token != state.expectedToken) return false;
    emit(ChallengeState(round: state.round, matched: state.matched + 1));
    return true;
  }

  void next() {
    if (state.complete) emit(ChallengeState(round: state.round + 1));
  }
}
