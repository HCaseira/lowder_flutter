import 'extensions.dart';

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
  static final Map<String, String> _strings = Map<String, String>.from(_initialStrings);

  static void load(Map<String, String> strings, { bool clear = false }) {
    if (clear) _strings.clear();
    _strings.addAll(_initialStrings);
    _strings.addAll(strings);
  }

  static String getCapitalized(String key, { String? fallbackValue, Map<String, dynamic>? attributes }) {
    return get(key, fallbackValue: fallbackValue, attributes: attributes, transform: Transform.capitalize);
  }

  static String getUpper(String key, { String? fallbackValue, Map<String, dynamic>? attributes }) {
    return get(key, fallbackValue: fallbackValue, attributes: attributes, transform: Transform.upper);
  }

  static String getLower(String key, { String? fallbackValue, Map<String, dynamic>? attributes }) {
    return get(key, fallbackValue: fallbackValue, attributes: attributes, transform: Transform.lower);
  }

  static String getTitle(String key, { String? fallbackValue, Map<String, dynamic>? attributes }) {
    return get(key, fallbackValue: fallbackValue, attributes: attributes, transform: Transform.title);
  }

  static String get(String key, { String? fallbackValue, Map<String, dynamic>? attributes, Transform transform = Transform.none }) {
    var value =  _strings[key] ?? _strings[key.toLowerCase()] ?? fallbackValue ?? key;
    if (attributes != null) {
      for (var key in attributes.keys) {
        var keyValue = attributes[key] != null ? attributes[key].toString() : "";
        value = value.replaceAll("{$key}", keyValue);
      }
    }

    switch (transform) {
      case Transform.upper:
        return value.toUpperCase();
      case Transform.lower:
        return value.toLowerCase();
      case Transform.capitalize:
        return value.toCapitalized();
      case Transform.title:
        return value.toTitleCase();
      default:
        return value;
    }
  }
}

enum Transform {
  none,
  upper,
  lower,
  capitalize,
  title,
}