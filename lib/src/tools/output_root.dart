// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:path/path.dart';

/// Determines the directory error pathes should be printed relative to.
///
/// VSCode resolves relative pathes in the terminal and the debug console
/// against the folder it was opened with. Therefore error pathes must not be
/// printed relative to the package, but relative to that folder:
///
/// 1. If the package is located within the current working directory, the
///    current working directory is used. This covers both »project opened«
///    (prefix is empty) and »workspace opened plus `gg_multi` started at the
///    workspace root« (prefix is e.g. `ggsuite/gg_one`).
/// 2. Otherwise the closest `*.code-workspace` file above the package
///    determines the root.
/// 3. Otherwise there is no root and absolute pathes are printed.
class OutputRoot {
  /// Constructor
  const OutputRoot();

  /// Returns the directory error pathes should be printed relative to.
  ///
  /// [currentDirectory] defaults to [Directory.current] and can be overridden
  /// for testing.
  ///
  /// Returns `null` when no root could be determined. In that case absolute
  /// pathes should be printed.
  Directory? get(Directory packageDir, {Directory? currentDirectory}) {
    final package = resolve(packageDir.absolute.path);
    final cwd = resolve((currentDirectory ?? Directory.current).path);

    // 1. The package is located within the current working directory
    if (equals(cwd, package) || isWithin(cwd, package)) {
      return Directory(cwd);
    }

    // 2. Search the closest *.code-workspace file above the package
    var dir = Directory(package);
    while (true) {
      if (_containsCodeWorkspace(dir)) {
        return dir;
      }

      final parent = dir.parent;
      if (equals(parent.path, dir.path)) {
        break;
      }
      dir = parent;
    }

    // 3. No root found
    return null;
  }

  // ...........................................................................
  /// Resolves symbolic links so that pathes can be compared reliably.
  static String resolve(String path) {
    final canonical = canonicalize(path);
    try {
      return canonicalize(Directory(canonical).resolveSymbolicLinksSync());
    } catch (_) {
      return canonical;
    }
  }

  // ...........................................................................
  bool _containsCodeWorkspace(Directory dir) {
    if (!dir.existsSync()) {
      return false;
    }

    return dir
        .listSync(followLinks: false)
        .any((e) => e is File && e.path.endsWith('.code-workspace'));
  }
}
