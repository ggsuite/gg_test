// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_lang/gg_lang.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

// #############################################################################

/// Runs the test suite of a TypeScript project.
///
/// When the project's `package.json` declares a `test` script, that script is
/// run (`<pm> run test`) so a cross-language bridge repo can chain its Dart
/// and TypeScript suites. Otherwise it falls back to `vitest run --coverage`.
///
/// The coverage gate is delegated to the script / Vitest itself — projects
/// express their thresholds in `vitest.config.{ts,mts}` (`thresholds` +
/// `checkCoverage`), so this runner only needs to fail when the command fails.
class TypeScriptTestRunner {
  /// Constructor.
  const TypeScriptTestRunner({this.processWrapper = const GgProcessWrapper()});

  /// The process wrapper used to execute shell processes.
  final GgProcessWrapper processWrapper;

  /// Runs the project's `test` script (or `vitest run --coverage` as a
  /// fallback) via the detected package manager. Throws on failure.
  Future<void> run({required Directory directory, required GgLog ggLog}) async {
    final pm = detectTypeScriptPackageManager(directory);

    final ({String executable, List<String> args}) cmd;
    final String label;
    if (hasNpmScript(directory, 'test')) {
      // Prefer the project's own test script when one is defined.
      cmd = pm.runCommand('test');
      label = '${cmd.executable} ${cmd.args.join(' ')}';
    } else {
      cmd = pm.execCommand('vitest', ['run', '--coverage']);
      label = 'vitest run --coverage';
    }

    final statusPrinter = GgStatusPrinter<void>(
      message: 'Running "$label"',
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
        yellow('Run "${blue(label)}" to see details.'),
      ].join('\n'),
    );
  }
}

// .............................................................................
/// A mocktail mock.
class MockTypeScriptTestRunner extends mocktail.Mock
    implements TypeScriptTestRunner {}
