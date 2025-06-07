#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Create an exe and install it in the system.
/// This is a simple way to install the package as command line tool.
library;

import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';

// #############################################################################
void main() {
  const exe = 'gg_test';

  print('Installing $exe globally');
  final result = Process.runSync('dart', [
    'pub',
    'global',
    'activate',
    '--source',
    'path',
    '.',
  ]);

  if (result.stderr.toString().trim().isNotEmpty) {
    print(red('❌ ${result.stderr.toString().trim()}'));
    return;
  }
  print(green('✅ Installed $exe.'));
}
