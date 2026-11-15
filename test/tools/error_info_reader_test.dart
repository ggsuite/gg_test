// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: lines_longer_than_80_chars

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
        '"00:07 +131 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble more complicated assembly correctly [E]',
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
        '"00:07 +131 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble more complicated assembly correctly [E]',
        '  Some stupid error',
      ]);
    });
  });

  group('extractErrorLines', () {
    test('should extract error lines from a message', () {
      final message = [
        '"00:07 +131 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble more complicated assembly correctly [E]',
        '  Invalid argument(s): Error while loading GLBs referenced in Assembly "nameCabinetLayout":',
        '  PathNotFoundException: Cannot open file, path = \'test/example_files/pexar.glb\' (OS Error: No such file or directory, errno = 2)',
        '  package:ds_assembly/src/assembly/load_glbs.dart:58:5  loadGlbs',
        '  ',
        '00:07 +131 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +132 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +133 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +134 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +135 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +136 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +137 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +138 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:07 +139 -1: test/assembly/assembly_to_glb_test.dart: Assembly to Glb builder should assemble correctly as GLTF',
        '00:08 +140 -1: loading test/base/tree_test.dart',
        '00 08 +140 -1: test/base/tree_test.dart: Tree example should work',
        '00:08 +141 -1: test/base/container_item_test.dart: ContainerItem example should work',
        '00:08 +142 -1: test/base/container_item_test.dart: ContainerItem example should work',
        '00:08 +143 -1: test/base/tree_test.dart: Tree fromComposition throws when composition has more then one root item',
        '00:08 +144 -1: test/base/tree_test.dart: Tree fromComposition throws when composition has more then one root item',
        '00:08 +145 -1: test/base/tree_test.dart: Tree fromComposition throws when composition has more then one root item',
        '00:08 +146 -1: test/base/typedefs_test.dart: Typedefs GlbData',
        '00:08 +147 -1: test/base/tree_test.dart: Tree fromComposition throws when a composition has a root - parent - child chain',
        '00:08 +148 -1: test/base/tree_test.dart: Tree item, children, hash',
        '00:08 +149 -1: test/base/tree_test.dart: Tree hash',
        '"',
      ].join('\n');

      final result = errorInfoReader.extractErrorLines(message);
      expect(result, ['lib/src/assembly/load_glbs.dart:58:5']);
    });
  });

  group('failedTests', () {
    test('returns the failed tests with what the runner printed about '
        'them', () {
      final failed = errorInfoReader.failedTests(testRunOutput);

      expect(failed.map((test) => test.name), [
        'loading test/load_fails_test.dart',
        'test/simple_base_test.dart: SimpleBase times out',
        'test/simple_base_test.dart: SimpleBase fails with a location',
      ]);

      // The line naming the test comes first, then the error.
      expect(failed[1].lines, [
        '00:00 +5 -2: test/simple_base_test.dart: SimpleBase times out [E]',
        '  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.',
        '  dart:isolate  _RawReceivePort._handleMessage',
        '',
      ]);
    });

    test('offers the error of a failed test without the line naming it and '
        'without empty lines', () {
      final failed = errorInfoReader.failedTests(testRunOutput);

      expect(failed[0].details, [
        '  Failed to load "test/load_fails_test.dart": Bad state: cannot load',
      ]);
      expect(failed[2].details, [
        '  Expected: <2>',
        '    Actual: <1>',
        '  package:matcher                  expect',
        '  test/simple_base_test.dart 31:7  main.<fn>.<fn>',
      ]);
    });

    test('does not take the summary at the end for a failed test', () {
      final failed = errorInfoReader.failedTests(testRunOutput);
      expect(
        failed.expand((test) => test.lines),
        isNot(contains('Failing tests:')),
      );
    });

    test('reads the lines of hours, skipped tests and windows line '
        'endings', () {
      final failed = errorInfoReader.failedTests(
        [
          '01:02:03 +5 ~1 -1: test/a_test.dart: A fails [E]',
          '  Bad state: a',
          '01:02:04 +5 ~1 -1: Some tests failed.',
        ].join('\r\n'),
      );

      expect(failed.single.name, 'test/a_test.dart: A fails');
      expect(failed.single.details, ['  Bad state: a']);
    });

    test('returns nothing for a run without failed tests', () {
      expect(errorInfoReader.failedTests(''), isEmpty);
      expect(
        errorInfoReader.failedTests(
          '00:00 +0: test/a_test.dart: A works\n00:00 +1: All tests passed!',
        ),
        isEmpty,
      );
    });
  });

  group('linesOutsideFailedTests', () {
    test('returns the lines that belong to no failed test', () {
      final rest = errorInfoReader.linesOutsideFailedTests(testRunOutput);

      expect(rest, [
        '00:00 +0: loading test/class_without_methods_test.dart',
        '00:00 +0 -1: test/ignore_file_test.dart: IgnoreFile should work fine',
        '00:00 +5 -1: test/simple_base_test.dart: SimpleBase times out',
        '00:00 +5 -2: test/simple_base_test.dart: SimpleBase fails with a location',
        '00:02 +5 -3: Some tests failed.',
        '',
        'Failing tests:',
        '  test/load_fails_test.dart: loading test/load_fails_test.dart',
        '  test/simple_base_test.dart: SimpleBase fails with a location',
        '  test/simple_base_test.dart: SimpleBase times out',
      ]);
    });
  });
}

// .............................................................................
/// What `dart test -r expanded` printed for a run with three failures: a
/// test file that does not load, a test that timed out and a failed
/// expectation.
const testRunOutput = '''
00:00 +0: loading test/class_without_methods_test.dart
00:00 +0 -1: loading test/load_fails_test.dart [E]
  Failed to load "test/load_fails_test.dart": Bad state: cannot load

00:00 +0 -1: test/ignore_file_test.dart: IgnoreFile should work fine
00:00 +5 -1: test/simple_base_test.dart: SimpleBase times out
00:00 +5 -2: test/simple_base_test.dart: SimpleBase times out [E]
  TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.
  dart:isolate  _RawReceivePort._handleMessage

00:00 +5 -2: test/simple_base_test.dart: SimpleBase fails with a location
00:00 +5 -3: test/simple_base_test.dart: SimpleBase fails with a location [E]
  Expected: <2>
    Actual: <1>

  package:matcher                  expect
  test/simple_base_test.dart 31:7  main.<fn>.<fn>

00:02 +5 -3: Some tests failed.

Failing tests:
  test/load_fails_test.dart: loading test/load_fails_test.dart
  test/simple_base_test.dart: SimpleBase fails with a location
  test/simple_base_test.dart: SimpleBase times out
''';

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
