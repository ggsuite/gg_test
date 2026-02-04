// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { describe, expect, it } from 'vitest';

import { copy } from '../src/copy';

describe('copy, copyList', () => {
  it('empty json', () => {
    expect(copy({})).toEqual({});
  });

  it('simple value', () => {
    expect(copy({ a: 1 })).toEqual({ a: 1 });
  });

  it('nested value', () => {
    expect(
      copy({
        a: { b: 1 },
      }),
    ).toEqual({
      a: { b: 1 },
    });
  });

  it('list value', () => {
    expect(
      copy({
        a: [1, 2],
      }),
    ).toEqual({
      a: [1, 2],
    });
  });

  it('list with list', () => {
    expect(
      copy({
        a: [[1, 2]],
      }),
    ).toEqual({
      a: [[1, 2]],
    });
  });

  it('list with map', () => {
    expect(
      copy({
        a: [{ b: 1 }],
      }),
    ).toEqual({
      a: [{ b: 1 }],
    });
  });

  it('null value', () => {
    expect(
      copy({
        a: null,
        b: [1, null, 2],
      }),
    ).toEqual({
      a: null,
      b: [1, null, 2],
    });
  });

  it('undefined value', () => {
    expect(
      copy({
        a: undefined,
        b: [1, undefined, 2],
      }),
    ).toEqual({
      a: undefined,
      b: [1, undefined, 2],
    });
  });

  describe('throws', () => {
    describe('on unsupported type', () => {
      it('in map', () => {
        let message = '';
        try {
          copy({
            a: new Error() as any,
          });
        } catch (e: any) {
          message = e.toString();
        }

        expect(message).toEqual('Error: Unsupported type: object');
      });

      it('in list', () => {
        let message: string = '';
        try {
          copy({
            a: [new Error() as any],
          });
        } catch (e: any) {
          message = e.toString();
        }

        expect(message).toEqual('Error: Unsupported type: object');
      });
    });
  });
});
