// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_test/gg_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

class MockGgProcessWrapper extends Mock implements GgProcessWrapper {}

/// A minimal fake [Process] used to simulate `npm test` or similar calls.
class FakeProcess implements Process {
  FakeProcess({required this.stdoutData, this.exitCodeValue = 0, this.onExit}) {
    _stdoutController = StreamController<List<int>>();
    if (stdoutData.isNotEmpty) {
      _stdoutController.add(utf8.encode(stdoutData));
    }
    _stdoutController.close();

    _exitCodeCompleter = Completer<int>()
      ..complete(
        Future<int>.delayed(Duration.zero, () {
          onExit?.call();
          return exitCodeValue;
        }),
      );
  }

  final String stdoutData;
  final int exitCodeValue;
  final void Function()? onExit;

  late final StreamController<List<int>> _stdoutController;
  late final Completer<int> _exitCodeCompleter;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  IOSink get stdin => IOSink(StreamController<List<int>>().sink);

  @override
  int get pid => 0;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

void main() {
  late Directory tmp;
  late Directory d;
  late Directory sampleTsProject;
  late File srcFile;
  late File testFile;
  late String testFileContent;
  late TestsTs testCmd;
  late MockGgProcessWrapper processWrapper;
  late CommandRunner<void> runner;
  final messages = <String>[];

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  Future<void> initDirs() async {
    tmp = Directory.systemTemp.createTempSync('test_ts_');
    d = Directory(join(tmp.path, 'test')); // working directory
    await d.create();
  }

  Future<void> initSampleProject() async {
    final src = Directory(join('sample_ts_project'));
    sampleTsProject = Directory(join(d.path, 'sample_ts_project'));

    final result = Platform.isWindows
        ? await Process.run('xcopy', <String>[
            src.path,
            sampleTsProject.path,
            '/E',
            '/I',
            '/H',
          ])
        : await Process.run('cp', <String>[
            '-r',
            src.path,
            sampleTsProject.path,
          ]);

    expect(result.exitCode, 0);
    expect(await sampleTsProject.exists(), isTrue);

    srcFile = File(join(sampleTsProject.path, 'src', 'simple_base.ts'));
    expect(srcFile.existsSync(), isTrue);

    testFile = File(join(sampleTsProject.path, 'test', 'simple_base.spec.ts'));
    expect(testFile.existsSync(), isTrue);

    testFileContent = await testFile.readAsString();
  }

  Future<void> initCommandAndRunner() async {
    processWrapper = MockGgProcessWrapper();
    testCmd = TestsTs(ggLog: messages.add, processWrapper: processWrapper);

    runner = CommandRunner<void>('check', 'Check')..addCommand(testCmd);
  }

  Future<void> init() async {
    await initDirs();
    await initSampleProject();
    await initCommandAndRunner();
  }

  tearDown(() async {
    try {
      await d.delete(recursive: true);
      await tmp.delete(recursive: true);
    } catch (_) {}
    messages.clear();
  });

  group('TestsTs', () {
    group('run()', () {
      test(
        'should throw if implementation files have no corresponding test files',
        () async {
          await init();

          // Delete test file so that the command creates a boilerplate test.
          testFile.deleteSync();

          // No processWrapper stubbing is required here because the
          // command will fail before running tests.

          await expectLater(
            () => runner.run(<String>[
              'tests-ts',
              '--input',
              sampleTsProject.path,
            ]),
            throwsA(
              isA<Exception>()
                  .having((e) => e.toString().split('\n'), 'message', <String>[
                    'Exception: Tests failed',
                    yellow('Run "${blue('npm test')}" to see details.'),
                  ]),
            ),
          );

          expect(messages[0], contains('⌛️ Running "npm test"'));
          expect(messages[1], contains('❌ Running "npm test"'));

          final combined = messages[2];
          expect(
            combined,
            contains(yellow('Tests were created. Please revise:')),
          );

          expect(combined.os, contains(red('test/simple_base.spec.ts'.os)));

          expect(combined.os, contains(brightBlack('src/simple_base.ts'.os)));
        },
      );

      test('should report failing unit tests from Jest output', () async {
        await init();

        const failingOutput = '''
FAIL test/simple_base.spec.ts
  ● SimpleBase › example should work

    Expected: 2
    Received: 1

      10 |   it('example should work', () => {
      11 |     const instance = SimpleBase.example();
    > 12 |     expect(instance.increment()).toBe(3);
         |                                  ^
      13 |   });
      14 | });

      at Object.<anonymous> (src/simple_base.ts:7:1)
''';

        when(
          () => processWrapper.start(
            any<String>(),
            any<List<String>>(),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer(
          (_) async => FakeProcess(stdoutData: failingOutput, exitCodeValue: 1),
        );

        await expectLater(
          () =>
              runner.run(<String>['tests-ts', '--input', sampleTsProject.path]),
          throwsA(
            isA<Exception>()
                .having((e) => e.toString().split('\n'), 'message', <String>[
                  'Exception: Tests failed',
                  yellow('Run "${blue('npm test')}" to see details.'),
                ]),
          ),
        );

        expect(messages[0], contains('⌛️ Running "npm test"'));
        expect(messages[1], contains('❌ Running "npm test"'));
        expect(
          messages[2].os,
          contains(red('./test/simple_base.spec.ts:12:1'.os)),
        );
      });

      test('should succeed when coverage is 100%', () async {
        await init();

        final coverageDir = Directory(join(sampleTsProject.path, 'coverage'));
        final lcovFile = File(join(coverageDir.path, 'lcov.info'));

        when(
          () => processWrapper.start(
            any<String>(),
            any<List<String>>(),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer(
          (_) async => FakeProcess(
            stdoutData: 'PASS test/simple_base.spec.ts',
            onExit: () {
              coverageDir.createSync(recursive: true);
              lcovFile.writeAsStringSync(_tsLcovReport100);
            },
          ),
        );

        await runner.run(<String>['tests-ts', '--input', sampleTsProject.path]);

        // Last message should be the success message from coverage.
        expect(messages.last, contains('✅ Coverage is 100%!'));
      });

      test('should complain when coverage is below 100%', () async {
        await init();

        final coverageDir = Directory(join(sampleTsProject.path, 'coverage'));
        final lcovFile = File(join(coverageDir.path, 'lcov.info'));

        when(
          () => processWrapper.start(
            any<String>(),
            any<List<String>>(),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer(
          (_) async => FakeProcess(
            stdoutData: 'PASS test/simple_base.spec.ts',
            onExit: () {
              coverageDir.createSync(recursive: true);
              lcovFile.writeAsStringSync(_tsLcovReportPartial);
            },
          ),
        );

        await expectLater(
          () =>
              runner.run(<String>['tests-ts', '--input', sampleTsProject.path]),
          throwsA(
            isA<Exception>()
                .having((e) => e.toString().split('\n'), 'message', <String>[
                  'Exception: Tests failed',
                  yellow('Run "${blue('npm test')}" to see details.'),
                ]),
          ),
        );

        expect(messages[0], contains('⌛️ Running "npm test"'));
        expect(messages[1], contains('❌ Running "npm test"'));
        expect(
          messages[2].os,
          contains(yellow('Coverage not 100%. Untested code:')),
        );
        expect(messages[2].os, contains('- ${red('src/simple_base.ts:7'.os)}'));
      });
    });
  });
}

const _tsLcovReport100 = '''
SF:src/simple_base.ts
DA:5,1
DA:7,1
LF:2
LH:2
end_of_record
''';

const _tsLcovReportPartial = '''
SF:src/simple_base.ts
DA:5,1
DA:7,0
LF:2
LH:1
end_of_record
''';
