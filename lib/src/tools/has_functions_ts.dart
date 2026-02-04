// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Provides utilities to detect whether a TypeScript source file
/// contains executable code such as functions, methods, or accessors.
class HasFunctionsTs {
  HasFunctionsTs._();

  /// Returns `true` if the given TypeScript [code] contains at least one
  /// function, method, arrow function, or getter/setter.
  ///
  /// The detection is heuristic and based on regular expressions but is
  /// designed to work reliably for typical TypeScript code used in
  /// application projects.
  static bool hasFunctionsTs(String code) {
    final sanitized = _stripComments(code);

    // Function declarations: `function foo(...) {}` or `export function foo(...) {}`
    const functionDeclPattern =
        r'\b(?:export\s+)?(?:async\s+)?function\s+[A-Za-z_][A-Za-z0-9_]*\s*\('; // ignore: lines_longer_than_80_chars

    // Class or object methods: `foo() {}`, possibly with modifiers.
    const methodPattern =
        r'\b(?:public|private|protected|static|async\s+)*[A-Za-z_][A-Za-z0-9_]*\s*\([^;{)]*\)\s*\{'; // ignore: lines_longer_than_80_chars

    // Getters and setters in classes: `get foo() {}` / `set foo(v) {}`.
    const getterSetterPattern =
        r'\b(?:public|private|protected|static\s+)?(?:get|set)\s+[A-Za-z_][A-Za-z0-9_]*\s*\('; // ignore: lines_longer_than_80_chars

    // Arrow functions assigned to variables: `const foo = (...) => {}`.
    const arrowFunctionPattern =
        r'\b(?:const|let|var)\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*(?:async\s*)?\([^;{)]*\)\s*=>'; // ignore: lines_longer_than_80_chars

    // Function expressions assigned to variables: `const foo = function(...) {}`.
    const functionExprPattern =
        r'\b(?:const|let|var)\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*(?:async\s+)?function\s*\('; // ignore: lines_longer_than_80_chars

    final patterns = <RegExp>[
      RegExp(functionDeclPattern, multiLine: true),
      RegExp(methodPattern, multiLine: true),
      RegExp(getterSetterPattern, multiLine: true),
      RegExp(arrowFunctionPattern, multiLine: true),
      RegExp(functionExprPattern, multiLine: true),
    ];

    return patterns.any((pattern) => pattern.hasMatch(sanitized));
  }

  /// Removes single-line (`// ...`) and multi-line (`/* ... */`) comments
  /// from the given [code] so that comment content does not confuse the
  /// function detection regular expressions.
  static String _stripComments(String code) {
    // Remove multi-line comments first.
    final multiLineCommentRegExp = RegExp(r'/\*.*?\*/', dotAll: true);
    var result = code.replaceAll(multiLineCommentRegExp, ' ');

    // Remove single-line comments.
    final singleLineCommentRegExp = RegExp(r'//.*', multiLine: true);
    result = result.replaceAll(singleLineCommentRegExp, '\n');

    return result;
  }
}

/// Convenience top-level function mirroring the Dart variant `hasFunctions`.
///
/// Returns `true` if [code] contains any TypeScript functions, methods,
/// arrow functions, or accessors.
bool hasFunctionsTs(String code) => HasFunctionsTs.hasFunctionsTs(code);
