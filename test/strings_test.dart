import 'package:flutter_test/flutter_test.dart';
import 'package:lowder/util/strings.dart';

void main() {
  setUp(() {
    // Reset to the built-in resources before each test, since Strings holds
    // its resources in static state shared across the whole test run.
    Strings.load({}, clear: true);
  });

  group('Strings.get', () {
    test('returns a built-in resource by key', () {
      expect(Strings.get('required_field_message'), 'Field is required');
    });

    test('returns the key itself when not found and no fallback is given', () {
      expect(Strings.get('some_unknown_key'), 'some_unknown_key');
    });

    test('returns the fallbackValue when the key is not found', () {
      expect(Strings.get('some_unknown_key', fallbackValue: 'fallback'),
          'fallback');
    });

    test('substitutes {attribute} placeholders', () {
      expect(Strings.get('_minimum_length_message_', attributes: {'length': 5}),
          'Minimum 5 characters');
    });
  });

  group('Strings.load', () {
    test('adds custom resources on top of the built-in ones', () {
      Strings.load({'greeting': 'hello world'});
      expect(Strings.get('greeting'), 'hello world');
      expect(Strings.get('required_field_message'), 'Field is required');
    });

    test('lets custom resources override built-in ones', () {
      Strings.load({'required_field_message': 'Campo obrigatório'});
      expect(Strings.get('required_field_message'), 'Campo obrigatório');
    });
  });

  group('Strings text transforms', () {
    setUp(() => Strings.load({'greeting': 'hello world'}));

    test('getCapitalized capitalizes only the first letter', () {
      expect(Strings.getCapitalized('greeting'), 'Hello world');
    });

    test('getTitle capitalizes every word', () {
      expect(Strings.getTitle('greeting'), 'Hello World');
    });

    test('getUpper upper-cases the whole string', () {
      expect(Strings.getUpper('greeting'), 'HELLO WORLD');
    });

    test('getLower lower-cases the whole string', () {
      expect(Strings.getLower('greeting'), 'hello world');
    });
  });
}
