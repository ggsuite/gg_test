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
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:gg_test/src/tools/error_info_reader.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:mocktail/mocktail.dart';

typedef _Report = Map<String, Map<int, int>>;
typedef _MissingLines = Map<String, List<int>>;
typedef _TaskResult = (int, List<String>, List<String>);

// #############################################################################

/// Runs dart test on the source code
class Tests extends DirCommand<void> {
  /// Constructor
  Tests({
    required super.ggLog,
    this.processWrapper = const GgProcessWrapper(),
  }) : super(name: 'tests', description: 'Runs »dart test«.');

  // ...........................................................................
  /// Executes the command
  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    await check(directory: directory);

    // Save directories
    _coverageDir = Directory(join(directory.path, 'coverage'));
    _srcDir = Directory(join(directory.path, 'lib', 'src'));
    // Init status printer
    final statusPrinter = GgStatusPrinter<void>(
      message: isFlutterDir(directory)
          ? 'Running "flutter test --coverage"'
          : 'Running "dart test"',
      ggLog: ggLog,
    );

    statusPrinter.status = GgStatusPrinterStatus.running;

    // Announce the command
    final result = await _task(directory);
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
      ggLog(errorMsg); // coverage:ignore-line
    }
    if (stdoutMsg.isNotEmpty) {
      ggLog(stdoutMsg);
    }
  }

  // ...........................................................................
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

  // ...........................................................................
  String _addDotSlash(String relativeFile) {
    if (!relativeFile.startsWith('./')) {
      return './$relativeFile';
    }
    return relativeFile;
  }

