// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
import 'dart:io';

/// Returns true if the current project is a flutter project
bool get isFlutter =>
    testIsFlutter ?? (_isFlutter ??= _estimateFlutterOrDart());

// .............................................................................
bool? _isFlutter;

// .............................................................................
/// Reset the value of [isFlutter] to null for test purposes
void testResetIsFlutter() {
  _isFlutter = null;
  testIsFlutter = null;
}

// .............................................................................
/// Use this variable to enforce a specific value for [isFlutter] in tests
bool? testIsFlutter;

// .............................................................................
bool _estimateFlutterOrDart() {
  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw Exception('pubspec.yaml not found');
  }

  final String content = pubspec.readAsStringSync();
  return (content.contains('flutter'));
}
