// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: avoid_relative_lib_imports

import 'package:sample_project/sample_project.dart';
import 'package:test/test.dart';

void main() {
  group('ClassWithoutMethods', () {
    test('foo', () {
      expect(ClassWithoutMethods.foo, 10);
    });
  });
}
