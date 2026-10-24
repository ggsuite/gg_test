// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test/gg_test.dart';
import 'package:test/test.dart';

void main() {
  group('runsOnPlatform(testCode, operatingSystem)', () {
    test('is true for a test file without @TestOn', () {
      expect(
        runsOnPlatform('void main() {}', operatingSystem: 'windows'),
        isTrue,
      );
    });

    test('follows the selector of a file-level @TestOn', () {
      const mac = "@TestOn('mac-os')\nlibrary;\n";
      expect(runsOnPlatform(mac, operatingSystem: 'macos'), isTrue);
      expect(runsOnPlatform(mac, operatingSystem: 'windows'), isFalse);

      const notWindows = '@TestOn("!windows")\nlibrary;\n';
      expect(runsOnPlatform(notWindows, operatingSystem: 'linux'), isTrue);
      expect(runsOnPlatform(notWindows, operatingSystem: 'windows'), isFalse);
    });

    test('knows posix and the VM', () {
      const posix = "@TestOn('posix && vm')\nlibrary;\n";
      expect(runsOnPlatform(posix, operatingSystem: 'linux'), isTrue);
      expect(runsOnPlatform(posix, operatingSystem: 'windows'), isFalse);
      const browser = "@TestOn('browser')\nlibrary;\n";
      expect(runsOnPlatform(browser, operatingSystem: 'linux'), isFalse);
    });

    test('ignores a testOn of a single test', () {
      const code = "test('x', () {}, testOn: 'mac-os');";
      expect(runsOnPlatform(code, operatingSystem: 'windows'), isTrue);
    });

    test('lets package:test report a selector it cannot parse', () {
      const broken = "@TestOn('mac-os &&')\nlibrary;\n";
      expect(runsOnPlatform(broken, operatingSystem: 'windows'), isTrue);
    });

    test('takes the current platform by default', () {
      expect(runsOnPlatform("@TestOn('vm')\nlibrary;\n"), isTrue);
    });
  });
}
