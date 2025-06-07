// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  final errorInfoReader = ErrorInfoReader();

  group('errorLines(message)', () {
    group('should return', () {
      group('an empty array', () {
        test('when message is null', () {
          final result = errorInfoReader.filePathes(null);
          expect(result, isEmpty);
        });
      });

      group('a list of vscode compatible error lines,', () {
        test('for dart analyze output', () {
          final result = errorInfoReader.filePathes(dartAnalyzeOutput);
          expect(result, ['lib/src/tools/error_lines.dart:7:14'.os]);
        });

        test('for dart format output', () {
          final result = errorInfoReader.filePathes(dartFormatOutput);
          expect(result, ['sub/test1.dart'.os, 'test.dart']);
        });
      });
    });
  });

  group('cleanupTestErrors', () {
    test('removes not needed information from error strings', () {
      final message = [
        '00:00 +0: test/gg_console_colors_test.dart: GgConsoleColors() Please remove this test',
        '00:00 +0 -1: test/vscode/launch_json_test.dart: .vscode/launch.json pathes in launch.json',
        '  Some stupid error',
        '  package:matcher                        fail',
        '  test/gg_console_colors_test.dart:13:7  main.<fn>.<fn>',
        '  ',
        '00:00 +1 -1: test/gg_console_colors_test.dart: GgConsoleColors() printExample() should print a list of example colors',
        '00:00 +2 -1: test/gg_console_colors_test.dart: GgConsoleColors() printExample() should reset colors to the outer one',
        '00:00 +3 -1: Some tests failed.',
      ];

      final cleaned = ErrorInfoReader().cleanupTestErrors(message);
      expect(cleaned, [
        '  Some stupid error',
      ]);
    });
  });
}

// .............................................................................
const dartAnalyzeOutput = '''
Analyzing gg_check...

   info - lib/src/tools/error_lines.dart:7:14 - Missing documentation for a public member. Try adding documentation for the member. - public_member_api_docs

1 issue found.
''';

const dartFormatOutput = '''
Formatted sub/test1.dart
Formatted test.dart
Formatted 2 files (2 changed) in 0.06 seconds.
''';
