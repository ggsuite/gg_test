// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  group('HasFunctionsTs', () {
    group('example', () {
      test('should work', () {
        expect(hasFunctionsTs(noFunctionExample0), isFalse);
        expect(hasFunctionsTs(noFunctionExample1), isFalse);
        expect(hasFunctionsTs(functionExample0), isTrue);
        expect(hasFunctionsTs(functionExample1), isTrue);
        expect(hasFunctionsTs(functionExample2), isTrue);
        expect(hasFunctionsTs(getterExample), isTrue);
        expect(hasFunctionsTs(setterExample), isTrue);
      });
    });
  });
}

const noFunctionExample0 = '''
enum Example {
  A = 'A',
  B = 'B',
}
''';

const noFunctionExample1 = '''
interface Example {
  a: number;
  b: number;
}
''';

const functionExample0 = '''
class Example {
  foo(): number {
    return 42;
  }
}
''';

const functionExample1 = '''
export function foo(): number {
  return 42;
}
''';

const functionExample2 = '''
const foo = (): number => 42;
''';

const getterExample = '''
class Example {
  private _value = 0;

  get value(): number {
    return this._value;
  }
}
''';

const setterExample = '''
class Example {
  private _value = 0;

  set value(v: number) {
    this._value = v;
  }
}
''';
