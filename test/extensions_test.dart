import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowder/util/extensions.dart';

void main() {
  group('MapExtensions.clone', () {
    test('deep clones nested Maps', () {
      final original = {
        'a': 1,
        'b': {'c': 2},
      };
      final clone = original.clone();
      (clone['b'] as Map)['c'] = 99;

      expect((original['b'] as Map)['c'], 2);
      expect((clone['b'] as Map)['c'], 99);
    });

    test('deep clones List<Map> values, as produced by decodeWithReviver', () {
      final original = {
        'items': <Map<String, dynamic>>[
          {'e': 3}
        ],
      };
      final clone = original.clone();
      (clone['items'] as List<Map>)[0]['e'] = 99;

      expect((original['items'] as List<Map>)[0]['e'], 3);
      expect((clone['items'] as List<Map>)[0]['e'], 99);
    });

    test('copies other value types by reference', () {
      final sharedList = [1, 2, 3];
      final original = {'values': sharedList};
      final clone = original.clone();

      expect(identical(clone['values'], sharedList), isTrue);
    });
  });

  group('JsonCodecExtensions.decodeWithReviver', () {
    test('revives arrays of objects as List<Map>', () {
      final decoded =
          json.decodeWithReviver('{"items":[{"a":1},{"a":2}]}') as Map;

      expect(decoded['items'], isA<List<Map>>());
      expect((decoded['items'] as List)[0], {'a': 1});
    });

    test('revives arrays of arrays as List<List>', () {
      final decoded = json.decodeWithReviver('{"matrix":[[1,2],[3,4]]}') as Map;

      expect(decoded['matrix'], isA<List<List>>());
    });

    test('result plays nicely with Map.clone for deep copies', () {
      final decoded =
          json.decodeWithReviver('{"items":[{"a":1}]}') as Map<String, dynamic>;
      final clone = decoded.clone();
      (clone['items'] as List<Map>)[0]['a'] = 99;

      expect((decoded['items'] as List<Map>)[0]['a'], 1);
    });
  });

  group('JsonCodecExtensions.safeEncode', () {
    test('encodes DateTime as an ISO8601 string', () {
      final date = DateTime.utc(2024, 1, 1);
      final encoded = json.safeEncode({'date': date});

      expect(encoded, '{"date":"${date.toIso8601String()}"}');
    });
  });

  group('UriExtensions.buildUri', () {
    test('joins a host and a path without duplicating slashes', () {
      final uri = UriExtensions.buildUri('http://host/', path: '/api');
      expect(uri.toString(), 'http://host/api');
    });

    test('inserts a slash when neither side has one', () {
      final uri = UriExtensions.buildUri('http://host', path: 'api');
      expect(uri.toString(), 'http://host/api');
    });

    test('appends query arguments and skips null/empty ones', () {
      final uri = UriExtensions.buildUri('http://host',
          path: '/api', queryArgs: {'a': 1, 'b': null, 'c': ''});
      expect(uri.toString(), 'http://host/api?a=1');
    });
  });

  group('StringExtension', () {
    test('toCapitalized capitalizes only the first letter', () {
      expect('hello world'.toCapitalized(), 'Hello world');
      expect(''.toCapitalized(), '');
    });

    test('toTitleCase capitalizes each word', () {
      expect('hello  world'.toTitleCase(), 'Hello World');
    });

    test('getRandomString returns a string of the requested length', () {
      final result = StringExtension.getRandomString(16);
      expect(result.length, 16);
    });
  });

  group('ColorExtension.toHexString', () {
    test('formats an opaque color as a 6-digit hex string', () {
      expect(const Color(0xFFFF0000).toHexString(), '#ff0000');
    });
  });
}
