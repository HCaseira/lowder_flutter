import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

extension HttpExtensions on http.Response {
  bool get isSuccess => (statusCode ~/ 100) == 2;
}

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

extension ArrayExtensions on List<Map> {
  List clone() {
    var newList = <Map>[];
    forEach((value) {
      newList.add(value.clone());
    });
    return newList;
  }
}

extension UriExtensions on Uri {
  static Uri buildUri(String hostAddress, {String? path, Map? queryArgs}) {
    var uri = hostAddress;
    if (path != null && path.isNotEmpty) {
      if (hostAddress.endsWith("/") && path.startsWith("/")) {
        path = path.substring(1);
      }
      else if (!hostAddress.endsWith("/") && !path.startsWith("/")) {
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

extension JsonCodecExtensions on JsonCodec {
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

  String safeEncode(Object obj) {
    return json.encode(obj, toEncodable: (value) {
      if (value is DateTime) return value.toIso8601String();
      return value.toJson();
    });
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1)}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

extension HexColor on Color {
  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true, bool includeAlpha = true}) => '${leadingHashSign ? '#' : ''}'
      '${includeAlpha ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}