// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { describe, expect, it } from 'vitest';

import { exampleJsonArray } from '../src/json-array';
import { JsonArray } from '../src/json-array.ts';

import { expectGolden } from './setup/goldens.ts';

describe('JsonArray', () => {
  it('exampleJsonArray()', () => {
    expectGolden('json-array/example-json-array.json').toBe(exampleJsonArray());
  });

  it('string', () => {
    const val: JsonArray = ['hello'];
    expect(val).toEqual(['hello']);
  });

  it('number', () => {
    const val: JsonArray = [10];
    expect(val).toEqual([10]);
  });

  it('boolean', () => {
    const val: JsonArray = [true];
    expect(val).toEqual([true]);
  });

  it('null', () => {
    const val: JsonArray = [null];
    expect(val).toEqual([null]);
  });

  it('Json', () => {
    const val: JsonArray = [{ key: 'value' }];
    expect(val).toEqual([{ key: 'value' }]);
  });
});
