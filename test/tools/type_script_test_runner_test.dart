// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_process/gg_process.dart';
import 'package:gg_test/src/tools/type_script_test_runner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  late Directory tmp;
  late MockGgProcessWrapper processWrapper;

  setUp(() {
    messages.clear();
    tmp = Directory.systemTemp.createTempSync('gg_test_ts_runner_');
    File(join(tmp.path, 'package.json')).writeAsStringSync('{}');
    File(join(tmp.path, 'tsconfig.json')).writeAsStringSync('{}');
    processWrapper = MockGgProcessWrapper();
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  void stubRun(ProcessResult result) {
    when(
      () => processWrapper.run(
        any(),
        any(),
        workingDirectory: any(named: 'workingDirectory'),
        runInShell: any(named: 'runInShell'),
      ),
    ).thenAnswer((_) async => result);
  }

  List<dynamic> captureRun() => verify(
    () => processWrapper.run(
      captureAny(),
      captureAny(),
      workingDirectory: captureAny(named: 'workingDirectory'),
      runInShell: any(named: 'runInShell'),
    ),
  ).captured;

  group('TypeScriptTestRunner', () {
    test('runs "pnpm exec vitest run --coverage" on a pnpm project', () async {
      File(join(tmp.path, 'pnpm-lock.yaml')).writeAsStringSync('');
      stubRun(ProcessResult(1, 0, '', ''));

      final runner = TypeScriptTestRunner(processWrapper: processWrapper);
      await runner.run(directory: tmp, ggLog: messages.add);

      final captured = captureRun();
      expect(captured[0], 'pnpm');
      expect(captured[1], ['exec', 'vitest', 'run', '--coverage']);
      expect(captured[2], tmp.path);
      expect(messages[0], contains('⌛️ Running "vitest run --coverage"'));
      expect(messages[1], contains('✅ Running "vitest run --coverage"'));
    });

    test('runs "yarn vitest run --coverage" on a yarn project', () async {
      File(join(tmp.path, 'yarn.lock')).writeAsStringSync('');
      stubRun(ProcessResult(1, 0, '', ''));

      final runner = TypeScriptTestRunner(processWrapper: processWrapper);
      await runner.run(directory: tmp, ggLog: messages.add);

      final captured = captureRun();
      expect(captured[0], 'yarn');
      expect(captured[1], ['vitest', 'run', '--coverage']);
    });

    test(
      'falls back to "npx vitest run --coverage" without a lockfile',
      () async {
        stubRun(ProcessResult(1, 0, '', ''));

        final runner = TypeScriptTestRunner(processWrapper: processWrapper);
        await runner.run(directory: tmp, ggLog: messages.add);

        final captured = captureRun();
        expect(captured[0], 'npx');
        expect(captured[1], ['vitest', 'run', '--coverage']);
      },
    );

    test('runs the package.json "test" script when one is defined', () async {
      File(join(tmp.path, 'pnpm-lock.yaml')).writeAsStringSync('');
      File(
        join(tmp.path, 'package.json'),
      ).writeAsStringSync('{"scripts":{"test":"vitest run && dart test"}}');
      stubRun(ProcessResult(1, 0, '', ''));

      final runner = TypeScriptTestRunner(processWrapper: processWrapper);
      await runner.run(directory: tmp, ggLog: messages.add);

      final captured = captureRun();
      expect(captured[0], 'pnpm');
      expect(captured[1], ['run', 'test']);
      expect(captured[2], tmp.path);
      expect(messages[0], contains('⌛️ Running "pnpm run test"'));
      expect(messages[1], contains('✅ Running "pnpm run test"'));
    });

    test('throws and echoes tool output when vitest exits non-zero', () async {
      File(join(tmp.path, 'pnpm-lock.yaml')).writeAsStringSync('');
      stubRun(ProcessResult(1, 1, 'FAIL  src/foo.spec.ts > bar', ''));

      final runner = TypeScriptTestRunner(processWrapper: processWrapper);
      await expectLater(
        () => runner.run(directory: tmp, ggLog: messages.add),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Tests failed'),
          ),
        ),
      );
      expect(messages, contains('FAIL  src/foo.spec.ts > bar'));
    });

    test('defaults processWrapper when not provided', () {
      const runner = TypeScriptTestRunner();
      expect(runner.processWrapper, isA<GgProcessWrapper>());
    });

    test('example provides a real, usable instance', () {
      expect(TypeScriptTestRunner.example(), isA<TypeScriptTestRunner>());
    });
  });
}
