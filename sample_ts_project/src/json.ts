// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { JsonValue, JsonValueH, JsonValueType } from './json-value.ts';

/** A json data structure */
export interface Json {
  [key: string]: JsonValue | null | undefined;
}

/** A deeply hashed JSON object */
export interface JsonH {
  [key: string]: JsonValueH;
  _hash: string;
}

// .............................................................................
/** An example json type without hashes */
export interface ExampleJson extends Json {
  a: { b: number };
}

/** An example json object without hashes */
export const exampleJson: Readonly<ExampleJson> = { a: { b: 1 } };

// .............................................................................
// Example json values

/**
 * Returns an example json value containing all possible types
 */
export const exampleJsonObject = (): Json => {
  return {
    int: 5,
    double: 5.5,
    string: 'a',
    boolean: true,
    null: null,
    jsonArray: [1, 'a', true, null, [1, 'a', true, null], { a: 1 }],
    json: { a: 1, b: { c: 2 } },
    jsonValue: 3,
  } as const;
};

/**
 * Returns the intended Json value types for the fields of the exampleJsonObject
 */
export const exampleJsonObjectTypes = (): Record<
  string,
  JsonValueType | null
> => {
  return {
    int: 'number',
    double: 'number',
    string: 'string',
    boolean: 'boolean',
    jsonArray: 'jsonArray',
    json: 'json',
    jsonValue: 'jsonValue',
  } as const;
};
