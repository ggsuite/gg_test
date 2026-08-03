// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_test/gg_test.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  // ...........................................................................
  Directory createDir(String path) =>
      Directory(join(tmp.path, path))..createSync(recursive: true);

  // ...........................................................................
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('output_root_test_');
    tmp = Directory(tmp.resolveSymbolicLinksSync());
  });

  // ...........................................................................
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('OutputRoot', () {
    group('get(packageDir)', () {
      test('returns the current directory when it is the package', () {
        final package = createDir('ggsuite/gg_one');

        final root = const OutputRoot().get(
          package,
          currentDirectory: package,
        )!;

        expect(canonicalize(root.path), canonicalize(package.path));
      });

      test('returns the current directory when it contains the package', () {
        final workspace = createDir('tickets/82');
        final package = createDir('tickets/82/ggsuite/gg_one');

        final root = const OutputRoot().get(
          package,
          currentDirectory: workspace,
        )!;

        expect(canonicalize(root.path), canonicalize(workspace.path));

        // The prefix a caller derives from it
        expect(
          relative(canonicalize(package.path), from: root.path),
          'ggsuite/gg_one'.os,
        );
      });

      test('returns the folder of the closest *.code-workspace file', () {
        final workspace = createDir('tickets/82');
        final package = createDir('tickets/82/ggsuite/gg_one');
        File(join(workspace.path, '82.code-workspace')).writeAsStringSync('{}');

        final root = const OutputRoot().get(
          package,
          // The current directory is not related to the package
          currentDirectory: createDir('somewhere/else'),
        )!;

        expect(canonicalize(root.path), canonicalize(workspace.path));
      });

      test('returns null when neither applies', () {
        final package = createDir('ggsuite/gg_one');

        expect(
          const OutputRoot().get(
            package,
            currentDirectory: createDir('somewhere/else'),
          ),
          isNull,
        );
      });

      test('ignores directories that do not exist', () {
        final package = Directory(join(tmp.path, 'does', 'not', 'exist'));

        expect(
          const OutputRoot().get(
            package,
            currentDirectory: createDir('somewhere/else'),
          ),
          isNull,
        );
      });

      test('uses Directory.current by default', () {
        final current = Directory.current;
        final root = const OutputRoot().get(current)!;
        expect(canonicalize(root.path), canonicalize(current.path));
      });
    });
  });
}
