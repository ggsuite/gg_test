/**
 * The example function demonstrates how to use rljson/json
 */

import { JsonArray, JsonArrayH } from './json-array.ts';
import { JsonValue, JsonValueH } from './json-value.ts';
import { Json, JsonH } from './json.ts';

export const example = () => {
  const h1 = (val: any) => console.log('\n' + val);
  const kv = (key: string, val: any) => console.log('  ' + key + ': ' + val);

  // .............................................................................
  h1('JsonValue can be all JSON types');
  let jsonValue: JsonValue = 10;
  kv('Number', jsonValue);

  jsonValue = 'hello';
  kv('String', jsonValue);

  jsonValue = true;
  kv('Boolean', jsonValue);

  jsonValue = { a: { b: 1 } };
  kv('Json', JSON.stringify(jsonValue));

  // .............................................................................
  h1('JsonValueH deeply enforces _hash properties for Json dictionaries');
  const jsonValueH: JsonValueH = {
    a: { b: 1, _hash: 'hash1' },
    _hash: 'hash0',
  };
  kv('JsonH', JSON.stringify(jsonValueH));

  // .............................................................................
  h1('JsonArray is array of json values');

  let jsonArray: JsonArray = [1, 2, 3, 4, 5];
  kv('Number array', jsonArray);

  jsonArray = ['hello', 'world'];
  kv('String array', jsonArray);

  jsonArray = [true, false];
  kv('Boolean array', jsonArray);

  jsonArray = [null, null];
  kv('Null array', jsonArray);

  jsonArray = [{ a: { b: 1 } }];
  kv('Json array', JSON.stringify(jsonArray));

  // .............................................................................
  h1('JsonArrayH enforces hashes in Json dictionaries');

  const jsonArrayH: JsonArrayH = [
    { a: { b: 1, _hash: 'hash1' }, _hash: 'hash0' },
  ];
  kv('JsonH array', JSON.stringify(jsonArrayH));

  // ...........................................................................
  h1('Json');

  let json: Json = { a: 1 };
  kv('numbers', JSON.stringify(json));

  json = { b: 'hello' };
  kv('strings', JSON.stringify(json));

  json = { c: true };
  kv('booleans', JSON.stringify(json));

  json = { d: null };
  kv('nulls', JSON.stringify(json));

  json = { e: { f: { g: 1 } } };
  kv('nested', JSON.stringify(json));

  // ...........................................................................
  h1('JsonH deeply enforces _hash properties for Json dictionaries');

  const jsonH: JsonH = {
    a: 1,
    _hash: 'hash1',
    b: { c: 'hello', _hash: 'hash2' },
  };

  kv('numbers', JSON.stringify(jsonH));
};
