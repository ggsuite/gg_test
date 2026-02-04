// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of the json package.

import { describe, expect, it } from '@jest/globals';
import { index } from '../src/index';

describe('index', () => {
  it('example should work', () => {
    const instance = index.example();
    expect(instance).toBeDefined();
  });
});
