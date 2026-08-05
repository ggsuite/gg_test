// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_is_flutter/gg_is_flutter.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_test/gg_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:gg_status_printer/gg_status_printer.dart';

void main() {
  late Directory tmp;
  late Directory d;
  late Directory sampleProject;
  final Directory currentDir = Directory.current;
  late File srcFile;
  late File testFile;
  late String testFileContent;
  late Tests testCmd;
  final messages = <String>[];
  late CommandRunner<void> runner;
  const pathTypes = ['absolute', 'relative'];

  // ...........................................................................
  tearDown(() {
    Directory.current = currentDir;
    testIsFlutter = null;
  });

  // ...........................................................................
  Future<void> initSampleProject() async {
    final src = Directory(join('sample_project'));
    sampleProject = Directory(join(d.path, 'sample_project'));

    final r = Platform.isWindows
        ? await Process.run('xcopy', [
            src.path,
            sampleProject.path,
            '/E',
            '/I',
            '/H',
          ])
        : await Process.run('cp', ['-r', src.path, sampleProject.path]);

    expect(r.exitCode, 0);
    expect(await sampleProject.exists(), isTrue);

    srcFile = File(join(sampleProject.path, 'lib', 'src', 'simple_base.dart'));
    expect(srcFile.existsSync(), isTrue);

    testFile = File(join(sampleProject.path, 'test', 'simple_base_test.dart'));
    expect(testFile.existsSync(), isTrue);
    testFileContent = await testFile.readAsString();
  }

  // ...........................................................................
  Future<void> initDirs() async {
    tmp = Directory.systemTemp.createTempSync('test_');
    d = Directory(join(tmp.path, 'test'));
    await d.create();
  }

  // ...........................................................................
  Future<void> initCommandAndRunner() async {
    runner = CommandRunner<void>('check', 'Check');

    testCmd = Tests(ggLog: (msg) => messages.add(rmControls(msg)));
    runner.addCommand(testCmd);
  }

  // ...........................................................................
  Future<void> pubGet() async {
    final r = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: join('sample_project'));
    expect(r.exitCode, 0);
  }

  // ...........................................................................
  Future<void> init() async {
    await initDirs();
    await initSampleProject();
    await initCommandAndRunner();
  }

  // ...........................................................................
  setUpAll(() async {
    await pubGet();
  });

  // ...........................................................................
  setUp(() async {
    await init();
  });

  // ...........................................................................
  tearDown(() async {
    try {
      await d.delete(recursive: true);
      await tmp.delete();
    } catch (_) {}
    messages.clear();
  });

  // ...........................................................................
  group('Test', () {
    group('run()', () {
      for (final pathType in pathTypes) {
        final isRelative = pathType == 'relative';
        String input() => isRelative ? '.' : sampleProject.path;

        group('with $pathType pathes', () {
          group('should throw', () {
            test(
              'if implementation files have not corresponding test files',
              () async {
                if (isRelative) Directory.current = sampleProject;

                // Delete test file
                testFile.deleteSync();

                // Run tests
                await expectLater(
                  runner.run(['tests', '--input', input()]),
                  throwsA(
                    isA<Exception>().having(
                      (e) => rmControls(e.toString()).split('\n'),
                      'message',
                      [
                        'Exception: Tests failed',
                        'Run "dart test" to see details.',
                      ],
                    ),
                  ),
                );
                expect(messages, [
                  '⌛️ Running "dart test"',
                  '✗ Running "dart test"',
                  [
                    'Tests were created. Please revise:',
                    '- test/simple_base_test.dart'.os,
                    '  lib/src/simple_base.dart'.os,
                  ].join(('\n')),
                ]);
              },
            );

            test(
              'if implementation files do not contain valid tests',
              () async {
                if (isRelative) Directory.current = sampleProject;
                // Comment out tests in test file
                final testFileWithoutTest = testFileContent
                    .replaceAll('expect', '// expect')
                    .replaceAll('final awesome', '// final awesome')
                    .replaceAll(
                      'import \'package:sample_project',
                      '// import \'package:sample_project',
                    );

                await testFile.writeAsString(testFileWithoutTest);

                // Run tests
                await expectLater(
                  runner.run(['tests', '--input', input()]),
                  throwsA(
                    isA<Exception>().having(
                      (e) => rmControls(e.toString()).split('\n'),
                      'message',
                      [
                        'Exception: Tests failed',
                        'Run "dart test" to see details.',
                      ],
                    ),
                  ),
                );

                // Expect exception
                expect(messages, [
                  '⌛️ Running "dart test"',
                  '✗ Running "dart test"',
                  [
                    'Please add valid tests to the following files:',
                    '- test/simple_base_test.dart'.os,
                    '  lib/src/simple_base.dart'.os,
                  ].join('\n'),
                ]);
              },
            );

            test(
              'if there are uncovered lines in implementation file',
              () async {
                if (isRelative) Directory.current = sampleProject;

                // Append some untested code to the implementation file
                srcFile.writeAsStringSync(
                  '${srcFile.readAsStringSync()}\nvoid bar() => print("bar");',
                );

                // Run tests
                await expectLater(
                  runner.run(['tests', '--input', input()]),
                  throwsA(
                    isA<Exception>().having(
                      (e) => rmControls(e.toString()).split('\n'),
                      'message',
                      [
                        'Exception: Tests failed',
                        'Run "dart test" to see details.',
                      ],
                    ),
                  ),
                );

                expect(messages[0], contains('⌛️ Running "dart test"'));
                expect(messages[1], contains('✗ Running "dart test"'));

                expect(
                  messages[2].os,
                  contains('Please fix missing coverage:'),
                );

                expect(
                  messages[2].os,
                  contains('- ${'lib/src/simple_base.dart:8'.os}'),
                );

                expect(
                  messages[2].os,
                  contains('  ${'test/simple_base_test.dart'.os}'),
                );
              },
            );

            test('if there failing unit tests', () async {
              // Add a failing test to test file
              if (isRelative) Directory.current = sampleProject;

              final modiefiedTestFile = testFileContent.replaceAll(
                '// PLACEHOLDER',
                'expect(1, 2);',
              );

              testFile.writeAsStringSync(modiefiedTestFile);

              // Run tests
              await expectLater(
                runner.run(['tests', '--input', input()]),
                throwsA(
                  isA<Exception>().having(
                    (e) => rmControls(e.toString()).split('\n'),
                    'message',
                    [
                      'Exception: Tests failed',
                      'Run "dart test" to see details.',
                    ],
                  ),
                ),
              );

              // Expect exception
              expect(messages[0], contains('⌛️ Running "dart test"'));
              expect(messages[1], contains('✗ Running "dart test"'));
              expect(
                messages[2],
                contains('- ${'test/simple_base_test.dart:17:7'.os}'),
              );
              expect(messages[2].os, contains('Expected: <2>'));
              expect(messages[2].os, contains('Actual: <1>'));
            });
          });

          group('should succeed', () {
            group('if implementation files have corresponding test files', () {
              test('and code coverage is 100%', () async {
                if (isRelative) Directory.current = sampleProject;
                await runner.run(['tests', '--input', input()]);
                expect(messages.last, contains('✓ Running "dart test"'));
              });
            });

            group('if not everything is coveraged, but', () {
              test('single lines are ignored from coverage', () async {
                final ignoreLine = await File(
                  join(sampleProject.path, 'lib', 'src', 'ignore_line.dart'),
                ).readAsString();
                expect(ignoreLine, contains('// coverage:ignore-line'));
              });

              test('files are ignored from coverage', () async {
                final ignoreLine = await File(
                  join(sampleProject.path, 'lib', 'src', 'ignore_file.dart'),
                ).readAsString();
                expect(ignoreLine, contains('// coverage:ignore-file'));
              });

              test('multiple lines are ignored from coverage', () async {
                final ignoreLine = await File(
                  join(sampleProject.path, 'lib', 'src', 'ignore_lines.dart'),
                ).readAsString();
                expect(ignoreLine, contains('// coverage:ignore-start'));
                expect(ignoreLine, contains('// coverage:ignore-end'));
              });
            });

            test('also for flutter tests', () async {
              testIsFlutter = true;

              // Run tests
              if (isRelative) {
                Directory.current = sampleProject;
              }

              await runner.run(['tests', '--input', input()]);

              // Check messages
              expect(
                messages[0],
                contains('⌛️ Running "flutter test --coverage"'),
              );
              expect(
                messages[1],
                contains('✓ Running "flutter test --coverage"'),
              );
            });
          });
        });
      }

      // .......................................................................
      group('for a project without implementation files', () {
        // Regression: an empty repo made the coverage check divide 0 by 0,
        // which yields NaN and therefore never equals 100.0. Additionally
        // listing the missing lib/src folder threw a PathNotFoundException
        // and "dart test" exits with 79 when it does not find any test.
        test('should succeed if there are no lib and no test folder', () async {
          Directory(
            join(sampleProject.path, 'lib'),
          ).deleteSync(recursive: true);
          Directory(
            join(sampleProject.path, 'test'),
          ).deleteSync(recursive: true);

          await runner.run(['tests', '--input', sampleProject.path]);

          expect(messages.last, contains('✓ Running "dart test"'));
        });

        test(
          'should succeed if there are tests but no lib/src folder',
          () async {
            Directory(
              join(sampleProject.path, 'lib', 'src'),
            ).deleteSync(recursive: true);
            File(
              join(sampleProject.path, 'lib', 'sample_project.dart'),
            ).writeAsStringSync('');

            final testDir = Directory(join(sampleProject.path, 'test'));
            testDir.deleteSync(recursive: true);
            testDir.createSync(recursive: true);
            File(join(testDir.path, 'standalone_test.dart')).writeAsStringSync(
              '''
import 'package:test/test.dart';

void main() {
  test('should work', () {
    expect(true, isTrue);
  });
}
''',
            );

            await runner.run(['tests', '--input', sampleProject.path]);

            expect(messages.last, contains('✓ Running "dart test"'));
          },
        );
      });

      // .......................................................................
      group('TypeScript dispatch', () {
        test(
          'delegates to the injected TypeScriptTestRunner for a TS project',
          () async {
            final tsDir = Directory.systemTemp.createTempSync('gg_test_ts_');
            File(join(tsDir.path, 'package.json')).writeAsStringSync('{}');
            File(join(tsDir.path, 'tsconfig.json')).writeAsStringSync('{}');

            final fakeRunner = _FakeTypeScriptTestRunner();
            final localRunner = CommandRunner<void>('test', 'test')
              ..addCommand(
                Tests(ggLog: messages.add, typeScriptTestRunner: fakeRunner),
              );

            try {
              await localRunner.run(['tests', '--input', tsDir.path]);
              expect(fakeRunner.invocations, 1);
              expect(fakeRunner.lastDirectory?.path, tsDir.path);
            } finally {
              tsDir.deleteSync(recursive: true);
            }
          },
        );

        test(
          'delegates to the TypeScriptTestRunner for a bridge repo',
          () async {
            // A bridge repo ships pubspec.yaml AND package.json + tsconfig.
            final bridgeDir = Directory.systemTemp.createTempSync(
              'gg_test_bridge_',
            );
            File(
              join(bridgeDir.path, 'pubspec.yaml'),
            ).writeAsStringSync('name: b\n');
            File(join(bridgeDir.path, 'package.json')).writeAsStringSync('{}');
            File(join(bridgeDir.path, 'tsconfig.json')).writeAsStringSync('{}');

            final fakeRunner = _FakeTypeScriptTestRunner();
            final localRunner = CommandRunner<void>('test', 'test')
              ..addCommand(
                Tests(ggLog: messages.add, typeScriptTestRunner: fakeRunner),
              );

            try {
              await localRunner.run(['tests', '--input', bridgeDir.path]);
              expect(fakeRunner.invocations, 1);
              expect(fakeRunner.lastDirectory?.path, bridgeDir.path);
            } finally {
              bridgeDir.deleteSync(recursive: true);
            }
          },
        );

        test('skips tests for a project without a manifest', () async {
          final noneDir = Directory.systemTemp.createTempSync('gg_test_none_');

          final fakeRunner = _FakeTypeScriptTestRunner();
          final localRunner = CommandRunner<void>('test', 'test')
            ..addCommand(
              Tests(ggLog: messages.add, typeScriptTestRunner: fakeRunner),
            );

          try {
            await localRunner.run(['tests', '--input', noneDir.path]);
            expect(fakeRunner.invocations, 0);
            expect(
              messages.last,
              contains('Skipping tests (no project manifest)'),
            );
          } finally {
            noneDir.deleteSync(recursive: true);
          }
        });

        test('propagates failures from the TypeScriptTestRunner', () async {
          final tsDir = Directory.systemTemp.createTempSync('gg_test_ts_');
          File(join(tsDir.path, 'package.json')).writeAsStringSync('{}');
          File(join(tsDir.path, 'tsconfig.json')).writeAsStringSync('{}');

          final fakeRunner = _FakeTypeScriptTestRunner(
            onRun: () => throw Exception('ts boom'),
          );
          final localRunner = CommandRunner<void>('test', 'test')
            ..addCommand(
              Tests(ggLog: messages.add, typeScriptTestRunner: fakeRunner),
            );

          try {
            await expectLater(
              () => localRunner.run(['tests', '--input', tsDir.path]),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  contains('ts boom'),
                ),
              ),
            );
          } finally {
            tsDir.deleteSync(recursive: true);
          }
        });
      });
    });

    group('coveragePackageArgs', () {
      late Directory pkgDir;

      setUp(() {
        pkgDir = Directory.systemTemp.createTempSync('gg_test_pkg_');
      });

      tearDown(() {
        pkgDir.deleteSync(recursive: true);
      });

      void writePubspec() {
        File(
          join(pkgDir.path, 'pubspec.yaml'),
        ).writeAsStringSync('name: my_pkg\n');
      }

      void writeLock(
        String testCoreVersion, {
        Directory? into,
        String lineEnding = '\n',
      }) {
        final content =
            '''
packages:
  test_core:
    dependency: transitive
    description:
      name: test_core
      sha256: "1234"
      url: "https://pub.dev"
    source: hosted
    version: "$testCoreVersion"
sdks:
  dart: ">=3.8.0 <4.0.0"
'''
                .replaceAll('\n', lineEnding);
        File(
          join((into ?? pkgDir).path, 'pubspec.lock'),
        ).writeAsStringSync(content);
      }

      test('returns scoped args when test_core supports the option', () {
        writePubspec();
        writeLock('0.6.15');
        expect(Tests.coveragePackageArgs(pkgDir), [
          '--coverage-package',
          '^my_pkg\$',
        ]);
      });

      test('returns an empty list when test_core is too old', () {
        writePubspec();
        writeLock('0.6.14');
        expect(Tests.coveragePackageArgs(pkgDir), isEmpty);
      });

      test('returns an empty list when the package name is unknown', () {
        writeLock('0.6.16');
        expect(Tests.coveragePackageArgs(pkgDir), isEmpty);
      });

      test('returns an empty list when no test_core version is found', () {
        writePubspec();
        // A lock file without a test_core entry ends the lookup within
        // the sandbox.
        File(
          join(pkgDir.path, 'pubspec.lock'),
        ).writeAsStringSync('packages:\n  args:\n    version: "2.4.2"\n');
        expect(Tests.coveragePackageArgs(pkgDir), isEmpty);
      });

      group('resolvedTestCoreVersion', () {
        test('reads the version from the package directory', () {
          writeLock('0.6.16');
          expect(Tests.resolvedTestCoreVersion(pkgDir), '0.6.16');
        });

        test('falls back to an ancestor directory (pub workspace)', () {
          writeLock('0.6.15', into: pkgDir);
          final memberDir = Directory(join(pkgDir.path, 'packages', 'member'))
            ..createSync(recursive: true);
          expect(Tests.resolvedTestCoreVersion(memberDir), '0.6.15');
        });

        test('parses lock files with CRLF line endings', () {
          writeLock('0.6.15', lineEnding: '\r\n');
          expect(Tests.resolvedTestCoreVersion(pkgDir), '0.6.15');
        });

        test('returns null when the lock file has no test_core entry', () {
          File(
            join(pkgDir.path, 'pubspec.lock'),
          ).writeAsStringSync('packages:\n  args:\n    version: "2.4.2"\n');
          expect(Tests.resolvedTestCoreVersion(pkgDir), isNull);
        });

        test('returns null when no pubspec.lock exists', () {
          // stopAt keeps the ancestor walk inside the test sandbox.
          expect(Tests.resolvedTestCoreVersion(pkgDir, stopAt: pkgDir), isNull);
        });
      });

      group('versionIsAtLeast', () {
        test('compares major, minor and patch parts', () {
          expect(Tests.versionIsAtLeast('0.6.15', '0.6.15'), isTrue);
          expect(Tests.versionIsAtLeast('0.6.16', '0.6.15'), isTrue);
          expect(Tests.versionIsAtLeast('0.7.0', '0.6.15'), isTrue);
          expect(Tests.versionIsAtLeast('1.0.0', '0.6.15'), isTrue);
          expect(Tests.versionIsAtLeast('0.6.14', '0.6.15'), isFalse);
          expect(Tests.versionIsAtLeast('0.5.20', '0.6.15'), isFalse);
        });

        test('ignores pre-release and build suffixes', () {
          expect(Tests.versionIsAtLeast('0.6.15-dev.1', '0.6.15'), isTrue);
          expect(Tests.versionIsAtLeast('0.6.16+2', '0.6.15'), isTrue);
        });

        test('returns false for unparseable versions', () {
          expect(Tests.versionIsAtLeast('any', '0.6.15'), isFalse);
          expect(Tests.versionIsAtLeast('0.6.15', 'any'), isFalse);
        });
      });

      group('is wired into the dart test invocation', () {
        late MockGgProcessWrapper wrapper;
        List<String>? capturedArgs;

        Future<void> runTestsCommand() async {
          // A minimal Dart package passing the missing-test-files check
          Directory(
            join(pkgDir.path, 'lib', 'src'),
          ).createSync(recursive: true);
          File(
            join(pkgDir.path, 'lib', 'src', 'foo.dart'),
          ).writeAsStringSync('void foo() {}\n');
          Directory(join(pkgDir.path, 'test')).createSync(recursive: true);
          File(
            join(pkgDir.path, 'test', 'foo_test.dart'),
          ).writeAsStringSync('void main() {}\n');

          wrapper = MockGgProcessWrapper();
          capturedArgs = null;

          when(
            () => wrapper.start(
              any(),
              any(),
              workingDirectory: any(named: 'workingDirectory'),
            ),
          ).thenAnswer((invocation) async {
            capturedArgs = invocation.positionalArguments[1] as List<String>;
            // Exit with an error to stop the command right after the
            // test process ran — coverage parsing is not part of this
            // test.
            return GgFakeProcess()..exit(1);
          });

          final localRunner = CommandRunner<void>('test', 'test')
            ..addCommand(Tests(ggLog: messages.add, processWrapper: wrapper));

          await expectLater(
            localRunner.run(['tests', '--input', pkgDir.path]),
            throwsA(isA<Exception>()),
          );
        }

        test('passes --coverage-package when test_core supports it', () async {
          writePubspec();
          writeLock('0.6.15');
          await runTestsCommand();
          expect(
            capturedArgs,
            containsAllInOrder(['--coverage-package', '^my_pkg\$']),
          );
        });

        test('omits --coverage-package when test_core is too old', () async {
          writePubspec();
          writeLock('0.6.14');
          await runTestsCommand();
          expect(capturedArgs, isNot(contains('--coverage-package')));
          expect(capturedArgs, contains('--coverage'));
        });
      });
    });

    group('isCoverageSourceForOwnFile', () {
      test('matches sources from the package itself', () {
        expect(
          Tests.isCoverageSourceForOwnFile(
            source: 'package:my_pkg/src/foo/bar.dart',
            packageName: 'my_pkg',
            implementationFileWithoutLib: 'src/foo/bar.dart',
          ),
          isTrue,
        );
      });

      test(
        'rejects sources from a dependency that share the relative path',
        () {
          // Regression: previously a permissive `contains` check meant a
          // coverage entry from a dependency with the same relative path
          // (and possibly more lines) got applied to the host package's
          // file, blowing up `_ignoredLines` with a RangeError.
          expect(
            Tests.isCoverageSourceForOwnFile(
              source: 'package:other_pkg/src/foo/bar.dart',
              packageName: 'my_pkg',
              implementationFileWithoutLib: 'src/foo/bar.dart',
            ),
            isFalse,
          );
        },
      );

      test('falls back to substring match when package name is unknown', () {
        expect(
          Tests.isCoverageSourceForOwnFile(
            source: 'package:other_pkg/src/foo/bar.dart',
            packageName: null,
            implementationFileWithoutLib: 'src/foo/bar.dart',
          ),
          isTrue,
        );
      });
    });
  });
}

// .............................................................................
/// A hand-written fake — simpler than a mocktail mock and keeps the test
/// assertions local and readable.
class _FakeTypeScriptTestRunner implements TypeScriptTestRunner {
  _FakeTypeScriptTestRunner({void Function()? onRun}) : _onRun = onRun;

  final void Function()? _onRun;
  int invocations = 0;
  Directory? lastDirectory;

  @override
  Future<void> run({
    required Directory directory,
    required void Function(String) ggLog,
  }) async {
    invocations++;
    lastDirectory = directory;
    _onRun?.call();
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final flutterLcovReport =
    '''
SF:lib/src/simple_base.dart
DA:5,1
LF:1
LH:1
end_of_record
SF:lib/src/ignore_line.dart
DA:7,1
LF:1
LH:1
end_of_record
SF:lib/src/ignore_lines.dart
DA:7,1
LF:1
LH:1
end_of_record
'''
        .os;
