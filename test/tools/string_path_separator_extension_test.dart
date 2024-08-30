// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  group('StringPathSeparatorExtension', () {
    test('should work for / separator', () {
      GgTestStringPathSeparatorExtensions.nextTestSeparator = '/';
      expect('x/y/z'.os, 'x/y/z');

      GgTestStringPathSeparatorExtensions.nextTestSeparator = '/';
      expect(r'x\y\z'.os, 'x/y/z');

      expect(GgTestStringPathSeparatorExtensions.nextTestSeparator, isNull);
    });

    test('should work for \\ separator', () {
      GgTestStringPathSeparatorExtensions.nextTestSeparator = r'\';
      expect('x/y/z'.os, r'x\y\z');

      GgTestStringPathSeparatorExtensions.nextTestSeparator = r'\';
      expect(r'x\y\z'.os, r'x\y\z');
    });
  });
}
