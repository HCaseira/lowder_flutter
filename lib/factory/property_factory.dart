import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../util/parser.dart';
import '../util/strings.dart';
import 'properties.dart';

/// Class that handles Property related operations.
class PropertyFactory {
  final Map<String, Function> _builders = {};

  /// Schema loading
  @nonVirtual
  void loadProperties(IProperties properties) {
    _builders.addAll(properties.builders);
  }

  /// Returns a result from a Property's [type] and [propValue].
  dynamic build(String type, dynamic propValue, {dynamic argument}) {
    if (!_builders.containsKey(type) || _builders[type] == null) {
      return propValue;
    }
    final func = _builders[type]!;
    if (func is ValueSpecBuildFunction) {
      return func(argument, propValue);
    } else {
      return func(propValue);
    }
  }

  /// Utility method to return a [Key] based on a Property's value.
  Key? getKey(dynamic key) {
    if (key is Key) {
      return key;
    }
    if (key == null || key is! String || key.isEmpty) {
      return null;
    }
    return Key(key);
  }

  /// Utility method to build an [EdgeInsets] based on a Property's [value].
  EdgeInsets? getInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(parseDouble(value));

    var parts = value.toString().split(RegExp(r'[|\s]'));
    if (parts.length > 2) {
      return EdgeInsets.fromLTRB(parseDouble(parts[0]), parseDouble(parts[1]), parseDouble(parts[2]), parseDouble(parts[3]));
    } else if (parts.length > 1) {
      return EdgeInsets.symmetric(vertical: parseDouble(parts[0]), horizontal: parseDouble(parts[1]));
    } else {
      return EdgeInsets.all(parseDouble(parts[0]));
    }
  }

  /// Utility method to return a translated string from a [value].
  /// A [context] value will define it's transformation.
  /// E.g.: a [context] 'button' will return a title cased translated string.
  String getText(String value, String context, {Map<String, dynamic>? attributes}) {
    switch (context) {
      case "dialogTitle":
      case "dialogButton":
      case "appBar":
      case "label":
      case "hintText":
      case "helperText":
      case "prefixText":
      case "errorMessage":
      case "titleMessage":
      case "message":
      case "listTile":
      case "menu":
        return Strings.getCapitalized(value, attributes: attributes);
      case "title":
      case "button":
        return Strings.getTitle(value, attributes: attributes);
      default:
        return Strings.get(value, attributes: attributes);
    }
  }

  /// Updates the content of a [Map] by evaluating it's values using [otherMap] as context.
  void evaluateMap(Map map, Map? otherMap) {
    if (otherMap == null) {
      return;
    }
    for (var key in map.keys) {
      map[key] = evaluateValue(map[key], otherMap);
    }
  }

  /// Updates the content of a [List] by evaluating it's values using [map] as context.
  void evaluateList(List list, Map map) {
    for (var i = 0; i < list.length; i++) {
      list[i] = evaluateValue(list[i], map);
    }
  }

  /// Returns the evaluated value of a given [value] using [map] as context.
  dynamic evaluateValue(dynamic value, Map map) {
    if (value is String) {
      return evaluateString(value, map);
    } else if (value is Map) {
      evaluateMap(value, map);
    } else if (value is List) {
      evaluateList(value, map);
    }
    return value;
  }

  /// Evaluates a string using [evaluatorContext].
  /// A string containing ${<some var>} will be evaluated.
  /// E.g.: a string "${state.name}" will be replaced with the (evaluatorContext["state"] as Map)["name"].
  dynamic evaluateString(String? value, Map evaluatorContext) {
    if (value == null || value.isEmpty) {
      return null;
    }

    var startIdx = 0;
    while ((startIdx = value!.indexOf("\${", startIdx)) >= 0) {
      var endIdx = value.indexOf("}", startIdx);
      if (endIdx < 0) {
        return value;
      }

      var valueToResolve = value.substring(startIdx + 2, endIdx);
      var resolvedPart = _evaluateStringPart(valueToResolve, evaluatorContext);
      if (value.length == endIdx - startIdx + 1) {
        return resolvedPart;
      } else {
        value = value.replaceRange(startIdx, endIdx + 1, "${resolvedPart ?? ""}");
      }
      startIdx = 0;
    }
    return value;
  }

  dynamic _evaluateStringPart(String value, Map evaluatorContext) {
    final parts = value.split(".");
    var evaluatedValue = evaluatorContext[parts.removeAt(0)];
    if (evaluatedValue == null || parts.isEmpty) {
      return evaluatedValue;
    }

    for (var part in parts) {
      if (evaluatedValue is Map) {
        if (!evaluatedValue.containsKey(part)) {
          return null;
        } else {
          evaluatedValue = evaluatedValue[part];
        }
      } else if (evaluatedValue is List<dynamic>) {
        var arrayIdx = parseInt(part, defaultValue: -1);
        if (arrayIdx < 0) {
          return null;
        } else {
          evaluatedValue = evaluatedValue[arrayIdx];
        }
      } else {
        return null;
      }
    }
    return evaluatedValue;
  }

  /// Evaluates the result of a given [leftStatement], an [operator] and a [rightStatement].
  bool evaluateOperator(dynamic leftStatement, String operator, dynamic rightStatement) {
    dynamic left;
    dynamic right;
    if (leftStatement is DateTime || rightStatement is DateTime) {
      left = tryParseDateTime(leftStatement);
      right = tryParseDateTime(rightStatement);
    } else if (leftStatement is num || rightStatement is num) {
      left = tryParseDouble(leftStatement);
      right = tryParseDouble(rightStatement);
    } else if (leftStatement is bool || rightStatement is bool) {
      left = tryParseBool(leftStatement);
      right = tryParseBool(rightStatement);
    } else {
      left = leftStatement;
      right = rightStatement;
    }

    switch (operator) {
      case "==":
      case "equal":
        return left == right;
      case "!=":
      case "notEqual":
        return left != right;
      case ">":
      case "greater":
        return left > right;
      case ">=":
      case "greaterEqual":
        return left >= right;
      case "<":
      case "less":
        return left < right;
      case "<=":
      case "lessEqual":
        return left <= right;
      case "contain":
      case "not contain":
        var result = false;
        if (left is Map) {
          result = left.containsKey(right);
        } else if (left != null) {
          left.contains(right);
        }
        return operator == "contain" ? result : !result;
      default:
        return false;
    }
  }

  /// Evaluates an "OperatorCondition" Property.
  bool evaluateCondition(Map spec) {
    if (spec["_type"] != "OperatorCondition") {
      return true;
    }
    var result = evaluateOperator(spec["left"], spec["operator"], spec["right"]);
    if (result && spec["and"] != null) {
      result = evaluateCondition(spec["and"]);
    }
    if (!result && spec["or"] != null) {
      result = evaluateCondition(spec["or"]);
    }
    return result;
  }
}
