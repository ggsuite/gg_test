// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('bin/gg_test.dart', () {
    // #########################################################################

    test('should be executable', () async {
      // Execute bin/gg_test.dart and check if it prints help
      final result = await Process.run('dart', [
        join('.', 'bin', 'gg_test.dart'),
        '--help',
      ]);

      final expectedMessages = ['Execute tests with coverage.', 'dart test'];

      final stdout = result.stdout as String;

      for (final msg in expectedMessages) {
        expect(stdout, contains(msg));
      }
    });
  });
}
