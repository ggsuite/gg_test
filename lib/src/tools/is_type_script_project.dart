// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_lang/gg_lang.dart';

// #############################################################################

/// Returns true when [directory] looks like a TypeScript project.
///
/// Detection is delegated to gg_lang's [detectProjectType], so a Dart/Flutter
/// `pubspec.yaml` always takes precedence; a directory with no recognizable
/// manifest is treated as non-TypeScript.
bool isTypeScriptProject(Directory directory) {
  try {
    return detectProjectType(directory) == ProjectType.typescript;
  } catch (_) {
    return false;
  }
}
