<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Skip Coverage of Tests That Do Not Run on This Platform

## Motivation

- gg's coverage check demands that every implementation file is covered by
  its test file.
- Some test files are restricted to a platform with a file-level
  `@TestOn('mac-os')`, `@TestOn('!windows')` or `@TestOn('linux')`.
- Such test files never run on other platforms, so they produce no coverage
  there.
- On Windows gg therefore reported "Please add valid tests ... The test
  files exist but produced no coverage for their implementation file".
- This hit e.g. the Apple-native files of aud_midi_apple.
- The goal: gg checks work on Windows for platform-specific repos, too.

## Strategy

- Find out whether a test file runs on the current platform at all.
- Do this the same way package:test does on the VM.
- Ignore implementation files whose test file does not run here.
- Keep everything else of the coverage check unchanged.

## Implementation 1: runsOnPlatform

- New file `lib/src/tools/runs_on_platform.dart`, exported by the package.
- `runsOnPlatform(testCode, {operatingSystem})` reads the file-level
  `@TestOn(selector)` with a regex.
- It evaluates the selector with package:boolean_selector.
- Known variables are `vm`, `dart-vm`, the operating system and `posix`
  on all platforms except Windows.
- The operating system name `macos` is mapped to `mac-os`, like
  package:test does.
- An unparsable selector counts as running, package:test reports it anyway.
- Files without `@TestOn` always run.

## Implementation 2: Coverage check

- In `lib/src/commands/tests.dart`, `_findUntestedFiles` now asks
  `_runsHere` for each test file.
- Implementation files whose test file does not run here are ignored.
- On macOS and Linux nothing changes for these files.

## Implementation 3: Dependency and tests

- New dependency `boolean_selector: ^2.1.0`.
- It was already a transitive dependency via package:test.
- New tests in `test/tools/runs_on_platform_test.dart` cover files without
  annotation, file-level selectors, `posix` and the VM, a `testOn` of a
  single test, unparsable selectors and the current platform as default.

## Result

- aud_midi_apple, aud_midi_linux and other platform-specific repos pass
  `gg one can commit` on Windows.
- gg_test keeps its 100% coverage.

## Open Points

- Only the file-level `@TestOn` annotation is considered.
- A `testOn` parameter of a single test or group is not evaluated.
