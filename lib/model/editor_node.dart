import 'package:flutter/material.dart';

import '../util/parser.dart';
import '../widget/lowder.dart';

/// A series of structures and classes used to define the Schema
/// of Node and Property Types for the Editor to know.

abstract class EditorNodeBase {
  dynamic toJson();
}

/// Base class for informing the Editor of a Node Type's schema.
abstract class EditorNode extends EditorNodeBase {
  final bool abstract;
  final String? baseType;
  final Map<String, EditorPropertyType>? properties;

  EditorNode({this.baseType, required this.abstract, this.properties});

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (abstract) {
      map["abstract"] = abstract;
    }
    if (baseType != null && baseType!.isNotEmpty) {
      map["extends"] = baseType;
    }

    if (properties != null && properties!.isNotEmpty) {
      final props = <String, dynamic>{};
      map["properties"] = props;
      for (var key in properties!.keys) {
        props[key] = properties![key]!.getValueType();
      }
    }
    return map;
  }
}

/// Class for creating an Action's schema.
class EditorAction extends EditorNode {
  static const String terminationAction = "IAction";
  static const String action = "IStackAction";
  static const String listAction = "IListAction";

  final Map<String, EditorActionType>? actions;

  EditorAction({
    super.abstract = false,
    super.baseType = action,
    this.actions,
    super.properties,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (actions != null && actions!.isNotEmpty) {
      final props = <String, dynamic>{};
      map["actions"] = props;
      for (var key in actions!.keys) {
        props[key] = actions![key]!.getValueType();
      }
    }
    return map;
  }
}

/// Class for creating a Widget's schema.
class EditorWidget extends EditorNode {
  static const String rootWidget = "RootWidget";
  static const String preferredSizeWidget = "PreferredSizeWidget";
  static const String widget = "Widget";

  final Map<String, EditorWidgetType>? widgets;
  final Map<String, EditorActionType>? actions;
  final List<String>? tags;

  EditorWidget({
    super.abstract = false,
    super.baseType = widget,
    this.widgets,
    this.actions,
    super.properties,
    this.tags,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (actions != null && actions!.isNotEmpty) {
      final props = <String, dynamic>{};
      map["actions"] = props;
      for (var key in actions!.keys) {
        props[key] = actions![key]!.getValueType();
      }
    }
    if (widgets != null && widgets!.isNotEmpty) {
      final props = <String, dynamic>{};
      map["widgets"] = props;
      for (var key in widgets!.keys) {
        props[key] = widgets![key]!.getValueType();
      }
    }
    if (tags != null && tags!.isNotEmpty) {
      map["tags"] = tags;
    }
    return map;
  }
}

/// Class for creating an Property's schema.
class EditorSpecProperty extends EditorNode {
  EditorSpecProperty(Map<String, EditorPropertyType>? properties,
      {super.baseType, super.abstract = false})
      : super(properties: properties);
}

/// Class for registering a Property Type as a list of possible values.
/// e.g.:  registerListType(Types.textAlign.type, getTextAlign, ["left", "right", "center", "justify"]);
class EditorValueListProperty extends EditorNodeBase {
  final List<String> values;
  EditorValueListProperty(this.values) : super();

  @override
  List<String> toJson() => values;
}

/// Base class for informing the Editor of a Type's schema.
abstract class EditorType {
  final String type;
  final bool isArray;
  const EditorType(this.type, {this.isArray = false});

  dynamic getValueType() {
    return isArray ? "[$type]" : type;
  }
}

/// Class to define a Node's Action properties
class EditorActionType extends EditorType {
  EditorActionType(super.type, {super.isArray});

  factory EditorActionType.action() =>
      EditorActionType(EditorAction.terminationAction);
  factory EditorActionType.listAction() =>
      EditorActionType(EditorAction.listAction);
}

/// Class to define a Node's Widget properties
class EditorWidgetType extends EditorType {
  EditorWidgetType(super.type, {super.isArray});

  factory EditorWidgetType.rootWidget({bool isArray = false}) =>
      EditorWidgetType(EditorWidget.rootWidget, isArray: isArray);
  factory EditorWidgetType.preferredSizeWidget({bool isArray = false}) =>
      EditorWidgetType(EditorWidget.preferredSizeWidget, isArray: isArray);
  factory EditorWidgetType.widget({bool isArray = false}) =>
      EditorWidgetType(EditorWidget.widget, isArray: isArray);
}

/// Class to define a Node's Property properties.
class EditorPropertyType extends EditorType {
  const EditorPropertyType(super.type, {super.isArray});

  dynamic build(dynamic propValue, {dynamic argument}) {
    return Lowder.properties.build(type, propValue, argument: argument);
  }
}

// String type Property.
class EditorPropertyString extends EditorPropertyType {
  const EditorPropertyString({super.isArray}) : super("String");

  @override
  String? build(propValue, {argument}) => propValue?.toString();
}

/// Int type Property.
class EditorPropertyInt extends EditorPropertyType {
  const EditorPropertyInt({super.isArray}) : super("Int");

  @override
  int? build(propValue, {argument}) => tryParseInt(propValue);
}

/// Double type Property.
class EditorPropertyDouble extends EditorPropertyType {
  const EditorPropertyDouble({super.isArray}) : super("Double");

  @override
  double? build(propValue, {argument}) => tryParseDouble(propValue);
}

/// Bool type Property.
class EditorPropertyBool extends EditorPropertyType {
  const EditorPropertyBool({super.isArray}) : super("Bool");

