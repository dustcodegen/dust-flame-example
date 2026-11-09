import 'package:dust_flame_example/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'challenge accepts only the next token and retains a completed code',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      expect(model.accept('fn'), isFalse);
      expect(model.state.matched, 0);
      model.next();
      expect(model.state.round, 0);
      for (final part in model.state.challenge.parts) {
        expect(model.accept(part.text), isTrue);
      }
      expect(model.state.complete, isTrue);
      expect(model.state.expectedToken, isNull);
      expect(model.accept('}'), isFalse);
      model.next();
      expect(model.state.round, 1);
      expect(model.state.matched, 0);
      expect(model.state.challenge.language, 'Rust');
    },
  );

  test('score, health, and challenge remain independent', () {
    final score = ScoreViewModel();
    final health = HealthViewModel();
    final challenge = ChallengeViewModel();
    addTearDown(score.dispose);
    addTearDown(health.dispose);
    addTearDown(challenge.dispose);
    score.addPoint();
    expect(health.state.lives, 3);
    expect(challenge.state.matched, 0);
    for (var i = 0; i < 5; i++) {
      health.hit();
    }
    expect(health.state.lives, 0);
    expect(score.state.points, 1);
  });

  test('challenge sources preserve full language syntax', () {
    expect(syntaxChallenges[0].source, 'void main() {\n  print("Hi");\n}');
    expect(syntaxChallenges[1].source, 'fn main() {\n  println!("Hi");\n}');
    for (final challenge in syntaxChallenges) {
      expect(challenge.parts.every((part) => part.text.isNotEmpty), isTrue);
      expect(challenge.distractors.toSet().length, greaterThanOrEqualTo(3));
    }
  });
}
