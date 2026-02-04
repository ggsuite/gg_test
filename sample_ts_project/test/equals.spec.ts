// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { describe, expect, it } from 'vitest';

import { equals } from '../src/equals';


describe('equals', () => {
  it('with integers', () => {
    expect(equals(1, 1)).toBe(true);
    expect(equals(1, 2)).toBe(false);
  });

  it('with floats', () => {
    // Todo: Precision noch angeben, ansonsten wird es nicht funktionieren
    expect(equals(1.1, 1.1)).toBe(true);
    expect(equals(1.1, 1.2)).toBe(false);
  });

  it('with strings', () => {
    expect(equals('a', 'a')).toBe(true);
    expect(equals('a', 'b')).toBe(false);
  });

  it('with booleans', () => {
    expect(equals(true, true)).toBe(true);
    expect(equals(true, false)).toBe(false);
  });

  it('with null', () => {
    expect(equals(null, null)).toBe(true);
    expect(equals(null, 0)).toBe(false);
  });

  describe('with arrays', () => {
    it('that are empty', () => {
      expect(equals([], [])).toBe(true);
      expect(equals([], [1])).toBe(false);
    });

    it('containing strings', () => {
      expect(equals(['a', 'b'], ['a', 'b'])).toBe(true);
      expect(equals(['a', 'b'], ['a', 'c'])).toBe(false);
    });

    it('containing numbers', () => {
      expect(equals([1, 2], [1, 2])).toBe(true);
      expect(equals([1, 2], [1, 3])).toBe(false);
    });

    it('containing booleans', () => {
      expect(equals([true, false], [true, false])).toBe(true);
      expect(equals([true, false], [true, true])).toBe(false);
    });

    it('containing null', () => {
      expect(equals([null, null], [null, null])).toBe(true);
      expect(equals([null, null], [null, 0])).toBe(false);
    });

    it('containing arrays', () => {
      expect(equals([[1], [2]], [[1], [2]])).toBe(true);
      expect(equals([[1], [2]], [[1], [3]])).toBe(false);
    });

    it('containing objects', () => {
      expect(equals([{ a: 1 }, { b: 2 }], [{ a: 1 }, { b: 2 }])).toBe(true);
      expect(equals([{ a: 1 }, { b: 2 }], [{ a: 1 }, { b: 3 }])).toBe(false);
    });

    it('containing different types', () => {
      expect(equals([1], [1, 2])).toBe(false);
      expect(equals([1, 2], [1])).toBe(false);
    });

    it('containing deeply nested structures', () => {
      expect(equals([[1, { a: 2 }], [3]], [[1, { a: 2 }], [3]])).toBe(true);
      expect(equals([[1, { a: 2 }], [3]], [[1, { a: 2 }], [4]])).toBe(false);
    });
  });

  describe('with objects', () => {
    it('that are empty', () => {
      expect(equals({}, {})).toBe(true);
      expect(equals({}, { a: 1 })).toBe(false);
    });

    it('containing strings', () => {
      expect(equals({ a: 'a', b: 'b' }, { a: 'a', b: 'b' })).toBe(true);
      expect(equals({ a: 'a', b: 'b' }, { a: 'a', b: 'c' })).toBe(false);
    });

    it('containing numbers', () => {
      expect(equals({ a: 1, b: 2 }, { a: 1, b: 2 })).toBe(true);
      expect(equals({ a: 1, b: 2 }, { a: 1, b: 3 })).toBe(false);
    });

    it('containing booleans', () => {
      expect(equals({ a: true, b: false }, { a: true, b: false })).toBe(true);
      expect(equals({ a: true, b: false }, { a: true, b: true })).toBe(false);
    });

    it('containing null', () => {
      expect(equals({ a: null, b: null }, { a: null, b: null })).toBe(true);
      expect(equals({ a: null, b: null }, { a: null, b: 0 })).toBe(false);
    });

    it('containing arrays', () => {
      expect(equals({ a: [1], b: [2] }, { a: [1], b: [2] })).toBe(true);
      expect(equals({ a: [1], b: [2] }, { a: [1], b: [3] })).toBe(false);
    });

    it('containing objects', () => {
      expect(
        equals({ a: { a: 1 }, b: { b: 2 } }, { a: { a: 1 }, b: { b: 2 } }),
      ).toBe(true);
      expect(
        equals({ a: { a: 1 }, b: { b: 2 } }, { a: { a: 1 }, b: { b: 3 } }),
      ).toBe(false);
    });

    it('containing different types', () => {
      expect(equals({ a: 1 }, [1, 2])).toBe(false);
      expect(equals([1, 2], { a: 1 })).toBe(false);
      expect(equals({ a: 1, b: 2 }, { a: 1 })).toBe(false);
    });

    it('containing deeply nested structures', () => {
      expect(
        equals({ a: [1, { a: 2 }], b: [3] }, { a: [1, { a: 2 }], b: [3] }),
      ).toBe(true);
      expect(
        equals({ a: [1, { a: 2 }], b: [3] }, { a: [1, { a: 2 }], b: [4] }),
      ).toBe(false);
    });

    describe('with both object having _hash properties', () => {
      describe('returns true if the hashes are the same', () => {
        describe('no matter what the rest of the object looks like', () => {
          it('for the root object', () => {
            const a = { a: 1, _hash: 'h0' };
            const b0 = { a: 1, _hash: 'h0' };
            const b1 = { a: 2, _hash: 'h0' };
            expect(equals(a, b0)).toBe(true);
            expect(equals(a, b1)).toBe(true);
            expect(equals(b0, a)).toBe(true);
            expect(equals(b1, a)).toBe(true);
          });

          it('for nested objects', () => {
            const a = { a: 1, b: { c: 2, _hash: 'h1' } };
            const b = { a: 1, b: { c: 2, _hash: 'h1' } };
            expect(equals(a, b)).toBe(true);
          });
        });
      });

      describe('returns false if the hashes are different', () => {
        describe('no matter what the rest of the object looks like', () => {
          it('for the root object', () => {
            const a = { a: 1, _hash: 'h0' };
            const b = { a: 1, _hash: 'h1' };
            expect(equals(a, b)).toBe(false);
            expect(equals(b, a)).toBe(false);
          });

          it('for nested objects', () => {
            const a = { a: 1, b: { c: 2, _hash: 'h1' } };
            const b = { a: 1, b: { c: 2, _hash: 'h0' } };
            expect(equals(a, b)).toBe(false);
            expect(equals(b, a)).toBe(false);
          });
        });
      });
    });

    describe('with only one object having a _hash property', () => {
      describe('ignores the hashes', () => {
        describe('no matter what the rest of the object looks like', () => {
          it('for the root object', () => {
            const a = { a: 1, _hash: 'h0' };
            const b0 = { a: 1, _hash: '' };
            const b1 = { a: 1, _hash: null };
            const b2 = { a: 1 };
            expect(equals(a, b0)).toBe(true);
            expect(equals(a, b1)).toBe(true);
            expect(equals(a, b2)).toBe(true);

            expect(equals(b0, a)).toBe(true);
            expect(equals(b1, a)).toBe(true);
            expect(equals(b2, a)).toBe(true);
          });
        });
      });

      describe('returns false if the hashes are different', () => {
        describe('no matter what the rest of the object looks like', () => {
          it('for the root object', () => {
            const a = { a: 1, _hash: 'h0' };
            const b = { a: 1, _hash: 'h1' };
            expect(equals(a, b)).toBe(false);
          });

          it('for nested objects', () => {
            const a = { a: 1, b: { c: 2, _hash: 'h1' } };
            const b = { a: 1, b: { c: 2, _hash: 'h0' } };
            expect(equals(a, b)).toBe(false);
          });
        });
      });
    });
  });
});
