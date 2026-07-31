import 'package:flutter_test/flutter_test.dart';
import 'package:lowder/factory/widget_factory.dart';

void main() {
  final widgets = WidgetFactory();

  group('mergeMaps (default, override: false)', () {
    test('fills in missing keys without touching existing ones', () {
      final map1 = {'a': 1};
      final map2 = {'a': 99, 'b': 2};

      widgets.mergeMaps(map1, map2);

      expect(map1['a'], 1);
      expect(map1['b'], 2);
    });

    test('merges nested maps recursively', () {
      final map1 = {
        'style': <String, dynamic>{'color': 'red'}
      };
      final map2 = {
        'style': <String, dynamic>{'color': 'blue', 'fontSize': 12}
      };

      widgets.mergeMaps(map1, map2);

      expect((map1['style'] as Map)['color'], 'red');
      expect((map1['style'] as Map)['fontSize'], 12);
    });

    test('creates nested maps that do not exist yet in map1', () {
      final map1 = {};
      final map2 = {
        'style': {'fontSize': 12}
      };

      widgets.mergeMaps(map1, map2);

      expect((map1['style'] as Map)['fontSize'], 12);
    });
  });

  group('mergeMaps (override: true)', () {
    test('overrides existing keys with non-null values from map2', () {
      final map1 = {'a': 1};
      final map2 = {'a': 99};

      widgets.mergeMaps(map1, map2, override: true);

      expect(map1['a'], 99);
    });

    test('does not add a key when map2 has a null value for it', () {
      final map1 = {'a': 1};
      final map2 = {'a': 99, 'b': null};

      widgets.mergeMaps(map1, map2, override: true);

      expect(map1.containsKey('b'), isFalse);
    });
  });
}
