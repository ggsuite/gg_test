// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/src/tools/error_files.dart';
import 'package:test/test.dart';

void main() {
  group('errorLines(message)', () {
    group('should return', () {
      group('an empty array', () {
        test('when message is null', () {
          final result = errorFiles(null);
          expect(result, isEmpty);
        });
      });

      group('a list of vscode compatible error lines,', () {
        test('for dart analyze output', () {
          final result = errorFiles(dartAnalyzeOutput);
          expect(result, ['lib/src/tools/error_lines.dart:7:14']);
        });

        test('for dart format output', () {
          final result = errorFiles(dartFormatOutput);
          expect(result, ['sub/test1.dart', 'test.dart']);
        });
      });
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
