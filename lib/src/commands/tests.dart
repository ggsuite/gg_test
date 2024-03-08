// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_args/gg_args.dart';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_is_flutter/gg_is_flutter.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_test/src/tools/error_files.dart';
import 'package:gg_test/src/tools/is_github.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

typedef _Report = Map<String, Map<int, int>>;
typedef _MissingLines = Map<String, List<int>>;
typedef _TaskResult = (int, List<String>, List<String>);

// #############################################################################

/// Runs dart test on the source code
class Tests extends GgDirCommand {
  /// Constructor
  Tests({
    required super.log,
    this.processWrapper = const GgProcessWrapper(),
  });

  /// Then name of the command
  @override
  final name = 'tests';

  /// The description of the command
  @override
  final description = 'Check tests and coverage';

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> run() async {
    await super.run();
    await GgDirCommand.checkDir(directory: inputDir);

    // Save directories
    _coverageDir = Directory(join(inputDir.path, 'coverage'));
    _srcDir = Directory(join(inputDir.path, 'lib', 'src'));

    // Init status printer
    final statusPrinter = GgStatusPrinter<void>(
      message: isFlutter
          ? 'Running "flutter test --coverage"'
          : 'Running "dart test"',
      printCallback: log,
      useCarriageReturn: isGitHub,
    );

    statusPrinter.status = GgStatusPrinterStatus.running;

    // Announce the command
    final result = await _task();
    final (code, messages, errors) = result;
    final success = code == 0;

    statusPrinter.status =
        success ? GgStatusPrinterStatus.success : GgStatusPrinterStatus.error;

    if (!success) {
      _logErrors(messages, errors);
    }

    if (code != 0) {
      throw Exception(
        '"dart test" failed. See log for details.',
      );
    }
  }

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;

  final _errors = <String>[];
  final _messages = <String>[];
  late Directory _coverageDir;
  late Directory _srcDir;

  // ...........................................................................
  void _logErrors(List<String> messages, List<String> errors) {
    final errorMsg = errors.where((e) => e.isNotEmpty).join('\n');
    final stdoutMsg = messages.where((e) => e.isNotEmpty).join('\n');

    if (errorMsg.isNotEmpty) {
      log(errorMsg); // coverage:ignore-line
    }
    if (stdoutMsg.isNotEmpty) {
      log(stdoutMsg);
    }
  }

// .............................................................................
  List<String> _extractErrorLines(String message) {
    // Regular expression to match file paths and line numbers
    RegExp exp = RegExp(r'test\/[\/\w]+\.dart[\s:]*\d+:\d+');
    final matches = exp.allMatches(message);
    final result = <String>[];

    if (matches.isEmpty) {
      return result;
    }

    for (final match in matches) {
      var matchedString = match.group(0) ?? '';
      result.add(matchedString);
    }

    return result;
  }

// .............................................................................
  String _addDotSlash(String relativeFile) {
    if (!relativeFile.startsWith('./')) {
      return './$relativeFile';
    }
    return relativeFile;
  }

// .............................................................................
  _Report _generateReport() {
    return isFlutter ? _generateFlutterReport() : _generateDartReport();
  }

  // ...........................................................................
  _Report _generateDartReport() {
    // Iterate all 'dart.vm.json' files within coverage directory
    final coverageFiles =
        _coverageDir.listSync(recursive: true).whereType<File>().where((file) {
      return file.path.endsWith('dart.vm.json');
    }).toList();

    final relativeCoverageFiles = coverageFiles.map((file) {
      return relative(file.path, from: inputDir.path);
    }).toList();

    // Prepare result
    final result = _Report();

    // Collect coverage data
    for (final coverageFile in relativeCoverageFiles) {
      final testFile =
          coverageFile.replaceAll('.vm.json', '').replaceAll('coverage/', '');
      var implementationFile = testFile
          .replaceAll('test/', 'lib/src/')
          .replaceAll('_test.dart', '.dart');
      final implementationFileWithoutLib =
          implementationFile.replaceAll('lib/', '');

      final fileContent =
          File(join(inputDir.path, coverageFile)).readAsStringSync();
      final coverageData = jsonDecode(fileContent);

      // Iterate coverage data
      final entries = coverageData['coverage'] as List<dynamic>;
      final entriesForImplementationFile = entries.where((entry) {
        final source = entry['source'] as String;
        return (source.contains(implementationFileWithoutLib));
      });
      for (final entry in entriesForImplementationFile) {
        // Read script

        // Find or create summary for script
        implementationFile = join(inputDir.path, implementationFile);
        result[implementationFile] ??= {};
        late Map<int, int> summaryForScript = result[implementationFile]!;
        final ignoredLines = _ignoredLines(implementationFile);

        // Collect hits for all lines
        var hits = entry['hits'] as List<dynamic>;
        for (var i = 0; i < hits.length; i += 2) {
          final line = hits[i] as int;
          final isIgnored = ignoredLines[line];
          if (isIgnored) continue;
          final hitCount = hits[i + 1] as int;
          // Find or create summary for line
          final existingHits = summaryForScript[line] ?? 0;
          summaryForScript[line] = existingHits + hitCount;
        }
      }
    }

    return result;
  }

