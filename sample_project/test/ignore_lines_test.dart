// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:sample_project/sample_project.dart';
import 'package:test/test.dart';

void main() {
  group('UncoveredLintes', () {
    test('should work fine', () {
      expect(ignoreLines(false), 'foo');
    });
  });
}
