import 'package:flutter/material.dart';

bool parseBool(var value, { bool defaultValue = false }) {
  return _parseBool(value, defaultValue) as bool;
}

bool? tryParseBool(var value) {
  return _parseBool(value, null);
}

bool? _parseBool(var value, bool? defaultValue) {
  if (value != null) {
    if (value is bool || value is bool?) {
      return value;
    } else if (value is String) {
      return value.toLowerCase() == "true" || value == "1";
    } else if (value is int || value is double) {
      return value == 1;
    }
  }
  return defaultValue;
}

int parseInt(var value, { int defaultValue = 0 }) {
  return _parseInt(value, defaultValue) as int;
}

int? tryParseInt(var value) {
  return _parseInt(value, null);
}

int? _parseInt(var value, int? defaultValue) {
  if (value != null) {
    if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return num.tryParse(value)?.toInt() ?? defaultValue;
    }
    else if (value is bool) {
      return value ? 1 : 0;
    }
  }
  return defaultValue;
}

double parseDouble(var value, { double defaultValue = 0.0 }) {
  return _parseDouble(value, defaultValue) as double;
}

double? tryParseDouble(var value) {
  return _parseDouble(value, null);
}

double? _parseDouble(var value, double? defaultValue) {
  if (value != null) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
  }
  return defaultValue;
}

DateTime parseDateTime(var value, { DateTime? defaultValue }) {
  defaultValue ??= DateTime.fromMillisecondsSinceEpoch(0);
  return _parseDateTime(value, defaultValue) as DateTime;
}

DateTime? tryParseDateTime(var value) {
  return _parseDateTime(value, null);
}

DateTime? _parseDateTime(var value, DateTime? defaultValue) {
  if (value != null) {
    if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? defaultValue;
    }
  }
  return defaultValue;
}

Color parseColor(String? value, { Color defaultColor = Colors.black }) {
  return _parseColor(value, defaultColor) as Color;
}

Color? tryParseColor(String? value) {
  return _parseColor(value, null);
}

Color? _parseColor(String? value, Color? defaultColor) {
  if (value == null) return defaultColor;

  if (value.contains(",")) {
    final parts = value.split(",");
    while (parts.length < 4) {
      parts.insert(0, "255");
    }
    return Color.fromARGB(parseInt(parts[0]), parseInt(parts[1]), parseInt(parts[2]), parseInt(parts[3]));
  } else {
    value = value.replaceAll("#", "");
    if (value.length == 3) {
      value = "FF${value[0]}${value[0]}${value[1]}${value[1]}${value[2]}${value[2]}";
    } else if (value.length == 4) {
      value = "${value[0]}${value[0]}${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}";
    } else if (value.length == 6) {
      value = "FF$value";
    }
    return Color(int.parse(value, radix: 16));
  }
}