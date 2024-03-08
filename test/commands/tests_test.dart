// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_is_flutter/gg_is_flutter.dart';
import 'package:gg_test/src/commands/tests.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

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
  const pathTypes = ['absolute']; // Add also "relative" from time to time

  // ...........................................................................
  tearDown(() {
    Directory.current = currentDir;
    testIsFlutter = null;
  });

  // ...........................................................................
  Future<void> initSampleProject() async {
    final src = Directory(join('sample_project'));
    sampleProject = Directory('${d.path}/sample_project');

    final r = await Process.run('cp', ['-r', src.path, sampleProject.path]);
    expect(r.exitCode, 0);
    expect(await sampleProject.exists(), isTrue);

    srcFile = File(
      join(sampleProject.path, 'lib', 'src', 'simple_base.dart'),
    );
    expect(srcFile.existsSync(), isTrue);

    testFile = File(
      join(sampleProject.path, 'test', 'simple_base_test.dart'),
    );
    expect(testFile.existsSync(), isTrue);
    testFileContent = await testFile.readAsString();
  }

  // ...........................................................................
  Future<void> initDirs() async {
    tmp = Directory.systemTemp.createTempSync('test_');
    d = Directory('${tmp.path}/test');
    await d.create();
  }

  // ...........................................................................
  Future<void> initCommandAndRunner() async {
    runner = CommandRunner<void>('check', 'Check');

    testCmd = Tests(log: messages.add);
    runner.addCommand(testCmd);
  }

  // ...........................................................................
  Future<void> pubGet() async {
    final r = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: join('sample_project'),
    );
    expect(r.exitCode, 0);
  }

  // ...........................................................................
  Future<void> init() async {
    await initDirs();
    await initSampleProject();
    await initCommandAndRunner();
  }

  // ...........................................................................
  setUpAll(
    () async {
      await pubGet();
    },
  );

  // ...........................................................................
  setUp(
    () async {
      testIsFlutter = null;
      await init();
    },
  );

  // ...........................................................................
  tearDown(
    () async {
      await d.delete(recursive: true);
      await tmp.delete();
      messages.clear();
    },
  );

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
                expect(await testFile.exists(), isFalse);

                // Run tests
                await expectLater(
                  runner.run(['tests', '--input', input()]),
                  throwsA(
                    isA<Exception>().having(
                      (e) => e.toString(),
                      'message',
                      contains(
                        'Exception: "dart test" failed. See log for details.',
                      ),
                    ),
                  ),
                );

                // Right logs should be written
                expect(messages[0], contains('⌛️ Running "dart test"'));
                expect(messages[1], contains('❌ Running "dart test"'));

                expect(
                  messages[2],
                  contains('${yellow}Tests were created. Please revise:'),
                );

                expect(
                  messages[2],
                  contains('${red}test/simple_base_test.dart$reset'),
                );

                expect(
                  messages[2],
                  contains('${brightBlack}lib/src/simple_base.dart$reset'),
                );

                // The test file should have been created
                expect(await testFile.exists(), isTrue);

                // The test file should include the implementation file
                final fileContent = await testFile.readAsString();
                expect(
                  fileContent,
                  contains(
                    'import \'package:sample_project/src/simple_base.dart\';',
                  ),
                );
              },
            );

            test('if implementation files do not contain valid tests',
                () async {
              // Comment out tests in test file
              final testFileWithoutTest = testFileContent
                  .replaceAll(
                    'expect',
                    '// expect',
                  )
                  .replaceAll(
                    'final awesome',
                    '// final awesome',
                  )
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
                    (e) => e.toString(),
                    'message',
                    contains(
                      'Exception: "dart test" failed. See log for details.',
                    ),
                  ),
                ),
              );

              // Expect exception
              expect(messages[0], contains('⌛️ Running "dart test"'));
              expect(messages[1], contains('❌ Running "dart test"'));
              expect(
                messages[2],
                contains(
                  '${yellow}Please add valid tests to the following files:',
                ),
              );
              expect(
                messages[2],
                contains(
                  '${yellow}Please add valid tests to the following files:',
                ),
              );

              expect(
                messages[2],
                contains(
                  '${red}test/simple_base_test.dart$reset',
                ),
              );

              expect(
                messages[2],
                contains(
                  '${blue}lib/src/simple_base.dart$reset',
                ),
              );
            });

            test('if there are uncovered lines in implementation file',
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
                    (e) => e.toString(),
                    'message',
                    contains(
                      'Exception: "dart test" failed. See log for details.',
                    ),
                  ),
                ),
              );

              expect(messages[0], contains('⌛️ Running "dart test"'));
              expect(messages[1], contains('❌ Running "dart test"'));

              expect(
                messages[2],
                contains('${yellow}Coverage not 100%. Untested code:$reset'),
              );

              expect(
                messages[2],
                contains('- ${red}lib/src/simple_base.dart:8$reset'),
              );

              expect(
                messages[2],
                contains('  ${blue}test/simple_base_test.dart$reset'),
              );
            });

            test('if there failing unit tests', () async {
              // Add a failing test to test file

              final modiefiedTestFile =
                  testFileContent.replaceAll('// PLACEHOLDER', 'expect(1, 2);');

              testFile.writeAsStringSync(modiefiedTestFile);

              // Run tests
              await expectLater(
                runner.run(['tests', '--input', input()]),
                throwsA(
                  isA<Exception>().having(
                    (e) => e.toString(),
                    'message',
                    contains(
                      'Exception: "dart test" failed. See log for details.',
                    ),
                  ),
                ),
              );

              // Expect exception
              expect(messages[0], contains('⌛️ Running "dart test"'));
              expect(messages[1], contains('❌ Running "dart test"'));
              expect(
                messages[2],
                contains('$red./test/simple_base_test.dart:17:7$reset'),
              );
              expect(
                messages[2],
                contains('Expected: <2>'),
              );
              expect(
                messages[2],
                contains('Actual: <1>'),
              );
            });
          });

          group('should succeed', () {
            group('if implementation files have corresponding test files', () {
              test('and code coverage is 100%', () async {
                if (isRelative) Directory.current = sampleProject;
                await runner.run(['tests', '--input', input()]);
                expect(messages.last, contains('✅ Running "dart test"'));
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
              if (isRelative) Directory.current = sampleProject;
              await runner.run(['tests', '--input', input()]);

              // Check messages
              expect(
                messages[0],
                contains('⌛️ Running "flutter test --coverage"'),
              );
              expect(
                messages[1],
                contains('✅ Running "flutter test --coverage"'),
              );
            });
          });
        });
      }
    });
  });
}
