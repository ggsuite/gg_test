<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Skip coverage of tests that do not run on this platform

## Motivation

- gg_test demands that every implementation file is covered by its test
  file
- Some test files are bound to a platform with a file-level `@TestOn`, e.g.
  `@TestOn('mac-os')` for code that calls macOS APIs
- On other platforms such a test file never runs and leaves no coverage
- On Windows the check therefore reported "The test files exist but
  produced no coverage for their implementation file", although nothing
  was left untested
- The coverage check has to judge only what can run on the current platform

## Strategy

- Find out whether a test file runs on the current platform at all
- Read its `@TestOn` the way package:test does on the Dart VM
- Ignore implementation files whose test file does not run here
- Keep the rest of the coverage check unchanged
- Offer the decision as a public function, so it can be reused and tested

## Implementation 1: runsOnPlatform

- New file `lib/src/tools/runs_on_platform.dart`, exported by the package
- `runsOnPlatform(testCode, {operatingSystem})` finds the file-level
  `@TestOn(selector)` with a regular expression
- It evaluates the selector with package:boolean_selector
- True are `vm`, `dart-vm`, the operating system and, on all platforms but
  Windows, `posix`
- The operating system `macos` is named `mac-os`, as in package:test
- Browser selectors are false, the VM never runs them
- A file without `@TestOn` runs everywhere
- A selector that does not parse counts as running; package:test reports
  it anyway

## Implementation 2: Coverage check

- `_findUntestedFiles` in `lib/src/commands/tests.dart` now asks the new
  `_runsHere` for the test file of each implementation file
- An implementation file whose test file does not run here is ignored,
  like files with `coverage:ignore-file` or without functions
- A missing test file counts as running, so it is still asked for
- On the platforms a test file names, nothing changes

## Implementation 3: Tests and documentation

- `test/tools/runs_on_platform_test.dart` covers files without annotation,
  file-level selectors in single and double quotes, `posix` and the VM, a
  browser selector, a `testOn` of a single test, an unparsable selector,
  and the current platform as default
- The README explains which files are not asked for coverage; after the
  review it also names `runsOnPlatform`

## Dependency updates

- New dependency `boolean_selector: ^2.1.2`; it already came in
  transitively through package:test
- gg_process starts commands the PATH holds only as `.bat` or `.cmd`
  through the shell on Windows; `dart test`, which gg_test starts through
  `GgProcessWrapper`, now starts also when `dart` is the `dart.bat` of the
  Flutter SDK
- This arrives with the next release of gg_process, within `^1.3.0`
- dna_ggsuite ^1.0.0 brings the `/gg-review` skill, a blog guide that
  writes to `doc/blog/<yyyy>`, a README guide with
  `scripts/check-readme.js`, and moves the GitHub setup guide to
  `doc/guides/`

## Result

- Repos with platform-specific test files pass the coverage check on
  every platform
- The checks of this repo pass on Windows with full coverage

## Open Points

- Only the file-level `@TestOn` is considered; a `testOn` of a single test
  or group is not evaluated, so its file is still asked for coverage
- An implementation file whose test runs on one platform only is covered
  only there; coverage of several platforms is not merged
