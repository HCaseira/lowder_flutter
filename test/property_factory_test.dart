import 'package:flutter_test/flutter_test.dart';
import 'package:lowder/factory/property_factory.dart';

void main() {
  final properties = PropertyFactory();

  group('evaluateString', () {
    test('returns null for null or empty input', () {
      expect(properties.evaluateString(null, {}), isNull);
      expect(properties.evaluateString('', {}), isNull);
    });

    test('returns plain strings unchanged', () {
      expect(properties.evaluateString('hello', {}), 'hello');
    });

    test('resolves a nested placeholder inside a string', () {
      final context = {
        'state': {'firstName': 'John'}
      };
      expect(properties.evaluateString('Hello \${state.firstName}', context),
          'Hello John');
    });

    test(
        'returns the raw (non-stringified) value when the whole string is one placeholder',
        () {
      expect(properties.evaluateString('\${count}', {'count': 5}), 5);
    });

    test('stringifies the resolved value when combined with other text', () {
      expect(properties.evaluateString('Count: \${count}', {'count': 5}),
          'Count: 5');
    });

    test('resolves multiple placeholders in the same string', () {
      final context = {'first': 'John', 'last': 'Doe'};
      expect(
          properties.evaluateString('\${first} \${last}', context), 'John Doe');
    });

    test('returns null for a missing nested key', () {
      final context = {
        'state': {'user': {}}
      };
      expect(
          properties.evaluateString('\${state.user.missing}', context), isNull);
    });

    test('resolves list indexing', () {
      expect(
          properties.evaluateString('\${list.1}', {
            'list': [10, 20, 30]
          }),
          20);
    });

    test('resolves micro-functions', () {
      final context = {}..addAll(PropertyFactory.microFunctions);
      expect(properties.evaluateString('\${math.add(2,3)}', context), 5.0);
    });
  });

  group('evaluateMap / evaluateValue', () {
    test('evaluates placeholders in-place, including nested maps', () {
      final context = {
        'state': {'x': 10}
      };
      final map = {
        'a': '\${state.x}',
        'b': <String, dynamic>{'c': '\${state.x}'},
      };

      properties.evaluateMap(map, context);

      expect(map['a'], 10);
      expect((map['b'] as Map)['c'], 10);
    });

    test('does nothing when context is null', () {
      final map = {'a': '\${state.x}'};
      properties.evaluateMap(map, null);
      expect(map['a'], '\${state.x}');
    });
  });

  group('evaluateOperator', () {
    test('compares numbers regardless of being int, double or numeric string',
        () {
      expect(properties.evaluateOperator(5, '>', 3), isTrue);
      expect(properties.evaluateOperator('5', '>', '3'), isTrue);
      expect(properties.evaluateOperator('5', '<', '3'), isFalse);
    });

    test('treats null operands as not comparable', () {
      expect(properties.evaluateOperator(null, '>', 5), isFalse);
      expect(properties.evaluateOperator(5, '>=', null), isFalse);
    });

    test('supports equality on non-numeric strings', () {
      expect(properties.evaluateOperator('abc', '==', 'abc'), isTrue);
      expect(properties.evaluateOperator('abc', '!=', 'def'), isTrue);
    });

    test('contain checks Map keys', () {
      expect(properties.evaluateOperator({'a': 1}, 'contain', 'a'), isTrue);
      expect(properties.evaluateOperator({'a': 1}, 'not contain', 'b'), isTrue);
    });

    test('contain checks List and String membership', () {
      expect(properties.evaluateOperator([1, 2, 3], 'contain', 2), isTrue);
      expect(properties.evaluateOperator([1, 2, 3], 'not contain', 4), isTrue);
      expect(properties.evaluateOperator('hello world', 'contain', 'world'),
          isTrue);
    });
  });

  group('evaluateCondition', () {
    test('NullOrEmpty evaluates null, empty and non-empty values', () {
      expect(
          properties.evaluateCondition({'_type': 'NullOrEmpty', 'value': null}),
          isTrue);
      expect(
          properties.evaluateCondition({'_type': 'NullOrEmpty', 'value': ''}),
          isTrue);
      expect(
          properties.evaluateCondition({'_type': 'NullOrEmpty', 'value': 'x'}),
          isFalse);
    });

    test('NullOrEmpty can be negated with "not"', () {
      expect(
          properties.evaluateCondition(
              {'_type': 'NullOrEmpty', 'value': '', 'not': true}),
          isFalse);
    });

    test('OperatorCondition delegates to evaluateOperator', () {
      expect(
          properties.evaluateCondition({
            '_type': 'OperatorCondition',
            'left': 5,
            'operator': '>',
            'right': 3
          }),
          isTrue);
    });

    test('"and" only passes when both conditions are true', () {
      final condition = {
        '_type': 'OperatorCondition',
        'left': 5,
        'operator': '>',
        'right': 3,
        'and': {
          '_type': 'OperatorCondition',
          'left': 1,
          'operator': '<',
          'right': 0,
        },
      };
      expect(properties.evaluateCondition(condition), isFalse);
    });

    test('"or" passes when the first condition fails but the second passes',
        () {
      final condition = {
        '_type': 'OperatorCondition',
        'left': 5,
        'operator': '<',
        'right': 3,
        'or': {'_type': 'NullOrEmpty', 'value': null},
      };
      expect(properties.evaluateCondition(condition), isTrue);
    });
  });
}
