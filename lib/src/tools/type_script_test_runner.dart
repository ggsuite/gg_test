// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:path/path.dart';

// #############################################################################

/// Runs Vitest against a TypeScript project.
///
/// The coverage gate is delegated to Vitest itself — projects express their
/// thresholds in `vitest.config.{ts,mts}` (`thresholds` + `checkCoverage`),
/// so this runner only needs to fail when Vitest fails.
class TypeScriptTestRunner {
  /// Constructor.
  const TypeScriptTestRunner({this.processWrapper = const GgProcessWrapper()});

  /// The process wrapper used to execute shell processes.
  final GgProcessWrapper processWrapper;

  /// Runs `vitest run --coverage` via the detected package manager.
  /// Throws on failure.
  Future<void> run({required Directory directory, required GgLog ggLog}) async {
    final cmd = _buildVitestCommand(directory);

    final statusPrinter = GgStatusPrinter<void>(
      message: 'Running "vitest run --coverage"',
      ggLog: ggLog,
    );
    statusPrinter.status = GgStatusPrinterStatus.running;

    final result = await processWrapper.run(
      cmd.executable,
      cmd.args,
      workingDirectory: directory.path,
      // Node tooling ships as `.cmd`/`.ps1` launchers on Windows, which
      // `dart:io` can only resolve via the shell.
      runInShell: true,
    );

    statusPrinter.status = result.exitCode == 0
        ? GgStatusPrinterStatus.success
        : GgStatusPrinterStatus.error;

    if (result.exitCode == 0) {
      return;
    }

    final stdout = result.stdout as String;
    final stderr = result.stderr as String;
    if (stdout.isNotEmpty) ggLog(stdout.trimRight());
    if (stderr.isNotEmpty) ggLog(stderr.trimRight());

    throw Exception(
      [
        'Tests failed',
        yellow(
          'Run "${blue('vitest run --coverage')}" '
          'to see details.',
        ),
      ].join('\n'),
    );
  }

  // ...........................................................................
  ({String executable, List<String> args}) _buildVitestCommand(
    Directory directory,
  ) {
    final vitestArgs = ['vitest', 'run', '--coverage'];
    if (File(join(directory.path, 'pnpm-lock.yaml')).existsSync()) {
      return (executable: 'pnpm', args: ['exec', ...vitestArgs]);
    }
    if (File(join(directory.path, 'yarn.lock')).existsSync()) {
      return (executable: 'yarn', args: vitestArgs);
    }
    return (executable: 'npx', args: vitestArgs);
  }
}

// .............................................................................
/// A mocktail mock.
class MockTypeScriptTestRunner extends mocktail.Mock
    implements TypeScriptTestRunner {}
