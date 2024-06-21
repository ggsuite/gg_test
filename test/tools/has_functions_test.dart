// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  group('HasFunctions', () {
    group('example', () {
      test('should work', () {
        expect(hasFunctions(noFunctionExample0), isFalse);
        expect(hasFunctions(noFunctionExample1), isFalse);
        expect(hasFunctions(functionExample0), isTrue);
        expect(hasFunctions(functionExample1), isTrue);
        expect(hasFunctions(functionExample2), isTrue);
        expect(hasFunctions(getterExample), isTrue);
        expect(hasFunctions(setterExample), isTrue);
      });
    });
  });
}

const noFunctionExample0 = '''
enum Example {
  a,
  b,
  c,
}
''';

const noFunctionExample1 = '''
class Example {
  final int a;
  final int b;
  final int c;
}
''';

const functionExample0 = '''
class Example {
  int foo() => 42;
}
''';

const functionExample1 = '''
int foo() => 42;
''';

const functionExample2 = '''
int foo(){
  return 42;
};
''';

const getterExample = '''
class Example {
  int get foo => 42;
}
''';

const setterExample = '''
class Example {
  void set foo(int x) => this.k = x;
}
''';