  // ...........................................................................
  _Report _generateFlutterReport() {
    // Iterate all 'lcov' files within coverage directory
    final coverageFile = File(
      join(inputDir.path, 'coverage', 'lcov.info'),
    );

    // Prepare result
    final result = _Report();

    // Prepare report for file
    late Map<int, int> summaryForScript;

    final fileContent = coverageFile.readAsStringSync();
    final lines = fileContent.split('\n');

    for (final line in lines) {
      // Read script
      if (line.startsWith('SF:')) {
        final script = './${line.replaceFirst('SF:', '')}';
        final scriptAbsolute = canonicalize(join(inputDir.path, script));
        summaryForScript = {};
        result[scriptAbsolute] = summaryForScript;
      }
      // Read coverage
      else if (line.startsWith('DA:')) {
        final parts = line.replaceFirst('DA:', '').split(',');
        final lineNumber = int.parse(parts[0]);
        final hits = int.parse(parts[1]);
        summaryForScript[lineNumber] = hits;
      }
    }

    return result;
  }

  // ...........................................................................
  double _calculateCoverage(_Report report) {
    // Calculate coverage
    var totalLines = 0;
    var coveredLines = 0;
    for (final script in report.keys) {
      for (final line in report[script]!.keys) {
        totalLines++;
        if (report[script]![line]! > 0) {
          coveredLines++;
        }
      }
    }

    // Calculate percentage
    var percentage = (coveredLines / totalLines) * 100;
    return percentage;
  }

// .............................................................................
  final Map<String, List<bool>> _ignoredLinesCache = {};

  // ...........................................................................
  List<bool> _ignoredLines(String script) {
    final cachedResult = _ignoredLinesCache[script];
    if (cachedResult != null) {
      return cachedResult;
    }

    final lines = File(script).readAsLinesSync();
    final ignoredLines = List<bool>.filled(lines.length + 1, false);

    final isThisScript = script.contains('lib/src/commands/check/tests.dart');

    // Evaluate ignore start/end
    var ignoreStart = false;
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var lineNumber = i + 1;

      // Whole file ignored?
      if (!isThisScript && line.contains('coverage:ignore-file')) {
        ignoredLines.fillRange(0, lines.length + 1, true);
        break;
      }

      // Range ignored?
      if (line.contains('coverage:ignore-start')) {
        ignoreStart = true;
      }

      if (line.contains('coverage:ignore-end')) {
        ignoreStart = false;
      }

      // Line ignored?
      var ignoreLine = line.contains('coverage:ignore-line');
      ignoredLines[lineNumber] = ignoreStart || ignoreLine;
    }

    _ignoredLinesCache[script] = ignoredLines;
    return ignoredLines;
  }

// .............................................................................
  _MissingLines _estimateMissingLines(_Report report) {
    final _MissingLines result = {};
    for (final script in report.keys) {
      final lines = report[script]!;
      final linesSorted = lines.keys.toList()..sort();

      for (final line in linesSorted) {
        final hits = lines[line]!;
        if (hits == 0) {
          result[script] ??= [];
          result[script]!.add(line);
        }
      }
    }

    return result;
  }

