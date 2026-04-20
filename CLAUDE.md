# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this package is

`gg_test` is a Dart CLI (package + executable) that wraps `dart test` / `flutter test --coverage` to enforce 100% code coverage with concise, VSCode-clickable error output. It is consumed as a dev dependency in other Dart/Flutter packages and invoked via `dart run gg_test tests`.

## Common commands

- Run the tool against the current package: `dart run gg_test tests`
- Run this package's own tests: `dart test`
- Run a single test file: `dart test test/commands/tests_test.dart`
- Run a single test by name: `dart test -n "<test name substring>"`
- Static analysis: `dart analyze`
- Format: `dart format .`
- Pre-push verification (used by the `gg` toolchain): `dart run .gg/verify_push.dart`

`check.yaml` declares which of analyze/format/tests/pana should run for this package's CI gate; `pana` is off.

## Architecture

Entry point is `bin/gg_test.dart`, which wires `GgTest` into `GgCommandRunner` from `gg_args`. `GgTest` (lib/src/gg_test.dart) is a thin `Command` that registers a single subcommand: `Tests`.

`Tests` (lib/src/commands/tests.dart) is where all the logic lives. It extends `DirCommand` and:

1. Detects Flutter vs pure Dart via `isFlutterDir` from `gg_is_flutter` and dispatches to `_testFlutter` or `_testDart`.
2. Runs the test process through an injectable `GgProcessWrapper` (from `gg_process`) so tests can mock I/O. `--coverage coverage` is passed for Dart; `--coverage` for Flutter.
3. Streams stdout through `ErrorInfoReader` (lib/src/tools/error_info_reader.dart) which rewrites test failure locations into VSCode-clickable `file:line:col` form and deduplicates the noisy parts of stack traces.
4. Parses coverage: Flutter reads `coverage/lcov.info` directly; pure Dart walks `coverage/**/*.dart.vm.json` files, maps each test path back to its `lib/src` implementation, and builds an internal `_Report = Map<file, Map<line, hits>>`. For pure Dart, `_writeLcovReport` then emits a combined `coverage/lcov.info` so downstream tools see a uniform format.
5. Applies coverage exclusions: `coverage:ignore-file`, `coverage:ignore-start` / `coverage:ignore-end`, `coverage:ignore-line` (parsed in `_ignoredLines`), plus the static `foldersExcludedFromCoverage` list (currently `l10n`).
6. Enforces structural rules before checking coverage percent:
   - Every `lib/src/**/foo.dart` must have a matching `test/**/foo_test.dart`. Missing test files are auto-generated from `_testBoilerplate` and the run fails with a yellow "Please revise" message.
   - Files with no function/method definitions (checked via `hasFunctions` in lib/src/tools/has_functions.dart) or marked `coverage:ignore-file` are skipped when looking for untested files.
7. Fails the run (exit 1, throws `Exception`) if any test fails, any implementation file is untested, or coverage is not exactly 100%. Missing lines are printed as `file:line` (red) with a paired clickable test-file path (blue).

Path handling is Windows-aware via the `.os` extension in lib/src/tools/string_path_separator_extension.dart — use it whenever comparing or constructing paths that mix forward/backward slashes.

The `library` surface (lib/gg_test.dart) re-exports `Tests`, `GgTest`, `ErrorInfoReader`, `hasFunctions`, and the path extension. A `MockTests` (mocktail) is exported from tests.dart for downstream consumers.

## Testing conventions enforced on this repo

Because this package runs itself through its own coverage gate, every file under `lib/src/` needs a mirrored `test/` file, and untested lines must be annotated with `// coverage:ignore-line` (or a range/file marker) — otherwise `dart run gg_test tests` will fail locally and in CI. `sample_project/` is excluded from analysis (see `analysis_options.yaml`).

## Lints

`analysis_options.yaml` enables strict-casts / strict-inference / strict-raw-types and requires `public_member_api_docs`, `lines_longer_than_80_chars`, `prefer_single_quotes`, `require_trailing_commas`, and `always_declare_return_types` as an error. New public API without a doc comment will break `dart analyze`.
