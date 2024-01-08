import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../model/solution.dart';
import '../util/parser.dart';
import '../util/strings.dart';
import '../widget/lowder.dart';
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
      Lowder.logError(
          "[PropertyFactory] Property resolver for '$type' not found");
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
      return EdgeInsets.fromLTRB(parseDouble(parts[0]), parseDouble(parts[1]),
          parseDouble(parts[2]), parseDouble(parts[3]));
    } else if (parts.length > 1) {
      return EdgeInsets.symmetric(
          vertical: parseDouble(parts[0]), horizontal: parseDouble(parts[1]));
    } else {
      return EdgeInsets.all(parseDouble(parts[0]));
    }
  }

  /// Utility method to return a translated string from a [value].
  /// A [context] value will define it's transformation.
  /// E.g.: a [context] 'button' will return a title cased translated string.
  String getText(String value, String context,
      {Map<String, dynamic>? attributes}) {
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

  /// Method to build a String representing a DateTime
  String formatDateTime(DateTime date, bool diffToNow, {String? format}) {
    if (!diffToNow) {
      format ??= Strings.get("_date_time_format_");
    }
    if (format != null) {
      return DateFormat(format).format(date.toLocal());
    }

    if (formatDate(date.toLocal(), true) == formatDate(DateTime.now(), true)) {
      return formatTime(date.toLocal(), true);
    } else {
      return formatDate(date.toLocal(), true);
    }

    // var formattedDate = formatDate(date.toLocal(), diffToNow);
    // var formattedTime = formatTime(date.toLocal(), false);
    // if (formattedDate.isEmpty ||
    //     formattedDate == Strings.getCapitalized("today")) {
    //   return formattedTime;
    // } else if (formattedTime.isEmpty) {
    //   return formattedDate;
    // } else {
    //   return "$formattedDate, $formattedTime";
    // }
  }

  /// Method to build a String representing the Date part of a DateTime
  String formatDate(DateTime date, bool diffToNow, {String? format}) {
    if (!diffToNow) {
      format ??= Strings.get("_date_format_");
    }
    if (format != null) {
      return DateFormat(format).format(date.toLocal());
    }

    if (diffToNow) {
      final now = DateTime.now();
      final date1 = DateTime(date.year, date.month, date.day);
      final date2 = DateTime(now.year, now.month, now.day);
      final diff = date2.difference(date1);
      if (diff.inDays == 0) {
        return Strings.getCapitalized("today");
      } else if (diff.inDays == 1) {
        return Strings.getCapitalized("yesterday");
      } else if (diff.inDays == -1) {
        return Strings.getCapitalized("tomorrow");
      } else if (date1.year == date2.year) {
        return DateFormat(Strings.get("_short_date_format_"))
            .format(date.toLocal());
      }
    }
    return DateFormat(Strings.get("_date_format_")).format(date.toLocal());
  }

  /// Method to build a String representing the Time part of a DateTime
  String formatTime(DateTime date, bool diffToNow, {String? format}) {
    if (!diffToNow) {
      format ??= Strings.get("_time_format_");
    }
    if (format != null) {
      return DateFormat(format).format(date.toLocal());
    }

    return DateFormat(Strings.get("_time_format_")).format(date.toLocal());
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

      // A scenery of something like ${state.${env.nameKey}}
      var nextStartIdx = value.indexOf("\${", startIdx + 2);
      if (nextStartIdx >= 0 && nextStartIdx < endIdx) {
        startIdx = nextStartIdx;
        continue;
      }

      var valueToResolve = value.substring(startIdx + 2, endIdx);
      var resolvedPart = evaluateStringPart(valueToResolve, evaluatorContext);
      if (value.length == endIdx - startIdx + 1) {
        return resolvedPart;
      } else {
        value =
            value.replaceRange(startIdx, endIdx + 1, "${resolvedPart ?? ""}");
      }
      startIdx = 0;
    }
    return value;
  }

  dynamic evaluateStringPart(String value, Map evaluatorContext) {
    // Check if is a function
    final functionParts = value.split("(");
    if (functionParts.length > 1) {
      var func = evaluatorContext[functionParts.removeAt(0)];
      if (func is Function) {
        final argsString =
            functionParts[0].substring(0, functionParts[0].length - 1);

        if (argsString.isNotEmpty) {
          final args = argsString.split(",");
          if (args.length == 1) {
            return func(args[0]);
          } else {
            return func(args);
          }
        }
        return func();
      }
    }

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
        if (arrayIdx < 0 || evaluatedValue.length <= arrayIdx) {
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
  bool evaluateOperator(
      dynamic leftStatement, String operator, dynamic rightStatement) {
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
    final type = spec["_type"] ?? "";
    switch (type) {
      case "NullOrEmpty":
        final not = parseBool(spec["not"]);
        bool result = false;
        final value = spec["value"];
        if (value == null) {
          result = true;
        } else if (value is List) {
          result = value.isEmpty;
        } else if (value is Map) {
          result = value.isEmpty;
        } else if (value is String) {
          result = value.isEmpty;
        }
        Lowder.logInfo(
            "[NullOrEmpty] '$value' is ${result ? "empty" : "not empty"}");
        return not ? !result : result;
      case "OperatorCondition":
        var result =
            evaluateOperator(spec["left"], spec["operator"], spec["right"]);
        if (result && spec["and"] != null) {
          result = evaluateCondition(spec["and"]);
        }
        if (!result && spec["or"] != null) {
          result = evaluateCondition(spec["or"]);
        }
        return result;
      default:
        return true;
    }
  }

  /// Returns a Map with the evaluation context used when sanitizing properties of a [NodeSpec].
  /// Used to resolve properties that use placeholders as values, like "${state.firstName}" or "${env.api_uri}".
  Map getEvaluatorContext(Object? value, Map state, Map? specContext) {
    final mediaQueryData = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.single);

    Lowder.globalVariables.addAll({
      "languages": Solution.languages,
      "language": Solution.language,
    });
    final map = {};
    if (specContext != null) map.addAll(specContext);
    map.addAll({
      "null": null,
      "env": Solution.environmentVariables,
      "global": Lowder.globalVariables,
      "state": state,
      "value": value,
      "media": {
        "isWeb": kIsWeb,
        "isMobile": !kIsWeb && mediaQueryData.size.shortestSide < 600,
        "isTablet": !kIsWeb && mediaQueryData.size.shortestSide >= 600,
        "isAndroid": kIsWeb ? false : Platform.isAndroid,
        "isIOS": kIsWeb ? false : Platform.isIOS,
        "isWindows": kIsWeb ? false : Platform.isWindows,
        "isMacOS": kIsWeb ? false : Platform.isMacOS,
        "isLinux": kIsWeb ? false : Platform.isLinux,
        "isFuchsia": kIsWeb ? false : Platform.isFuchsia,
        "portrait": mediaQueryData.orientation == Orientation.portrait,
        "landscape": mediaQueryData.orientation == Orientation.landscape,
        // "version": Platform.version,
      }
    });
    return map;
  }
}
