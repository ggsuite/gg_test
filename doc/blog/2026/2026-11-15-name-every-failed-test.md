<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Name every failed test, also without a file location

## Motivation

- `Tests` shows a failed test by the location of its error, as a link an
  editor can open. It found that location in the stack trace: the first
  line that names a file of the package.
- Not every failure has such a line. A test that runs into its timeout, a
  test file that does not load and an error thrown inside the SDK name no
  file of the package.
- Such a run ended with nothing but »Tests failed«. The developer had to
  run `dart test` by hand to learn which test failed and why.
- The same happened when the test runner itself ended early with an error
  code: nothing said what went wrong.

## Strategy

- Report by failed test, not by location: every test the runner marks as
  failed gets a message, with a location when there is one.
- Read the output as a whole after the run instead of line by line, so a
  failure is shown with its own error and not with lines of its
  neighbours.
- Read stderr as well, from the start, so no pipe fills up and nothing
  the run says is lost.
- When the run fails and no message explains it, show how it ended.

## Failed tests in ErrorInfoReader

- `failedTests` splits the output of the expanded reporter into the
  failed tests: the line the runner marks with `[E]`, and everything it
  printed up to the next progress line.
- A `FailedTest` has the `name` of the test as the runner prints it —
  `loading test/foo_test.dart` for a file that does not load — its
  `lines`, and `details`: the error and its stack trace without the line
  naming the test and without empty lines.
- `linesOutsideFailedTests` gives the rest of the output, for the
  messages that belong to no single test.

## Evaluating a run in Tests

- `_evaluateTestRun` replaces the line-by-line `_processTestOutput`. It
  reads stdout and stderr, waits for the exit code and then evaluates.
- `_noteFailedTests` writes one message per failed test. With a location
  it is the link as before. Without one it is the name of the test and
  the first six lines of its error; more lines are announced by `…`.
- `_noteUnexplainedExit` covers a run that ends with an error code
  although no failed test was named: it shows the exit code and the last
  six lines of stdout and of stderr.
- A run fails when the exit code is not zero or a failed test was found.

## Tests

- A timeout, a test file that throws while loading and an error without a
  stack trace line of the package are each reported with the name of the
  test.
- Two failures in one run show their own errors only.
- A run that exits with an error code and names no test shows the exit
  code and the end of its output.
- The README names the new behaviour, `index.jsonc` and `CLAUDE.md`
  follow.

## Open Points

- Only the expanded reporter of the Dart and Flutter test runners is
  split into failed tests. The output of a TypeScript run is shown as
  before.
- Six lines are a fixed limit. A failure whose cause stands further down
  still needs a run by hand.
