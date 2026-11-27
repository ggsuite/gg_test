<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Run the tests without DDS, with a given concurrency

## Motivation

- `Tests` assumed that a test run has the machine for itself. Testing
  several directories at the same time ran into three problems.
- A run keeps its messages and folders in the fields of the instance. Two
  runs on one instance shared them, and a run could report the messages of
  the one before.
- On a busy machine a test file could fail to load with »Connection closed
  before full header was received«, and now and then the run never ended.
- Every run let the test runner take half of the processors. Several runs
  together started a multiple of the test files the machine can serve, and
  tests that start processes ran into their 30 s timeout.

## Strategy

- Give every run an instance of its own, so runs cannot disturb each other.
- Start the Dart test runner without the Dart Development Service (DDS).
- Let the caller say how many test files a run starts at the same time.
- Let the caller say how much longer a test may take next to other runs.
- Keep both options optional: a caller that tests one directory changes
  nothing.

## An instance per run

- `Tests.get()` creates a fresh `Tests` instance for every call and runs
  there. Its signature is unchanged.
- So one shared instance can test several directories at the same time.
- The details of a failed run go to the `ggLog` handed to `get()`. They
  appear next to the status line of that run, also when several runs log
  at the same time.

## Dart tests without DDS

- A Dart package is now tested with `dart run --no-dds test:test`
  (`Tests.dartTestRunnerArgs`). It is the runner `dart test` starts, minus
  DDS. Only `dart run` takes `--no-dds`.
- To gather coverage the runner connects to the VM service of its own
  process for every test file.
- DDS takes that service over once it is up, and cuts the connections that
  are being opened at that moment.
- On an idle machine DDS is up before the first test file loads. On a busy
  one it comes up while files load.
- Measured with 11 suites started at once: 3 failed to load a test file,
  and one of them never ended. Without DDS: none.

## Concurrency and timeout factor

- `Tests(concurrency:)` is a function that is asked when a run starts. Its
  answer becomes `--concurrency=<n>`, for Dart and Flutter. An answer below
  one becomes one.
- Null leaves the choice to the test runner, which takes half of the
  processors.
- `Tests(timeoutFactor:)` is asked as well. `n` becomes `--timeout=<n>x`
  for a Dart package, so a test may take `n` times its usual time.
- Null or one leaves the timeouts alone.
- A timeout is set for a machine the run has for itself. Next to other
  runs, a test that needs ten seconds alone ran into its 30.

## Open Points

- `timeoutFactor` applies to Dart packages only, not to Flutter projects.
- TypeScript test runs take neither option.
- Both options exist in the Dart API only. The command line has no flags
  for them.
