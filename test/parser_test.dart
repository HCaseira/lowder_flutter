import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowder/util/parser.dart';

void main() {
  group('parseBool', () {
    test('parses bools as-is', () {
      expect(parseBool(true), isTrue);
      expect(parseBool(false), isFalse);
    });

    test('parses strings case-insensitively', () {
      expect(parseBool('true'), isTrue);
      expect(parseBool('TRUE'), isTrue);
      expect(parseBool('1'), isTrue);
      expect(parseBool('false'), isFalse);
      expect(parseBool('yes'), isFalse);
    });

    test('parses numbers', () {
      expect(parseBool(1), isTrue);
      expect(parseBool(0), isFalse);
      expect(parseBool(1.0), isTrue);
    });

    test('falls back to defaultValue for null or unsupported types', () {
      expect(parseBool(null), isFalse);
      expect(parseBool(null, defaultValue: true), isTrue);
      expect(parseBool([1, 2], defaultValue: true), isTrue);
    });

    test('tryParseBool returns null instead of a default', () {
      expect(tryParseBool(null), isNull);
      expect(tryParseBool('true'), isTrue);
    });
  });

  group('parseInt', () {
    test('parses numbers and numeric strings', () {
      expect(parseInt(42), 42);
      expect(parseInt(42.9), 42);
      expect(parseInt('42'), 42);
    });

    test('parses bools as 1 or 0', () {
      expect(parseInt(true), 1);
      expect(parseInt(false), 0);
    });

    test('falls back to defaultValue for null or unparseable strings', () {
      expect(parseInt(null), 0);
      expect(parseInt(null, defaultValue: 7), 7);
      expect(parseInt('abc', defaultValue: 7), 7);
    });

    test('tryParseInt returns null instead of a default', () {
      expect(tryParseInt('abc'), isNull);
      expect(tryParseInt('42'), 42);
    });
  });

  group('parseDouble', () {
    test('parses numbers and numeric strings', () {
      expect(parseDouble(3), 3.0);
      expect(parseDouble('3.14'), 3.14);
    });

    test('falls back to defaultValue for null, bools or unparseable strings',
        () {
      // Unlike parseInt/parseBool, bools are not special-cased here.
      expect(parseDouble(true), 0.0);
      expect(parseDouble(null), 0.0);
      expect(parseDouble('abc', defaultValue: 1.5), 1.5);
    });

    test('tryParseDouble returns null instead of a default', () {
      expect(tryParseDouble('abc'), isNull);
      expect(tryParseDouble('3.14'), 3.14);
    });
  });

  group('parseDateTime', () {
    test('returns DateTime values as-is', () {
      final date = DateTime(2024, 1, 1);
      expect(parseDateTime(date), date);
    });

    test('parses milliseconds since epoch', () {
      expect(parseDateTime(1000), DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('parses ISO8601 strings', () {
      expect(parseDateTime('2024-01-01T00:00:00.000Z'),
          DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('falls back to epoch 0 for null when no defaultValue is given', () {
      expect(parseDateTime(null), DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('falls back to the given defaultValue for unparseable strings', () {
      final fallback = DateTime(2000, 1, 1);
      expect(parseDateTime('not a date', defaultValue: fallback), fallback);
    });

    test('tryParseDateTime returns null instead of a default', () {
      expect(tryParseDateTime(null), isNull);
      expect(tryParseDateTime('not a date'), isNull);
    });
  });

  group('parseColor', () {
    test('parses 6-digit hex colors, with or without a leading #', () {
      expect(parseColor('#FF0000'), const Color(0xFFFF0000));
      expect(parseColor('00FF00'), const Color(0xFF00FF00));
    });

    test('parses 3-digit shorthand hex colors', () {
      expect(parseColor('F00'), const Color(0xFFFF0000));
    });

    test('parses 8-digit ARGB hex colors', () {
      expect(parseColor('80FF0000'), const Color(0x80FF0000));
    });

    test('parses comma-separated RGB and ARGB values', () {
      expect(parseColor('255,0,0'), const Color(0xFFFF0000));
      expect(parseColor('128,255,0,0'), const Color(0x80FF0000));
    });

    test('falls back to defaultColor for null or empty values', () {
      expect(parseColor(null), Colors.black);
      expect(parseColor('', defaultColor: Colors.white), Colors.white);
    });

    test('tryParseColor returns null instead of a default', () {
      expect(tryParseColor(null), isNull);
      expect(tryParseColor('#00FF00'), const Color(0xFF00FF00));
    });
  });
}
