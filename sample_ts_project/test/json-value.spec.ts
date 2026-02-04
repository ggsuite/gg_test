// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { describe, expect, it } from 'vitest';

import {
  isBasicType,
  jsonBasicValueTypes,
  jsonComplexValueTypes,
  jsonValueMatchesType,
  jsonValueType,
  jsonValueTypes,
  validateJsonValue,
} from '../src/json-value.ts';
import { exampleJsonObject } from '../src/json.ts';

describe('JsonValue', () => {
  it('jsonBasicValueTypes', () => {
    expect(jsonBasicValueTypes).toEqual(['string', 'number', 'boolean']);
  });

  it('jsonComplexValueTypes', () => {
    expect(jsonComplexValueTypes).toEqual(['json', 'jsonArray', 'jsonValue']);
  });

  it('jsonValueTypes', () => {
    expect(jsonValueTypes).toEqual([
      'string',
      'number',
      'boolean',
      'json',
      'jsonArray',
      'jsonValue',
    ]);
  });

  describe('jsonValueType(value)', () => {
    it('string', () => {
      expect(jsonValueType('hello')).toBe('string');
    });
    it('number', () => {
      expect(jsonValueType(10)).toBe('number');
    });
    it('boolean', () => {
      expect(jsonValueType(true)).toBe('boolean');
    });
    it('json', () => {
      expect(jsonValueType({ key: 'value' })).toBe('json');
    });
    it('jsonArray', () => {
      expect(jsonValueType(['hello'])).toBe('jsonArray');
    });
    it('other', () => {
      expect(() => jsonValueType(new Date(18908290) as any)).toThrow(
        'Invalid json type Date; value: "1970-01-01T05:15:08.290Z"',
      );
    });
  });

  describe('validateJsonValue(value)', () => {
    it('returns normally when the value is valid JSON', () => {
      expect(() => validateJsonValue(exampleJsonObject())).not.toThrow();
    });

    describe('throws when the value is not valid JSON', () => {
      it('when the value itself is not valid', () => {
        expect(() => validateJsonValue(new Date(0) as any)).toThrow(
          'Invalid json type Date; value: "1970-01-01T00:00:00.000Z"',
        );
      });

      it('when an array does not contain valid JSON', () => {
        const invalid = exampleJsonObject();
        (invalid['jsonArray'] as Array<any>).push(new Date(0));
        expect(() => validateJsonValue(invalid as any)).toThrow(
          'Invalid json type Date; value: "1970-01-01T00:00:00.000Z"',
        );
      });

      it('when an object does not contain valid JSON', () => {
        const invalid = exampleJsonObject();
        invalid['json']!['data'] = new Date(0);
        expect(() => validateJsonValue(invalid as any)).toThrow(
          'Invalid json type Date; value: "1970-01-01T00:00:00.000Z"',
        );
      });
    });
  });

  describe('isBasicType', () => {
    it('returns true if type is a basic type', () => {
      expect(isBasicType(1)).toEqual(true);
      expect(isBasicType(1.0)).toEqual(true);
      expect(isBasicType('1')).toEqual(true);
      expect(isBasicType(true)).toEqual(true);
      expect(isBasicType(false)).toEqual(true);
      expect(isBasicType(new Set())).toEqual(false);
    });
  });

  describe('jsonValueMatchesType', () => {
    describe('returns true ', () => {
      it('if value matches type', () => {
        expect(jsonValueMatchesType(1, 'number')).toEqual(true);
        expect(jsonValueMatchesType(1.0, 'number')).toEqual(true);
        expect(jsonValueMatchesType('1', 'string')).toEqual(true);
        expect(jsonValueMatchesType(true, 'boolean')).toEqual(true);
        expect(jsonValueMatchesType(false, 'boolean')).toEqual(true);
        expect(jsonValueMatchesType({}, 'json')).toEqual(true);
        expect(jsonValueMatchesType([], 'jsonArray')).toEqual(true);
      });
      describe('if the value is an arbitrary json value', () => {
        it('and type is jsonValue', () => {
          expect(jsonValueMatchesType(1, 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType(1.0, 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType('1', 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType(true, 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType(false, 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType({}, 'jsonValue')).toEqual(true);
          expect(jsonValueMatchesType([], 'jsonValue')).toEqual(true);
        });
      });
    });

    it('returns false if value is not a JsonValue', () => {
      expect(jsonValueMatchesType(new Set(), 'json')).toEqual(false);
    });
  });
});