// .............................................................................
  _Report _generateReport(Directory dir) {
    return isFlutter ? _generateFlutterReport(dir) : _generateDartReport(dir);
  }

  // ...........................................................................
  _Report _generateDartReport(Directory dir) {
    // Iterate all 'dart.vm.json' files within coverage directory
    final coverageFiles =
        _coverageDir.listSync(recursive: true).whereType<File>().where((file) {
      return file.path.endsWith('dart.vm.json');
    }).toList();

    final relativeCoverageFiles = coverageFiles.map((file) {
      return relative(file.path, from: dir.path);
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

      final implementationFileExists =
          File(join(dir.path, implementationFile)).existsSync();

      // Workaround: In some cases dart tests adds old coverage files
      if (!implementationFileExists) {
        continue;
      }

      final implementationFileWithoutLib =
          implementationFile.replaceAll('lib/', '');

      final fileContent = File(join(dir.path, coverageFile)).readAsStringSync();
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
        implementationFile = join(dir.path, implementationFile);
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
  _Report _generateFlutterReport(Directory dir) {
    // Iterate all 'lcov' files within coverage directory
    final coverageFile = File(
      join(dir.path, 'coverage', 'lcov.info'),
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
        final scriptAbsolute = canonicalize(join(dir.path, script));
        summaryForScript = {};
        final key = dir.path.startsWith('.') ? script : scriptAbsolute;
        result[key] = summaryForScript;
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

  // ...........................................................................
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

  // ...........................................................................
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

  // ...........................................................................
  void _printMissingLines(_MissingLines missingLines, Directory dir) {
    for (final script in missingLines.keys) {
      final testFile = script
          .replaceFirst('lib/src', 'test')
          .replaceAll('.dart', '_test.dart');

      final relativeTestFile = relative(testFile, from: dir.path);
      final relativeScript = relative(script, from: dir.path);

      const bool printFirstOnly = true;
      final lineNumbers = missingLines[script]!;
      for (final lineNumber in lineNumbers) {
        // Don't print too many lines
        var implementationRed = red('$relativeScript:$lineNumber');
        var testFileBlue = blue(relativeTestFile);

        _messages.add('- $implementationRed');
        _messages.add('  $testFileBlue');
        if (printFirstOnly) break;
      }
    }
  }

  // ...........................................................................
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
  void _createMissingTestFiles(
    Iterable<(File, File)> missingFiles,
    Directory dir,
  ) {
    // Create missing test files and ask user to edit it
    _messages.add(
      yellow(
        'Tests were created. Please revise:',
      ),
    );
    final packageName = basename(dir.path);

    for (final (implementationFile, testFile) in missingFiles) {
      // Create test file with intermediate directories
      final testFileDir = dirname(testFile.path);
      Directory(testFileDir).createSync(recursive: true);

      // Write boilerplate
      final className =
          basenameWithoutExtension(implementationFile.path).pascalCase;

      final implementationFilePath =
          implementationFile.path.replaceAll('lib/', '').replaceAll('./', '');

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
      final relativeTestFile = red(relative(testFile.path, from: dir.path));
      final relativeSrcFile = brightBlack(
        relative(
          implementationFile.path,
          from: dir.path,
        ),
      );

      // Print message
      _messages.add('- $relativeTestFile\n  $relativeSrcFile');
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
  void _printUntestedFiles(
    Iterable<(File, File)> files,
    Directory dir,
  ) {
    for (final tuple in files) {
      final (implementation, test) = tuple;
      final srcFileRelative =
          blue(relative(implementation.path, from: dir.path));
      final testFileRelative = red(relative(test.path, from: dir.path));

      _messages.add('- $testFileRelative');
      _messages.add('  $srcFileRelative');
    }
  }

  // ...........................................................................
  Future<int> _test(Directory dir) =>
      isFlutter ? _testFlutter(dir) : _testDart(dir);

  // ...........................................................................
  Future<int> _testDart(Directory dir) async {
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
      workingDirectory: dir.path,
    );

    // Iterate over stdout and print output using a for loop
    await _processTestOutput(
      process,
      isError,
      previousMessagesBelongingToError,
      errorLines,
    );

    return await process.exitCode != 0 || errorLines.isNotEmpty ? 1 : 0;
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
        event = ErrorInfoReader().makeVscodeCompatible(event);
        previousMessagesBelongingToError.add(event);
      }

      final newErrorLines = _extractErrorLines(event);
      if (newErrorLines.isNotEmpty &&
          !errorLines.contains(newErrorLines.first)) {
        // Print error line

        final newErrorLinesString = red(
          _addDotSlash(
            newErrorLines.join(',\n   '),
          ),
        );
        _messages.add(' - $newErrorLinesString');

        // Print messages belonging to this error
        for (var message in previousMessagesBelongingToError) {
          _messages.add(brightBlack(message));
        }

        isError = false;
      }
      errorLines.addAll(newErrorLines);
    }
  }

  // ...........................................................................
  Future<int> _testFlutter(Directory dir) async {
    int exitCode = 0;

    // Execute flutter tests
    var process = await processWrapper.start(
      'flutter',
      [
        'test',
        '--coverage',
        '-r',
        'expanded',
      ],
      workingDirectory: dir.path,
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

    return exitCode != 0 || errorLines.isNotEmpty ? 1 : 0;
  }

  // ...........................................................................
  Future<_TaskResult> _task(Directory dir) async {
    // Get implementation files
    final files = _implementationAndTestFiles();

    // Check if test files are missing for implementation files
    final missingTestFiles = _collectMissingTestFiles(files);
    if (missingTestFiles.isNotEmpty) {
      _createMissingTestFiles(missingTestFiles, dir);
      return (1, _messages, _errors);
    }

    // Run Tests
    final error = await _test(dir);

    if (error != 0) {
      return (error, _messages, _errors);
    }

    // Generate coverage reports
    final report = _generateReport(dir);

    // Estimate untested files
    final untestedFiles = _findUntestedFiles(report, files);
    if (untestedFiles.isNotEmpty) {
      _messages.add(
        yellow(
          'Please add valid tests to the following files:',
        ),
      );
      _printUntestedFiles(untestedFiles, dir);
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
        yellow(
          'Coverage not 100%. Untested code:',
        ),
      );

      // Print missing lines
      final missingLines =
          percentage < 100.0 ? _estimateMissingLines(report) : _MissingLines();

      _printMissingLines(missingLines, dir);

      return (1, _messages, _errors);
    } else {
      _messages.add('✅ Coverage is 100%!');
      return (error, _messages, _errors);
    }
  }
}

// .............................................................................
/// Mocktail mock
class MockTests extends Mock implements Tests {}
