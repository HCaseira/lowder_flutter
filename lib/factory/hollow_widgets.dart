import 'package:flutter/material.dart';
import 'package:lowder/factory/widget_factory.dart';
import 'package:lowder/model/editor_node.dart';
import 'package:lowder/model/node_spec.dart';
import 'package:lowder/util/parser.dart';
import 'package:lowder/widget/lowder.dart';

class ButtonSegmentWidget extends SizedBox {
  static const String type = "ButtonSegment";
  static final Map<String, EditorPropertyType> properties = {
    "value": Types.string,
    "label": Types.string,
    "iconCode": Types.int,
    "enabled": Types.bool,
    "tooltip": Types.string,
  };
  static final Map<String, EditorWidgetType> widgets = {
    "label": EditorWidgetType.widget(),
    "icon": EditorWidgetType.widget(),
  };

  late final ButtonSegment? widget;

  ButtonSegmentWidget(BuildParameters params, {super.key}) {
    final props = params.props;
    final widgets = params.widgets;

    final value = props["value"];
    if (value != null) {
      final enabled = parseBool(props["enabled"], defaultValue: true);
      final tooltip = props["tooltip"]?.toString();
      final iconValue = parseInt(props["iconCode"]);

      var label = Lowder.widgets.tryBuildWidget(
          params.context, widgets["label"], params.state, params.parentContext);
      if (label == null && props["label"] != null) {
        label = Text(props["label"].toString());
      }
      label ??= Text(value.toString());

      var icon = Lowder.widgets.tryBuildWidget(
          params.context, widgets["icon"], params.state, params.parentContext);
      if (icon == null && iconValue > 0) {
        icon = Icon(IconData(parseInt(iconValue), fontFamily: "MaterialIcons"));
      }

      widget = ButtonSegment(
        value: value,
        enabled: enabled,
        tooltip: tooltip,
        label: label,
        icon: icon,
      );
    }
  }
}

class ChoiceChipValueWidget extends SizedBox {
  static const String type = "ChoiceChipValue";
  static const String chipType = "ChoiceChip";
  static final Map<String, EditorPropertyType> _properties = {
    "value": Types.string,
    "label": Types.string
  };
  static Map<String, EditorPropertyType> get properties => _properties;
  static final Map<String, EditorWidgetType> widgets = {
    "chip": EditorWidgetType(chipType)
  };

  late final dynamic value;
  late final WidgetNodeSpec? widget;

  ChoiceChipValueWidget(BuildParameters params, {super.key}) {
    value = params.props["value"];
    var label = params.props["label"];

    if (value != null) {
      final parentSpec = params.spec.extra["parentSpec"] as WidgetNodeSpec;
      final childSpec = params.widgets["chip"];

      if (childSpec != null) {
        widget = WidgetNodeSpec.fromMap(childSpec);
      } else if (label != null) {
        widget = WidgetNodeSpec(params.id, null, chipType, null, {
          "label": label.toString(),
        }, {}, {}, {});
      }

      if (widget != null) {
        if (label != null && widget!.props["label"] == null) {
          widget!.props["label"] = label;
        }
        for (var key in parentSpec.props.keys) {
          if (key != "alias" && widget!.props[key] == null) {
            widget!.props[key] = parentSpec.props[key];
          }
        }
      }

      for (var key in parentSpec.widgets.keys) {
        if (key != "chips" && widget!.widgets[key] == null) {
          widget!.widgets[key] = parentSpec.widgets[key];
        }
      }
    }
  }
}

class FilterChipValueWidget extends ChoiceChipValueWidget {
  static const String type = "FilterChipValue";
  static const String chipType = "FilterChip";
  static Map<String, EditorPropertyType> get properties =>
      ChoiceChipValueWidget._properties;
  static final Map<String, EditorWidgetType> widgets = {
    "chip": EditorWidgetType(chipType)
  };

  FilterChipValueWidget(super.params, {super.key});
}

class BlocStateWidget extends SizedBox {
  late final String type;
  late final String state;
  late final Map? listener;
  late final Map? widget;

  BlocStateWidget(BuildParameters params, {super.key}) {
    type = params.spec.type;
    state = params.props["state"] as String? ?? "";
    if (state.isNotEmpty) {
      listener = params.actions["listener"] as Map?;
      if (type != "StateListener") {
        widget = params.widgets["child"] as Map?;
      }
    }
  }
}
