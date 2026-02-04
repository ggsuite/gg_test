// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { JsonValue, JsonValueH } from './json-value.ts';
import { exampleJsonObject } from './json.ts';

/** An array that can be assigned to a property in a json dictionary */
export type JsonArray = Array<JsonValue | null | undefined>;

/** A deeply hashed JSON array */
export type JsonArrayH = Array<JsonValueH>;

/**
 * Returns an example json array containing all values of the exampleJsonObject
 */
export const exampleJsonArray = (): JsonArray =>
  Object.values(exampleJsonObject());
