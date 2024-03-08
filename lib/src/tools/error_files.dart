// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Returns all Vscode formatted error lines from the given error string.
List<String> errorFiles(String? error) {
  if (error == null || error.isEmpty) {
    return <String>[];
  }
  error = makeErrorLinesInMessageVscodeCompatible(error);
  return _extractErrorLines(error);
}

// .............................................................................
List<String> _extractErrorLines(String message) {
  // Regular expression to match file paths and line numbers
  // RegExp exp = RegExp(r'[\/\w]+\.dart[\s:]*\d+:\d+');
  final exp = RegExp(r'[\/\w]+\.dart(?:[\s:]*\d+:\d+)?');
  final matches = exp.allMatches(message);
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

// .............................................................................
String _makeErrorLineVscodeCompatible(String errorLine) {
  errorLine = errorLine.replaceAll(':', ' ');
  var parts = errorLine.split(' ');
  if (parts.length != 3) {
    return errorLine;
  }

  var filePath = parts[0];
  var lineNumber = parts[1];
  var columnNumber = parts[2];

  return '$filePath:$lineNumber:$columnNumber';
}

// .............................................................................
/// Replaces error lines in the given message with vscode compatible ones.
String makeErrorLinesInMessageVscodeCompatible(String message) {
  var errorLines = _extractErrorLines(message);
  var result = message;

  for (var errorLine in errorLines) {
    var compatibleErrorLine = _makeErrorLineVscodeCompatible(errorLine);
    result = result.replaceAll(errorLine, compatibleErrorLine);
  }

  return result;
}
