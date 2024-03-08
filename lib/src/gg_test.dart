// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_test/src/commands/tests.dart';

/// The command line interface for GgTest
class GgTest extends Command<dynamic> {
  /// Constructor
  GgTest({required this.log}) {
    addSubcommand(Tests(log: log));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'test';
  @override
  final description = 'Execute tests with coverage.';
}
