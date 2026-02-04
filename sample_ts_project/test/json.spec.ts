// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { describe, expect, it } from 'vitest';

import {
  exampleJson,
  exampleJsonObject,
  exampleJsonObjectTypes,
  Json,
} from '../src/json';
import { exampleJsonArray } from '../src/json-array';
import { JsonValue, jsonValueType } from '../src/json-value';

import { expectGolden } from './setup/goldens';

describe('json', () => {
  describe('without hash', () => {
    describe('JsonValue', () => {
      it('string', () => {
        const val: JsonValue = 'hello';
        expect(val).toBe('hello');
      });

      it('number', () => {
        const val: JsonValue = 10;
        expect(val).toBe(10);
      });

      it('boolean', () => {
        const val: JsonValue = true;
        expect(val).toBe(true);
      });

      it('Json', () => {
        const val: JsonValue = { key: 'value' };
        expect(val).toEqual({ key: 'value' });
      });
    });

    describe('Json', () => {
      it('string', () => {
        const val: Json = { key: 'hello' };
        expect(val).toEqual({ key: 'hello' });
      });

      it('number', () => {
        const val: Json = { key: 10 };
        expect(val).toEqual({ key: 10 });
      });

      it('boolean', () => {
        const val: Json = { key: true };
        expect(val).toEqual({ key: true });
      });

      it('null', () => {
        const val: Json = { key: null };
        expect(val).toEqual({ key: null });
      });

      it('Json', () => {
        const val: Json = { key: { key: 'value' } };
        expect(val).toEqual({ key: { key: 'value' } });
      });
    });

    describe('ExampleJson', () => {
      it('provides an example json object', () => {
        expect(exampleJson).toEqual({ a: { b: 1 } });
      });
    });
  });

  describe('examplJsonValue()', () => {
    it('returns a JSON value containing all upported data types', () => {
      expectGolden('json/example-json-object.json').toBe(exampleJsonObject());
    });
  });

  describe('exampleJsonArray()', () => {
    it('returns a JSON array containing all supported data types', () => {
      expect(exampleJsonArray()).toEqual([
        5,
        5.5,
        'a',
        true,
        null,
        [
          1,
          'a',
          true,
          null,
          [1, 'a', true, null],
          {
            a: 1,
          },
        ],
        {
          a: 1,
          b: {
            c: 2,
          },
        },
        3,
      ]);
    });
  });

  describe('exampleJsonObjectTypes()', () => {
    it('describes the JSON value types for the fields of the exampleJsonObject', () => {
      const types = exampleJsonObjectTypes();

      for (const [key, value] of Object.entries(exampleJsonObject())) {
        if (value === null) {
          continue;
        }
        const typeIs = jsonValueType(value);
        const typeShould = types[key];
        if (key !== 'jsonValue') {
          expect(typeIs).toBe(typeShould);
        } else {
          expect(typeIs).toBe('number');
        }
      }
    });
  });
});
