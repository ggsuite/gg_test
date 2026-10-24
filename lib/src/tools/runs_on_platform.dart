// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:boolean_selector/boolean_selector.dart';

final RegExp _testOnRegExp = RegExp(
  r'''^\s*@TestOn\(\s*(['"])(.*?)\1\s*\)''',
  multiLine: true,
);

/// Returns true if the test file [testCode] runs on [operatingSystem], the
/// current one by default: false when its file-level `@TestOn(selector)`
/// excludes it, e.g. `@TestOn('mac-os')` on Windows.
///
/// A test file that does not run on a platform leaves no coverage there;
/// its implementation file cannot be asked for coverage on that platform.
/// The selector is read as `package:test` reads it, on the Dart VM.
bool runsOnPlatform(String testCode, {String? operatingSystem}) {
  final match = _testOnRegExp.firstMatch(testCode);
  if (match == null) {
    return true;
  }

  final os = operatingSystem ?? Platform.operatingSystem;
  final variables = {
    'vm',
    'dart-vm',
    switch (os) {
      'macos' => 'mac-os',
      final other => other,
    },
    if (os != 'windows') 'posix',
  };

  try {
    return BooleanSelector.parse(match.group(2)!).evaluate(variables.contains);
  } on FormatException {
    // A selector package:test cannot parse fails the run itself.
    return true;
  }
}
