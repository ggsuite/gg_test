// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of the json package.

import { describe, expect, it } from '@jest/globals';
import { merge } from '../src/merge';

describe('merge', () => {
  it('example should work', () => {
    const instance = merge.example();
    expect(instance).toBeDefined();
  });
});
