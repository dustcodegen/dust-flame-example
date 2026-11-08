import 'package:flutter_test/flutter_test.dart';

import '../tool/generate.dart';

void main() {
  test('discovers annotated classes and emits stable typed Flame helpers', () {
    const source = '''
@ViewModel(state: State)
class ZebraViewModel {
  ZebraViewModel({int optional = 1});
}
// @ViewModel must not register this class.
class IgnoredViewModel {}
@state.ViewModel(state: State)
class AppleViewModel {}
''';
    final output = generateBindings(source);
    expect(output, generateBindings(source));
    expect(output, contains('ViewModelKey<AppleViewModel>'));
    expect(output, contains('ViewModelKey(AppleViewModel.new)'));
    expect(output, contains('AppleViewModel readAppleViewModel()'));
    expect(
      output,
      contains(
        'void watchAppleViewModel(void Function(AppleViewModel) callback)',
      ),
    );
    expect(output, contains('watchViewModel(_appleViewModelKey, callback)'));
    expect(output, isNot(contains('IgnoredViewModel')));
    expect(
      output.indexOf('ViewModelKey<AppleViewModel>'),
      lessThan(output.indexOf('ViewModelKey<ZebraViewModel>')),
    );
  });

  final invalidDeclarations = <String, String>{
    'class Required { Required(int id); }': 'no required parameters',
    'class Named { Named({required int id}); }': 'no required parameters',
    'class FactoryOnly { FactoryOnly.named(); }': 'unnamed constructor',
    'abstract class AbstractModel {}': 'must be concrete',
    'sealed class SealedModel {}': 'must be concrete',
    'class Generic<T> {}': 'must not have type parameters',
    'class _Private {}': 'must be public',
    'enum Model { value }': 'require a concrete class',
  };
  for (final entry in invalidDeclarations.entries) {
    test('rejects unsupported declaration ${entry.key}', () {
      expect(
        () => generateBindings('@ViewModel()\n${entry.key}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(entry.value),
          ),
        ),
      );
    });
  }

  test('reports syntax errors and a missing annotated model', () {
    expect(
      () => generateBindings('@ViewModel() class Broken {'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('lib/state/game_models.dart:1:'),
        ),
      ),
    );
    expect(
      () => generateBindings('class Plain {}'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('No @ViewModel classes found'),
        ),
      ),
    );
  });

  test('rejects model names that would produce duplicate keys', () {
    expect(
      () => generateBindings('''
@ViewModel() class Example {}
@ViewModel() class example {}
'''),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('duplicate keys'),
        ),
      ),
    );
  });
}