// .............................................................................
  void _printMissingLines(_MissingLines missingLines) {
    for (final script in missingLines.keys) {
      final testFile = script
          .replaceFirst('lib/src', 'test')
          .replaceAll('.dart', '_test.dart');

      final relativeTestFile = relative(testFile, from: inputDir.path);
      final relativeScript = relative(script, from: inputDir.path);

      const bool printFirstOnly = true;
      final lineNumbers = missingLines[script]!;
      for (final lineNumber in lineNumbers) {
        // Don't print too many lines

        _messages.add('- $red$relativeScript:$lineNumber$reset');
        _messages.add('  $blue$relativeTestFile$reset\n');
        if (printFirstOnly) break;
      }
    }
  }

// .............................................................................
  void _writeLcovReport(_Report report) {
    final buffer = StringBuffer();
    for (final script in report.keys) {
      buffer.writeln('SF:$script');
      for (final line in report[script]!.keys) {
        final hits = report[script]![line]!;
        buffer.writeln('DA:$line,$hits');
      }
      buffer.writeln('end_of_record');
    }

    final lcovReport = buffer.toString();
    final lcovFile = File(join(_coverageDir.path, 'lcov.info'));
    lcovFile.writeAsStringSync(lcovReport);
  }

  // ...........................................................................
  Iterable<(File, File)> _implementationAndTestFiles() {
    // Get all implementation files
    final implementationFiles =
        _srcDir.listSync(recursive: true).whereType<File>().where((file) {
      return file.path.endsWith('.dart');
    }).toList();

    final result = implementationFiles.map((implementationFile) {
      final testFile = implementationFile.path
          .replaceAll('lib/src/', 'test/')
          .replaceAll('.dart', '_test.dart');

      return (implementationFile, File(testFile));
    });

    return result;
  }

// .............................................................................
  Iterable<(File, File)> _collectMissingTestFiles(
    Iterable<(File, File)> files,
  ) =>
      files.where(
        (e) => !e.$2.existsSync(),
      );

// .............................................................................
  static const _testBoilerplate = '''
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

void main() {
  group('Boilerplate', () {
    test('should work fine', () {
      // INSTANTIATE CLASS HERE
      expect(true, isNotNull);
    });
  });
}
''';

