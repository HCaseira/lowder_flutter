import 'package:flutter/material.dart';
import 'package:lowder/factory/properties.dart';
import 'package:lowder/factory/property_factory.dart';
import 'package:lowder/model/editor_node.dart';
import 'package:lowder/util/parser.dart';

class SolutionProperties extends PropertyFactory with IProperties {
  @override
  void registerProperties() {
    registerSpecType("BorderSide", getBorderSide, {
      "color": Types.color,
      "width": Types.int,
    });
  }

  BorderSide getBorderSide(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return BorderSide.none;
    }

    return BorderSide(
      color: parseColor(spec["color"], defaultColor: Colors.black),
      width: parseDouble(spec["width"], defaultValue: 1.0),
    );
  }
}
