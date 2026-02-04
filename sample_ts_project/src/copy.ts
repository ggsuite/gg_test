// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { JsonArray } from './json-array.ts';
import { isBasicType } from './json-value.ts';
import { Json } from './json.ts';

// ...........................................................................
export const copy = <T extends Json>(json: T): T => {
  const result: Json = {};
  for (const [key, value] of Object.entries(json)) {
    if (value === null) {
      result[key] = null;
    } else if (value === undefined) {
      result[key] = undefined;
    } else if (Array.isArray(value)) {
      result[key] = copyList(value);
    } else if (isBasicType(value)) {
      result[key] = value;
    } else if (value.constructor === Object) {
      result[key] = copy(value as Json);
    } else {
      throw new Error(`Unsupported type: ${typeof value}`);
    }
  }
  return result as T;
};

// ...........................................................................
export const copyList = <T extends JsonArray>(list: JsonArray): T => {
  const result: JsonArray = [];
  for (const element of list) {
    if (element === null) {
      result.push(null);
    } else if (element === undefined) {
      result.push(undefined);
    } else if (Array.isArray(element)) {
      result.push(copyList(element));
    } else if (isBasicType(element)) {
      result.push(element);
    } else if (element.constructor === Object) {
      result.push(copy(element as Json));
    } else {
      throw new Error(`Unsupported type: ${typeof element}`);
    }
  }
  return result as T;
};