  @override
  bool? build(propValue, {argument}) => tryParseBool(propValue);
}

/// Color type Property.
class EditorPropertyColor extends EditorPropertyType {
  const EditorPropertyColor({super.isArray}) : super("Color");

  @override
  Color? build(propValue, {argument}) => tryParseColor(propValue);
}

/// Json type Property.
class EditorPropertyJson extends EditorPropertyType {
  const EditorPropertyJson({super.isArray}) : super("Json");

  @override
  build(propValue, {argument}) => propValue;
}

/// Class for creating a Node's Property as a list of possible values
/// e.g.: "crossAxisAlignment": const EditorPropertyListType(["start", "center", "end"]),
class EditorPropertyListType extends EditorPropertyType {
  final List<String> values;
  const EditorPropertyListType(this.values) : super("", isArray: false);

  @override
  dynamic getValueType() {
    return values;
  }
}

/// A series of known [EditorPropertyType]s.
abstract class Types {
  static const string = EditorPropertyString();
  static const stringArray = EditorPropertyString(isArray: true);
  static const int = EditorPropertyInt();
  static const intArray = EditorPropertyInt(isArray: true);
  static const double = EditorPropertyDouble();
  static const doubleArray = EditorPropertyDouble(isArray: true);
  static const bool = EditorPropertyBool();
  static const color = EditorPropertyColor();
  static const json = EditorPropertyJson();

  static const screen = EditorPropertyType("Screen");
  static const formatter = EditorPropertyType("IFormatter");
  static const condition = EditorPropertyType("ICondition");
  static const operator = EditorPropertyType("Operator");
  static const request = EditorPropertyType("IRequest");

  static const safeArea = EditorPropertyType("SafeArea");
  static const fontWeight = EditorPropertyType("FontWeight");
  static const fontStyle = EditorPropertyType("FontStyle");
  static const textDecoration = EditorPropertyType("TextDecoration");
  static const edgeInsets = EditorPropertyType("EdgeInsets");
  static const boxShape = EditorPropertyType("BoxShape");
  static const borderType = EditorPropertyType("BorderType");
  static const navigationRailLabelType =
      EditorPropertyType("NavigationRailLabelType");
  static const floatingLabelBehavior =
      EditorPropertyType("FloatingLabelBehavior");
  static const materialType = EditorPropertyType("MaterialType");
  static const gradient = EditorPropertyType("Gradient");
  static const tableBorder = EditorPropertyType("TableBorder");
  static const border = EditorPropertyType("Border");
  static const borderSide = EditorPropertyType("BorderSide");
  static const shapeBorder = EditorPropertyType("ShapeBorder");
  static const tabController = EditorPropertyType("TabController");
  static const floatingActionButtonLocation =
      EditorPropertyType("FloatingActionButtonLocation");
  static const axis = EditorPropertyType("Axis");
  static const appBarLeadingIcon = EditorPropertyType("AppBarLeadingIcon");
  static const collapseMode = EditorPropertyType("CollapseMode");
  static const stretchMode = EditorPropertyType("StretchMode");
  static const boxDecoration = EditorPropertyType("BoxDecoration");
  static const boxConstraints = EditorPropertyType("BoxConstraints");
  static const notchedShape = EditorPropertyType("NotchedShape");
  static const alignment = EditorPropertyType("Alignment");
  static const tableVerticalAlignment =
      EditorPropertyType("TableVerticalAlignment");
  static const verticalDirection = EditorPropertyType("VerticalDirection");
  static const crossAxisAlignment = EditorPropertyType("CrossAxisAlignment");
  static const mainAxisAlignment = EditorPropertyType("MainAxisAlignment");
  static const mainAxisSize = EditorPropertyType("MainAxisSize");
  // static const EditorPropertyType decoration = EditorPropertyType("Decoration");
  static const tabBarIndicatorSize = EditorPropertyType("TabBarIndicatorSize");
  static const visualDensity = EditorPropertyType("VisualDensity");
  static const loadingIndicator = EditorPropertyType("LoadingIndicator");
  static const textStyle = EditorPropertyType("TextStyle");
  static const textAlign = EditorPropertyType("TextAlign");
  static const textOverflow = EditorPropertyType("TextOverflow");
  static const textAlignVertical = EditorPropertyType("TextAlignVertical");
  static const textCapitalization = EditorPropertyType("TextCapitalization");
  static const textInputType = EditorPropertyType("TextInputType");
  static const textInputFormatter = EditorPropertyType("TextInputFormatter");
  static const textInputAction = EditorPropertyType("TextInputAction");
  static const inputBorder = EditorPropertyType("InputBorder");
  static const inputDecoration = EditorPropertyType("InputDecoration");
  static const toolbarOptions = EditorPropertyType("ToolbarOptions");
  static const buttonStyle = EditorPropertyType("ButtonStyle");
  static const boxFit = EditorPropertyType("BoxFit");
  static const imageProvider = EditorPropertyType("ImageProvider");
  static const iconThemeData = EditorPropertyType("IconThemeData");
  static const routeTransitionBuilder =
      EditorPropertyType("RouteTransitionBuilder");
  static const size = EditorPropertyType("Size");
  static const shadow = EditorPropertyType("Shadow");
  static const boxShadow = EditorPropertyType("BoxShadow");
  static const curve = EditorPropertyType("Curve");
  static const keyboardDismissBehavior =
      EditorPropertyType("KeyboardDismissBehavior");
  static const matrix4 = EditorPropertyType("Matrix4");
  static const offset = EditorPropertyType("Offset");
}
