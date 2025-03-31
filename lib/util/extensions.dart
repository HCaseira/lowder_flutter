import 'dart:async';
import 'dart:convert';
import 'dart:math' hide log;
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// [http] extension with a [isSuccess] getter.
extension HttpExtensions on http.Response {
  bool get isSuccess => (statusCode ~/ 100) == 2;
}

/// [Map] extension implementing a [clone] method.
extension MapExtensions on Map {
  Map clone() {
    var newMap = {};
    forEach((key, value) {
      if (value is Map) {
        newMap[key] = value.clone();
      } else if (value is List<Map>) {
        newMap[key] = value.clone();
      } else {
        newMap[key] = value;
      }
    });
    return newMap;
  }
}

/// [List] extension implementing a [clone] method.
extension ArrayExtensions on List<Map> {
  List clone() {
    var newList = <Map>[];
    forEach((value) {
      newList.add(value.clone());
    });
    return newList;
  }
}

/// [Uri] extension implementing a [buildUri] method to facilitate the creation of an [Uri]
extension UriExtensions on Uri {
  static Uri buildUri(String hostAddress, {String? path, Map? queryArgs}) {
    var uri = hostAddress;
    if (path != null && path.isNotEmpty) {
      if (hostAddress.endsWith("/") && path.startsWith("/")) {
        path = path.substring(1);
      } else if (!hostAddress.endsWith("/") && !path.startsWith("/")) {
        uri += "/";
      }
      uri += path;
    }

    if (queryArgs != null) {
      var leadingChar = uri.contains("?") ? "&" : "?";
      for (var key in queryArgs.keys) {
        var value = queryArgs[key];
        if (value == null || value.toString().isEmpty) continue;
        uri += "$leadingChar$key=$value";
        leadingChar = "&";
      }
    }
    return Uri.parse(uri);
  }
}

/// [JsonCodec] extensions.
extension JsonCodecExtensions on JsonCodec {
  /// [decode] method with a [reviver] to instantiate the correct objects from `model`
  dynamic decodeWithReviver(String source) {
    return decode(source, reviver: (key, value) {
      if (value is List && value.isNotEmpty) {
        if (value[0] is Map) {
          return List<Map<String, dynamic>>.from(value);
        } else if (value[0] is List) {
          return List<List>.from(value);
        }
      }
      return value;
    });
  }

  /// [encode] method with [toEncodable] to correctly encode a DateTime object.
  String safeEncode(Object obj) {
    return json.encode(obj, toEncodable: (value) {
      if (value is DateTime) return value.toIso8601String();
      try {
        return value.toJson();
      } catch (e) {
        return null;
      }
    });
  }
}

/// [String] extension implementing formatting methods.
extension StringExtension on String {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static String getRandomString(int length) {
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))));
  }

  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

extension LoggerExtension on Logger {
  void shoutWithContext(String message, Map? context,
          [Object? error, StackTrace? stackTrace]) =>
      log(
        Level.SHOUT,
        LogRecord(
          Level.SHOUT,
          message,
          fullName,
          error,
          stackTrace,
          Zone.current,
          context,
        ),
      );

  void severeWithContext(String message, Map? context,
          [Object? error, StackTrace? stackTrace]) =>
      log(
        Level.SEVERE,
        LogRecord(
          Level.SEVERE,
          message,
          fullName,
          error,
          stackTrace,
          Zone.current,
          context,
        ),
      );

  void warningWithContext(String message, Map? context,
          [Object? error, StackTrace? stackTrace]) =>
      log(
        Level.WARNING,
        LogRecord(
          Level.WARNING,
          message,
          fullName,
          error,
          stackTrace,
          Zone.current,
          context,
        ),
      );

  void infoWithContext(String message, Map? context) => log(
        Level.INFO,
        LogRecord(
          Level.INFO,
          message,
          fullName,
          null,
          null,
          Zone.current,
          context,
        ),
      );
}

extension ColorExtension on Color {
  String toHexString() =>
      "#${toARGB32().toRadixString(16).substring(2).padLeft(2, '0')}";
}