// .............................................................................
  void _createMissingTestFiles(Iterable<(File, File)> missingFiles) {
    // Create missing test files and ask user to edit it
    _messages.add(
      '${yellow}Tests were created. Please revise:$reset',
    );
    final packageName = basename(inputDir.path);

    for (final (implementationFile, testFile) in missingFiles) {
      // Create test file with intermediate directories
      final testFileDir = dirname(testFile.path);
      Directory(testFileDir).createSync(recursive: true);

      // Write boilerplate
      final className =
          basenameWithoutExtension(implementationFile.path).pascalCase;

      final implementationFileRelative =
          relative(implementationFile.path, from: inputDir.path);

      final implementationFilePath = implementationFileRelative
          .replaceAll('lib/', '')
          .replaceAll('./', '');

      final boilerplate = _testBoilerplate
          .replaceAll('Boilerplate', className)
          .replaceAll('// INSTANTIATE CLASS HERE', '// const $className();')
          .replaceAll(
            'import \'package:test/test.dart\';',
            'import \'package:$packageName/'
                // ignore: missing_whitespace_between_adjacent_strings
                '$implementationFilePath\';\n'
                'import \'package:test/test.dart\';\n',
          );

      // Create boilerplate file
      testFile.writeAsStringSync(boilerplate);
      final relativeTestFile = relative(testFile.path, from: inputDir.path);
      final relativeSrcFile =
          relative(implementationFile.path, from: inputDir.path);

      // Print message
      _messages.add('- $red$relativeTestFile$reset');
      _messages.add('  $brightBlack$relativeSrcFile$reset');
    }
  }

  // ...........................................................................
  Iterable<(File, File)> _findUntestedFiles(
    _Report report,
    Iterable<(File, File)> files,
  ) {
    final result = files.where(
      (e) {
        return !report.containsKey(e.$1.path) &&
            !File(e.$1.path)
                .readAsStringSync()
                .contains('coverage:ignore-file');
      },
    ).toList();

    return result;
  }

  // ...........................................................................
  void _printUntestedFiles(Iterable<(File, File)> files) {
    for (final tuple in files) {
      final (implementation, test) = tuple;
      final srcFileRelative =
          relative(implementation.path, from: inputDir.path);
      final testFileRelative = relative(test.path, from: inputDir.path);

      _messages.add('- $red$testFileRelative$reset');
      _messages.add('  $blue$srcFileRelative$reset');
    }
  }

  // ...........................................................................
  Future<int> _test() => isFlutter ? _testFlutter() : _testDart();

  // ...........................................................................
  Future<int> _testDart() async {
    // Remove the coverage directory
    if (_coverageDir.existsSync()) {
      _coverageDir.deleteSync(recursive: true);
    }

    // Run the Dart coverage command

    var errorLines = <String>{};
    var previousMessagesBelongingToError = <String>[];
    var isError = false;

    var process = await processWrapper.start(
      'dart',
      [
        'test',
        '-r',
        'expanded',
        '--coverage',
        'coverage',
        '--chain-stack-traces',
        '--no-color',
      ],
      workingDirectory: inputDir.path,
    );

    // Iterate over stdout and print output using a for loop
    await _processTestOutput(
      process,
      isError,
      previousMessagesBelongingToError,
      errorLines,
    );

    return process.exitCode;
  }

  // ...........................................................................
  Future<void> _processTestOutput(
    Process process,
    bool isError,
    List<String> previousMessagesBelongingToError,
    Set<String> errorLines,
  ) async {
    // Iterate over stdout and print output using a for loop
    await for (var event in process.stdout.transform(utf8.decoder)) {
      isError = isError || event.contains('[E]');
      if (isError) {
        event = makeErrorLinesInMessageVscodeCompatible(event);
        previousMessagesBelongingToError.add(event);
      }

      final newErrorLines = _extractErrorLines(event);
      if (newErrorLines.isNotEmpty &&
          !errorLines.contains(newErrorLines.first)) {
        // Print error line

        final newErrorLinesString = _addDotSlash(newErrorLines.join(',\n   '));
        _messages.add(' - $red$newErrorLinesString$reset');

        // Print messages belonging to this error
        for (var message in previousMessagesBelongingToError) {
          _messages.add('$brightBlack$message$reset');
        }

        isError = false;
      }
      errorLines.addAll(newErrorLines);
    }
  }

  // ...........................................................................
  Future<int> _testFlutter() async {
    int exitCode = 0;

    // Execute flutter tests
    var process = await processWrapper.start(
      'flutter',
      [
        'test',
        '--coverage',
      ],
      workingDirectory: inputDir.path,
    );

    var errorLines = <String>{};
    var previousMessagesBelongingToError = <String>[];
    var isError = false;

    // Iterate over stdout and print output using a for loop
    await _processTestOutput(
      process,
      isError,
      previousMessagesBelongingToError,
      errorLines,
    );

    exitCode = await process.exitCode;

    return exitCode;
  }

  // ...........................................................................
  Future<_TaskResult> _task() async {
    // Get implementation files
    final files = _implementationAndTestFiles();

    // Check if test files are missing for implementation files
    final missingTestFiles = _collectMissingTestFiles(files);
    if (missingTestFiles.isNotEmpty) {
      _createMissingTestFiles(missingTestFiles);
      return (1, _messages, _errors);
    }

    // Run Tests
    final error = await _test();

    if (error != 0) {
      return (error, _messages, _errors);
    }

    // Generate coverage reports
    final report = _generateReport();

    // Estimate untested files
    final untestedFiles = _findUntestedFiles(report, files);
    if (untestedFiles.isNotEmpty) {
      _messages.add(
        '${yellow}Please add valid tests to the following files:$reset',
      );
      _printUntestedFiles(untestedFiles);
      return (1, _messages, _errors);
    }

    var percentage = _calculateCoverage(report);
    if (!isFlutter) {
      _writeLcovReport(report);
    }

    // Check coverage percentage
    if (percentage != 100.0) {
      // Print percentage
      _messages.add(
        '${yellow}Coverage not 100%. Untested code:$reset',
      );

      // Print missing lines
      final missingLines =
          percentage < 100.0 ? _estimateMissingLines(report) : _MissingLines();

      _printMissingLines(missingLines);

      return (1, _messages, _errors);
    } else {
      _messages.add('✅ Coverage is 100%!');
      return (error, _messages, _errors);
    }
  }
}
