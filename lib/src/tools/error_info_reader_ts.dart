// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';

/// Reads error information from TypeScript / Node / Jest error output.
///
/// This helper focuses on extracting file paths with line and column
/// information from typical stack traces and making them VSCode
/// compatible. It also provides utilities to clean noisy test output.
class ErrorInfoReaderTs {
  /// Returns all VSCode formatted error lines from the given [error]
  /// string.
  List<String> filePathes(String? error) {
    if (error == null || error.isEmpty) {
      return <String>[];
    }

    final compatible = makeVscodeCompatible(error);
    return extractErrorLines(compatible);
  }

  /// Replaces error lines in the given [message] with VSCode compatible
  /// ones where necessary.
  ///
  /// Currently this method mainly normalizes path separators and ensures
  /// that file references are in the form `path/to/file.ts:line:column`.
  String makeVscodeCompatible(String message) {
    // The default Jest / Node stack traces are already compatible, so we
    // primarily normalize path separators here.
    return message.os;
  }

  /// Removes not needed information from TypeScript test error strings
  /// (e.g. Jest output).
  ///
  /// Typical noise includes summary lines ("PASS", "Test Suites:" etc.)
  /// and stack frames originating from `node_modules` or Node internals.
  List<String> cleanupTestErrors(List<String> lines) {
    final splittedLines = lines
        .map((line) => line.split('\n'))
        .expand((element) => element)
        .toList();

    final result = <String>[];

    for (final line in splittedLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      // Filter generic Jest summary lines.
      if (trimmed.startsWith('PASS ')) {
        continue;
      }
      if (trimmed.startsWith('Test Suites:')) {
        continue;
      }
      if (trimmed.startsWith('Tests:')) {
        continue;
      }
      if (trimmed.startsWith('Snapshots:')) {
        continue;
      }
      if (trimmed.startsWith('Time:')) {
        continue;
      }
      if (trimmed.startsWith('Ran all test suites')) {
        continue;
      }

      // Keep FAIL lines, they usually contain important context.

      // Filter stack frames from node internals or dependencies.
      if (trimmed.startsWith('at ')) {
        if (trimmed.contains('node_modules') ||
            trimmed.contains('node:internal') ||
            trimmed.contains('internal/')) {
          continue;
        }
      }

      result.add(line);
    }

    return result;
  }

  /// Returns error lines from the given [message].
  ///
  /// The result contains normalized paths (using the OS-specific
  /// separator) in the form `src/foo.ts:10:5` or `test/bar.spec.ts:1:2`.
  List<String> extractErrorLines(String message) {
    final exp = RegExp(
      r'((?:src|test)[\\/][^:\s)]+\.ts):(\d+):(\d+)',
      multiLine: true,
    );

    final matches = exp.allMatches(message);
    final result = <String>{};

    for (final match in matches) {
      final path = match.group(1) ?? '';
      final line = match.group(2) ?? '';
      final column = match.group(3) ?? '';
      if (path.isEmpty || line.isEmpty || column.isEmpty) {
        continue;
      }
      final normalized = '$path:$line:$column'.os;
      result.add(normalized);
    }

    return result.toList();
  }
}
