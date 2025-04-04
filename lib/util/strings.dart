import 'extensions.dart';

/// Static class to access Model's String Resources.
abstract class Strings {
  static final Map<String, String> _initialStrings = {
    "unknown_error_message": "Unknown error.",
    "communication_error_message": "Communication error.",
    "try_again_question": "Retry?",
    "invalid_session_message": "Invalid Session.",
    "no_entries_message": "No entries.",
    "required_field_message": "Field is required",
    "invalid_value_message": "Invalid value",
    "_minimum_length_message_": "Minimum {length} characters",
    "_maximum_length_message_": "Maximum {length} characters",
    "_exact_length_message_": "Must have {length} characters",
    "_date_time_format_": "yyyy-MM-dd HH:mm",
    "_date_format_": "yyyy-MM-dd",
    "_time_format_": "HH:mm",
    "_number_format_": ".00",
    "_currency_symbol_": "€",
  };
  static final Map<String, String> _strings =
      Map<String, String>.from(_initialStrings);

  /// method used to load string resources into memory.
  static void load(Map<String, String> strings, {bool clear = false}) {
    if (clear) _strings.clear();
    _strings.addAll(_initialStrings);
    _strings.addAll(strings);
  }

  /// return a string resource capitalized.
  static String getCapitalized(String key,
      {String? fallbackValue, Map<String, dynamic>? attributes}) {
    return get(key,
        fallbackValue: fallbackValue,
        attributes: attributes,
        transform: TextTransform.capitalize);
  }

  /// return a string resource in upper case.
  static String getUpper(String key,
      {String? fallbackValue, Map<String, dynamic>? attributes}) {
    return get(key,
        fallbackValue: fallbackValue,
        attributes: attributes,
        transform: TextTransform.upper);
  }

  /// return a string resource in lower case.
  static String getLower(String key,
      {String? fallbackValue, Map<String, dynamic>? attributes}) {
    return get(key,
        fallbackValue: fallbackValue,
        attributes: attributes,
        transform: TextTransform.lower);
  }

  /// return a string resource in title case.
  static String getTitle(String key,
      {String? fallbackValue, Map<String, dynamic>? attributes}) {
    return get(key,
        fallbackValue: fallbackValue,
        attributes: attributes,
        transform: TextTransform.title);
  }

  /// return a string resource.
  static String get(String key,
      {String? fallbackValue,
      Map<String, dynamic>? attributes,
      TextTransform transform = TextTransform.none}) {
    var value =
        _strings[key] ?? _strings[key.toLowerCase()] ?? fallbackValue ?? key;
    if (attributes != null) {
      for (var key in attributes.keys) {
        var keyValue =
            attributes[key] != null ? attributes[key].toString() : "";
        value = value.replaceAll("{$key}", keyValue);
      }
    }

    switch (transform) {
      case TextTransform.upper:
        return value.toUpperCase();
      case TextTransform.lower:
        return value.toLowerCase();
      case TextTransform.capitalize:
        return value.toCapitalized();
      case TextTransform.title:
        return value.toTitleCase();
      default:
        return value;
    }
  }
}

enum TextTransform {
  none,
  upper,
  lower,
  capitalize,
  title,
}
