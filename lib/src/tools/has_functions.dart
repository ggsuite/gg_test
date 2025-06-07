// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

final RegExp _functionRegExp = RegExp(
  r'\b(?:[a-zA-Z_]\w*\s+)?' // Optional return type or visibility modifier
  r'(?:get|set)?' // Optional 'get' or 'set'
  r'\s+' // Mandatory whitespace (avoids matching variables)
  r'([a-zA-Z_]\w*)' // Function name
  r'\s*' // Optional whitespace before parameters
  r'\(' // Opening parenthesis
  r'[^)]*' // Non-greedy match inside the parenthesis
  r'\)' // Closing parenthesis
  r'\s*' // Optional whitespace before body or arrow
  r'(?:\=\>|\{)', // Match functions using either '=>' syntax or opening a block with '{'
  multiLine: true,
  dotAll: true,
);

final RegExp _getAndSetRegExp = RegExp(
  r'\b(?:[a-zA-Z_]\w*\s+)?' // Optional return type or visibility modifier (e.g., 'int', 'final')
  r'(get|set)\s+' // 'get' or 'set' keyword followed by mandatory whitespace
  r'([a-zA-Z_]\w*)' // Name of the getter or setter
  r'(?:\s*\(\s*([a-zA-Z_]\w*\s+[a-zA-Z_]\w*)?\s*\))?' // Optional parameter for setters
  r'\s*' // Optional whitespace
  r'(?:\=>\s*[^;]*;|\{[^}]*\})', // Match either '=>' for single line or '{}' for block body
  multiLine: true,
);

/// Returns true if the code has functions
bool hasFunctions(String code) {
  return _functionRegExp.hasMatch(code) || _getAndSetRegExp.hasMatch(code);
}
