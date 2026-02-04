// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('bin/gg_test.dart tests-ts', () {
    test('should show help for tests-ts command', () async {
      final result = await Process.run(
        'dart',
        <String>[
          join('.', 'bin', 'gg_test.dart'),
          'tests-ts',
          '--help',
        ],
      );

      final stdout = result.stdout as String;

      expect(stdout, contains('Runs TypeScript tests with coverage.'));
    });
  });
}
