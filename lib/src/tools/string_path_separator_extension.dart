// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

/// Adds an .os method to strings to turn / into the platform path separator
extension GgTestStringPathSeparatorExtensions on String {
  /// Overwrite this separator for testing purposes
  static String? nextTestSeparator;

  /// Replaces all slashes by the os path separator
  String get os {
    // coverage:ignore-start
    final s = nextTestSeparator ?? Platform.pathSeparator;
    // coverage:ignore-end
    nextTestSeparator = null;
    return s == '/' ? replaceAll(r'\', s) : replaceAll('/', s);
  }
}
