// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorInfoReaderTs', () {
    final reader = ErrorInfoReaderTs();

    test('filePathes returns empty list for null', () {
      expect(reader.filePathes(null), isEmpty);
    });

    test('filePathes extracts TypeScript paths from Jest output', () {
      final message = [
        'FAIL test/simple_base.spec.ts',
        '  ● simple_base › should fail',
        '',
        '    Expected: 2',
        '    Received: 1',
        '',
        '      5 |   return 1;',
        '      6 | }',
        '    > 7 | export function bar(): number {',
        '        | ^',
        '      8 |   return 2;',
        '',
        '      at Object.<anonymous> (src/simple_base.ts:7:1)',
      ].join('\n');

      final paths = reader.filePathes(message);

      expect(paths, ['src/simple_base.ts:7:1'.os]);
    });

    test('extractErrorLines finds multiple entries', () {
      final message = [
        'FAIL test/simple_base.spec.ts',
        '  at Object.<anonymous> (src/simple_base.ts:7:1)',
        '  at Object.<anonymous> (test/simple_base.spec.ts:10:3)',
      ].join('\n');

      final result = reader.extractErrorLines(message)..sort();

      expect(result, [
        'src/simple_base.ts:7:1'.os,
        'test/simple_base.spec.ts:10:3'.os,
      ]);
    });

    test('cleanupTestErrors removes noise from Jest output', () {
      final lines = <String>[
        'PASS test/ok.spec.ts',
        'FAIL test/simple_base.spec.ts',
        '  ● simple_base › should fail',
        '    Expected: 2',
        '    Received: 1',
        '      at Object.<anonymous> (src/simple_base.ts:7:1)',
        '      at Object.asyncJestTest (node_modules/jest-jasmine2/build/jasmineAsyncInstall.js:100:12)',
        'Test Suites: 1 failed, 1 total',
        'Tests:       1 failed, 1 total',
      ];

      final cleaned = reader.cleanupTestErrors(lines);

      expect(cleaned, isNot(contains(contains('PASS test/ok.spec.ts'))));
      expect(cleaned, isNot(contains(contains('node_modules'))));
      expect(
        cleaned.any((l) => l.contains('FAIL test/simple_base.spec.ts')),
        isTrue,
      );
      expect(
        cleaned.any((l) => l.contains('simple_base › should fail')),
        isTrue,
      );
      expect(cleaned.any((l) => l.contains('src/simple_base.ts:7:1')), isTrue);
    });
  });
}
