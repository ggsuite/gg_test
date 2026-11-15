// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_test/gg_test.dart';

/// A test that failed, as the test runner printed it.
class FailedTest {
  /// Constructor
  const FailedTest({required this.name, required this.lines});

  /// The name of the test as the runner prints it, e.g.
  /// `test/foo_test.dart: Foo works`, or `loading test/foo_test.dart` for
  /// a test file that could not be loaded.
  final String name;

  /// Everything the runner printed about the failure: the line naming the
  /// test first, then the error and its stack trace.
  final List<String> lines;

  /// The error and its stack trace: [lines] without the line naming the
  /// test and without empty lines.
  List<String> get details =>
      lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
}

/// Reads error information from a given error string.
class ErrorInfoReader {
  // ...........................................................................
  /// Returns the tests that failed according to [output], which is what
  /// `dart test` or `flutter test` print with the expanded reporter.
  ///
  /// That reporter writes one line whenever a test starts or ends,
  /// `00:07 +131 -1: <name>`, and marks the line of a failed test with
  /// `[E]`. What follows up to the next such line belongs to the failure.
  List<FailedTest> failedTests(String output) => _split(output).failed;

  // ...........................................................................
  /// Returns the lines of [output] that [failedTests] assigns to no failed
  /// test.
  List<String> linesOutsideFailedTests(String output) => _split(output).other;

  // ...........................................................................
  /// Returns all Vscode formatted error lines from the given error string.
  List<String> filePathes(String? error) {
    if (error == null || error.isEmpty) {
      return <String>[];
    }
    error = makeVscodeCompatible(error);
    return _extractErrorLines(error);
  }

  // ...........................................................................
  /// Replaces error lines in the given message with vscode compatible ones.
  String makeVscodeCompatible(String message) {
    var errorLines = _extractErrorLines(message);
    var result = message;

    for (var errorLine in errorLines) {
      var compatibleErrorLine = _makeErrorLineVscodeCompatible(errorLine);
      result = result.replaceAll(errorLine, compatibleErrorLine);
    }

    return result;
  }

  /// Removes unneccesary information from test output
  List<String> cleanupTestErrors(List<String> lines) {
    // Split all lines by \n and merge the result together
    final splittedLines = lines
        .map((line) => line.split('\n'))
        .expand((lines) => lines)
        .toList();

    // Remove 00:00 at the beginning of each line
    var result = splittedLines.where((line) {
      final additionalLines = RegExp(r'^\d\d:[\d:\s+-]+');
      var isOk =
          (!additionalLines.hasMatch(line) || line.contains('[E]')) &&
          line.trim().isNotEmpty &&
          !line.startsWith(RegExp(r'\s*package:matcher'));

      return isOk;
    });

    // Remove repetition of the error line
    result = result.where((line) => !line.contains('main.<fn>.<fn>')).toList();

    return result.toList();
  }

  // ...........................................................................
  /// Returns the error lines from a given message.
  List<String> extractErrorLines(String message) {
    // Regular expression to match file paths and line numbers

    // coverage:ignore-start
    RegExp exp = RegExp(r'(test|src)[\\/][\\/\w]+\.dart[\s:]*\d+:\d+');
    // coverage:ignore-end

    final matches = exp.allMatches(message);
    final result = <String>[];

    if (matches.isEmpty) {
      return result;
    }

    for (final match in matches) {
      var matchedString = match.group(0) ?? '';
      matchedString = matchedString.replaceFirst(RegExp(r'^src/'), 'lib/src/');
      result.add(matchedString);
    }

    return result;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  /// The mark the expanded reporter puts behind the name of a failed test.
  static const _failedMark = ' [E]';

  /// The line the expanded reporter writes when a test starts or ends: the
  /// time, the number of passed, skipped and failed tests, then the name.
  // coverage:ignore-start
  static final _progressLine = RegExp(
    r'^\d+:\d\d(?::\d\d)? \+\d+(?: ~\d+)?(?: -\d+)?: (.*)$',
  );
  // coverage:ignore-end

  // ...........................................................................
  /// Splits the output of a test run into the failed tests and the lines
  /// that belong to none of them.
  ({List<FailedTest> failed, List<String> other}) _split(String output) {
    final failed = <FailedTest>[];
    final other = <String>[];

    // The failed test the current line belongs to
    String? name;
    var lines = <String>[];

    void closeFailedTest() {
      if (name != null) {
        failed.add(FailedTest(name: name!, lines: lines));
      }
      name = null;
      lines = <String>[];
    }

    for (final line in const LineSplitter().convert(output)) {
      final progress = _progressLine.firstMatch(line);

      // Not the start or end of a test: belongs to the failed test above it
      if (progress == null) {
        (name == null ? other : lines).add(line);
        continue;
      }

      closeFailedTest();
      final text = progress.group(1)!;
      if (text.endsWith(_failedMark)) {
        name = text.substring(0, text.length - _failedMark.length);
        lines.add(line);
      } else {
        other.add(line);
      }
    }
    closeFailedTest();

    return (failed: failed, other: other);
  }

  // ...........................................................................
  List<String> _extractErrorLines(String message) {
    // Regular expression to match file paths and line numbers

    // coverage:ignore-start
    final exp = RegExp(r'[\\/\w]+\.dart(?:[\s:]*\d+:\d+)?');
    // coverage:ignore-end
    final matches = exp.allMatches(message.os);
    final result = <String>[];

    if (matches.isEmpty) {
      return result;
    }

    for (final match in matches) {
      var matchedString = match.group(0) ?? '';
      result.add(matchedString);
    }

    return result;
  }

  // ...........................................................................
  String _makeErrorLineVscodeCompatible(String errorLine) {
    errorLine = errorLine.replaceAll(':', ' ');
    var parts = errorLine.split(' ');
    if (parts.length != 3) {
      return errorLine;
    }

    var filePath = parts[0];
    var lineNumber = parts[1];
    var columnNumber = parts[2];

    return '$filePath:$lineNumber:$columnNumber'.os;
  }
}
