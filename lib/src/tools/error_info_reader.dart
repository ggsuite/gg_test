// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_test/gg_test.dart';

/// Reads error information from a given error string.
class ErrorInfoReader {
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
    final splittedLines =
        lines.map((line) => line.split('\n')).expand((lines) => lines).toList();

    // Remove 00:00 at the beginning of each line
    var result = splittedLines.where((line) {
      final additionalLines = RegExp(r'^\d\d:[\d:\s+-]+');
      var isOk = !additionalLines.hasMatch(line) &&
          line.trim().isNotEmpty &&
          !line.startsWith(RegExp(r'\s*package:matcher'));

      return isOk;
    });

    // Remove repetition of the error line
    result = result.where((line) => !line.contains('main.<fn>.<fn>')).toList();

    return result.toList();
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  List<String> _extractErrorLines(String message) {
    // Regular expression to match file paths and line numbers

    // coverage:ignore-start
    final exp = Platform.pathSeparator == r'\'
        ? RegExp(r'[\\\w]+\.dart(?:[\s:]*\d+:\d+)?')
        : RegExp(r'[\/\w]+\.dart(?:[\s:]*\d+:\d+)?');
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
