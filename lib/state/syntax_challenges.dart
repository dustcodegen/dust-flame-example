class CodePart {
  const CodePart(this.text, {this.before = ''});

  final String text;
  final String before;
}

class SyntaxChallenge {
  const SyntaxChallenge({
    required this.language,
    required this.title,
    required this.parts,
    required this.distractors,
  });

  final String language;
  final String title;
  final List<CodePart> parts;
  final List<String> distractors;

  String get source => parts.map((part) => '${part.before}${part.text}').join();
}

const syntaxChallenges = [
  SyntaxChallenge(
    language: 'Dart',
    title: 'Say hello',
    parts: [
      CodePart('void'),
      CodePart('main', before: ' '),
      CodePart('('),
      CodePart(')'),
      CodePart('{', before: ' '),
      CodePart('print', before: '\n  '),
      CodePart('('),
      CodePart('"Hi"'),
      CodePart(')'),
      CodePart(';'),
      CodePart('}', before: '\n'),
    ],
    distractors: ['fn', 'println!', 'let', '[', ']', ':', '=>'],
  ),
  SyntaxChallenge(
    language: 'Rust',
    title: 'Say hello',
    parts: [
      CodePart('fn'),
      CodePart('main', before: ' '),
      CodePart('('),
      CodePart(')'),
      CodePart('{', before: ' '),
      CodePart('println!', before: '\n  '),
      CodePart('('),
      CodePart('"Hi"'),
      CodePart(')'),
      CodePart(';'),
      CodePart('}', before: '\n'),
    ],
    distractors: ['void', 'print', 'final', '[', ']', ':', '=>'],
  ),
  SyntaxChallenge(
    language: 'Dart',
    title: 'Add two numbers',
    parts: [
      CodePart('void'),
      CodePart('main', before: ' '),
      CodePart('('),
      CodePart(')'),
      CodePart('{', before: ' '),
      CodePart('final', before: '\n  '),
      CodePart('total', before: ' '),
      CodePart('=', before: ' '),
      CodePart('2', before: ' '),
      CodePart('+', before: ' '),
      CodePart('3', before: ' '),
      CodePart(';'),
      CodePart('print', before: '\n  '),
      CodePart('('),
      CodePart('total'),
      CodePart(')'),
      CodePart(';'),
      CodePart('}', before: '\n'),
    ],
    distractors: ['fn', 'println!', 'let', '[', ']', ':', '-'],
  ),
  SyntaxChallenge(
    language: 'Rust',
    title: 'Add two numbers',
    parts: [
      CodePart('fn'),
      CodePart('main', before: ' '),
      CodePart('('),
      CodePart(')'),
      CodePart('{', before: ' '),
      CodePart('let', before: '\n  '),
      CodePart('total', before: ' '),
      CodePart('=', before: ' '),
      CodePart('2', before: ' '),
      CodePart('+', before: ' '),
      CodePart('3', before: ' '),
      CodePart(';'),
      CodePart('println!', before: '\n  '),
      CodePart('('),
      CodePart('"{}"'),
      CodePart(','),
      CodePart('total', before: ' '),
      CodePart(')'),
      CodePart(';'),
      CodePart('}', before: '\n'),
    ],
    distractors: ['void', 'print', 'final', '[', ']', ':', '-'],
  ),
];
