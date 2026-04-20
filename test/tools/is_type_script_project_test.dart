// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_test/src/tools/is_type_script_project.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gg_test_is_ts_');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  group('isTypeScriptProject', () {
    test('true when package.json + tsconfig.json are present', () {
      File(join(tmp.path, 'package.json')).writeAsStringSync('{}');
      File(join(tmp.path, 'tsconfig.json')).writeAsStringSync('{}');
      expect(isTypeScriptProject(tmp), isTrue);
    });

    test('false when tsconfig.json is missing', () {
      File(join(tmp.path, 'package.json')).writeAsStringSync('{}');
      expect(isTypeScriptProject(tmp), isFalse);
    });

    test('false when package.json is missing', () {
      File(join(tmp.path, 'tsconfig.json')).writeAsStringSync('{}');
      expect(isTypeScriptProject(tmp), isFalse);
    });

    test('false when pubspec.yaml is present (Dart/Flutter wins)', () {
      File(join(tmp.path, 'pubspec.yaml')).writeAsStringSync('name: foo\n');
      File(join(tmp.path, 'package.json')).writeAsStringSync('{}');
      File(join(tmp.path, 'tsconfig.json')).writeAsStringSync('{}');
      expect(isTypeScriptProject(tmp), isFalse);
    });

    test('false for empty directory', () {
      expect(isTypeScriptProject(tmp), isFalse);
    });

    test('true against the real rljson fixture', () {
      final realProject = Directory(
        'P:/workspace_grace_cloud/tickets/'
        'feat-gg-typescript/real_testproject_rljson',
      );
      if (!realProject.existsSync()) return;
      expect(isTypeScriptProject(realProject), isTrue);
    });
  });
}
