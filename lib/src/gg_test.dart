// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_test/src/commands/tests.dart';
import 'package:gg_test/src/commands/tests_ts.dart';

/// The command line interface for GgTest
class GgTest extends Command<dynamic> {
  /// Constructor
  GgTest({required this.ggLog}) {
    addSubcommand(Tests(ggLog: ggLog));
    addSubcommand(TestsTs(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'test';
  @override
  final description = 'Execute tests with coverage.';
}
