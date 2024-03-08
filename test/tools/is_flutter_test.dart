// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_test/src/tools/is_flutter.dart';
import 'package:test/test.dart';

void main() {
  final currentDir = Directory.current;

  setUp(() {
    testResetIsFlutter();
  });

  tearDown(() {
    Directory.current = currentDir;
  });

  group('IsFlutter', () {
    test('should work fine', () {
      // const IsFlutter();
      expect(isFlutter, isFalse);
    });

    group('should throw', () {
      test('if pubspec.yaml not found', () {
        final tmp = Directory.systemTemp.createTempSync();
        Directory.current = tmp;
        expect(
          () => isFlutter,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: pubspec.yaml not found',
            ),
          ),
        );
      });
    });
  });
}
