// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart';

// #############################################################################

/// Returns true when [directory] looks like a TypeScript project.
///
/// A Dart/Flutter `pubspec.yaml` always takes precedence — it unambiguously
/// marks the directory as a Dart/Flutter package even if a `package.json`
/// happens to sit next to it (e.g. for bundled tooling).
bool isTypeScriptProject(Directory directory) {
  if (File(join(directory.path, 'pubspec.yaml')).existsSync()) {
    return false;
  }
  final packageJson = File(join(directory.path, 'package.json'));
  final tsconfig = File(join(directory.path, 'tsconfig.json'));
  return packageJson.existsSync() && tsconfig.existsSync();
}
