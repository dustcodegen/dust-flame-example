import 'package:dust_flame_example/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'challenge accepts only the next token and retains a completed code',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      expect(model.state.started, isFalse);
      expect(model.accept(model.state.challenge.parts.first.text), isFalse);
      expect(model.state.matched, 0);
      model.next();
      expect(model.state.round, 0);
      model.start();
      expect(model.state.started, isTrue);
      expect(model.accept('fn'), isFalse);
      for (final part in model.state.challenge.parts) {
        expect(model.accept(part.text), isTrue);
      }
      expect(model.state.complete, isTrue);
      expect(model.state.expectedToken, isNull);
      expect(model.accept('}'), isFalse);
      model.next();
      expect(model.state.round, 1);
      expect(model.state.matched, 0);
      expect(model.state.started, isFalse);
      expect(model.state.challenge.language, 'Rust');
    },
  );

  test(
    'repeated start retains progress and emits only the first transition',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      var emissions = 0;
      model.addListener(() => emissions++);

      model.start();
      expect(emissions, 1);
      model.start();
      expect(emissions, 1);
      expect(model.accept(model.state.expectedToken!), isTrue);
      expect(emissions, 2);
      model.start();
      model.next();
      expect(emissions, 2);
      expect(model.state.started, isTrue);
      expect(model.state.round, 0);
      expect(model.state.matched, 1);
    },
  );

  test(
    'ready language selection chooses first examples without duplicate emits',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      var emissions = 0;
      model.addListener(() => emissions++);

      expect(model.chooseLanguage('Go'), isTrue);
      expect(model.state.challenge.language, 'Go');
      expect(
        model.state.challenge.source,
        'package main\nfunc main() {\n  println("Hi")\n}',
      );
      expect(model.state.started, isFalse);
      expect(model.state.matched, 0);
      expect(emissions, 1);
      expect(model.chooseLanguage('Go'), isTrue);
      expect(emissions, 1);

      expect(model.chooseLanguage('Python'), isTrue);
      expect(model.state.challenge.source, 'print("Hi")');
      expect(model.state.started, isFalse);
      expect(emissions, 2);
      expect(model.chooseLanguage('Dart'), isTrue);
      expect(model.state.round, 0);
      expect(model.state.challenge.title, 'Say hello');
      expect(emissions, 3);
    },
  );

  test('invalid language selection preserves ready state without emitting', () {
    final model = ChallengeViewModel();
    addTearDown(model.dispose);
    model.chooseLanguage('Go');
    final before = model.state;
    var emissions = 0;
    model.addListener(() => emissions++);

    expect(model.chooseLanguage('Ruby'), isFalse);
    expect(model.state, same(before));
    expect(emissions, 0);
  });

  test(
    'language selection is locked until an active or completed round advances',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      model.start();
      model.accept(model.state.expectedToken!);
      final active = model.state;
      var emissions = 0;
      model.addListener(() => emissions++);
      expect(model.chooseLanguage('Python'), isFalse);
      expect(model.state, same(active));
      expect(emissions, 0);

      while (!model.state.complete) {
        model.accept(model.state.expectedToken!);
      }
      final completed = model.state;
      emissions = 0;
      expect(model.chooseLanguage('Go'), isFalse);
      expect(model.state, same(completed));
      expect(emissions, 0);

      model.next();
      expect(model.state.started, isFalse);
      expect(model.chooseLanguage('Python'), isTrue);
      expect(model.state.challenge.language, 'Python');
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
    expect(challenge.chooseLanguage('Go'), isTrue);
    expect(health.state.lives, 0);
    expect(score.state.points, 1);
  });

  test(
    'language packs reconstruct exact source and provide distinct choices',
    () {
      const expectedSources = [
        'void main() {\n  print("Hi");\n}',
        'fn main() {\n  println!("Hi");\n}',
        'print("Hi")',
        'console.log("Hi");',
        'package main\nfunc main() {\n  println("Hi")\n}',
        "SELECT 'Hi' AS greeting;",
        'void main() {\n  final total = 2 + 3;\n  print(total);\n}',
        'fn main() {\n  let total = 2 + 3;\n  println!("{}", total);\n}',
      ];
      expect(
        syntaxChallenges.map((challenge) => challenge.source),
        expectedSources,
      );
      expect(syntaxChallenges.map((challenge) => challenge.language).toSet(), {
        'Dart',
        'Rust',
        'Python',
        'JavaScript',
        'Go',
        'SQL',
      });
      for (final challenge in syntaxChallenges) {
        expect(challenge.parts, isNotEmpty);
        expect(challenge.parts.every((part) => part.text.isNotEmpty), isTrue);
        expect(
          challenge.distractors.every((token) => token.trim().isNotEmpty),
          isTrue,
        );
        expect(
          challenge.distractors.toSet(),
          hasLength(challenge.distractors.length),
        );
        for (final part in challenge.parts) {
          expect(
            challenge.distractors.where((token) => token != part.text).toSet(),
            hasLength(greaterThanOrEqualTo(2)),
          );
        }
      }
    },
  );

  test(
    'each language completes in order and the next round wraps the catalog',
    () {
      final model = ChallengeViewModel();
      addTearDown(model.dispose);
      for (final challenge in syntaxChallenges) {
        expect(model.state.challenge, same(challenge));
        expect(model.state.started, isFalse);
        model.start();
        final assembled = StringBuffer();
        for (final part in challenge.parts) {
          expect(model.accept(part.text), isTrue);
          assembled.write('${part.before}${part.text}');
        }
        expect(assembled.toString(), challenge.source);
        expect(model.state.complete, isTrue);
        model.next();
        expect(model.state.started, isFalse);
      }
      expect(model.state.round, syntaxChallenges.length);
      expect(model.state.challenge, same(syntaxChallenges.first));
      expect(model.state.matched, 0);
      expect(model.state.started, isFalse);
    },
  );

  test('an authored token preserves Unicode and whitespace exactly', () {
    const challenge = SyntaxChallenge(
      language: 'JavaScript',
      title: 'Unicode string',
      parts: [
        CodePart('const'),
        CodePart('café', before: ' '),
        CodePart('=', before: ' '),
        CodePart('"e\u0301 🌍"', before: '\n\n\t'),
        CodePart(';'),
      ],
      distractors: ['let', ':', '-'],
    );
    expect(challenge.source, 'const café =\n\n\t"e\u0301 🌍";');
    expect(challenge.parts[3].text, '"e\u0301 🌍"');
  });
}
