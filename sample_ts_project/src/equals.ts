// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { JsonValue } from './json-value.ts';

/**
 * Returns true if a and b are deeply equal also evaluating the _hash property
 * @param a - The first value to compare
 * @param b - The second value to compare
 * @returns true if a and b are deeply equal
 */
export const equals = (
  a: JsonValue | null | undefined,
  b: JsonValue | null | undefined,
): boolean => {
  if (a === b) {
    return true;
  }

  if (typeof a !== typeof b) {
    return false;
  }

  if (a instanceof Array && b instanceof Array) {
    if (a.length !== b.length) {
      return false;
    }

    for (let i = 0; i < a.length; i++) {
      if (!equals(a[i], b[i])) {
        return false;
      }
    }

    return true;
  }

  if (a instanceof Array && !(b instanceof Array)) {
    return false;
  }

  if (!(a instanceof Array) && b instanceof Array) {
    return false;
  }

  if (a instanceof Object && b instanceof Object) {
    const aHash = (a as any)._hash;
    const bHash = (b as any)._hash;
    if (aHash && bHash) {
      return aHash === bHash;
    }

    const keys = Object.keys(a);
    let aKeys = keys;
    let bKeys = Object.keys(b);

    if (aHash) {
      aKeys = aKeys.filter((key) => key !== '_hash');
    }

    if (bHash) {
      bKeys = bKeys.filter((key) => key !== '_hash');
    }

    aKeys = aKeys.filter((key) => key !== '_hash');
    bKeys = bKeys.filter((key) => key !== '_hash');

    if (aKeys.length !== bKeys.length) {
      return false;
    }

    for (const key of aKeys) {
      const x = (a as any)[key];
      const y = (b as any)[key];

      if (!equals(x, y)) {
        return false;
      }
    }

    return true;
  }

  return false;
};
