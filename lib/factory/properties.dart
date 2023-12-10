import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../util/parser.dart';
import '../util/strings.dart';
import '../model/editor_node.dart';
import '../widget/lowder.dart';

typedef ValueBuildFunction = dynamic Function(String? value);
typedef SpecBuildFunction = dynamic Function(Map? spec);
typedef ValueSpecBuildFunction = dynamic Function(dynamic value, Map? spec);

/// An interface for registering a Solution's Properties.
mixin IProperties {
  final Map<String, Function> _propertyBuilders = {};
  final Map<String, EditorNodeBase> _schema = {};

  Map<String, Function> get builders => _propertyBuilders;
  Map<String, EditorNodeBase> get schema => _schema;

  @nonVirtual
  Map<String, dynamic> getSchema() {
    var schema = <String, dynamic>{};
    for (var key in _schema.keys) {
      schema[key] = _schema[key]!.toJson();
    }
    return schema;
  }

  void registerProperties();

  @nonVirtual
  void registerListType(String name, ValueBuildFunction func, List<String> values) {
    _propertyBuilders[name] = func;
    _schema[name] = EditorValueListProperty(values);
  }

  @nonVirtual
  void registerAbstractType(String name, Map<String, EditorPropertyType> properties) {
    _schema[name] = EditorSpecProperty(properties, abstract: true);
  }

  @nonVirtual
  void registerSpecType(String name, SpecBuildFunction func, Map<String, EditorPropertyType> properties,
      {Map<String, Map<String, EditorPropertyType>>? subTypes}) {
    _propertyBuilders[name] = func;
    _schema[name] = EditorSpecProperty(properties, abstract: subTypes != null && subTypes.isNotEmpty);
    if (subTypes != null) {
      for (var subType in subTypes.keys) {
        _schema[subType] = EditorSpecProperty(subTypes[subType], baseType: name);
      }
    }
  }

  @nonVirtual
  void registerValueSpecType(String name, ValueSpecBuildFunction func, Map<String, EditorPropertyType> properties,
      {Map<String, Map<String, EditorPropertyType>>? subTypes}) {
    _propertyBuilders[name] = func;
    _schema[name] = EditorSpecProperty(properties, abstract: subTypes != null && subTypes.isNotEmpty);
    if (subTypes != null) {
      for (var subType in subTypes.keys) {
        _schema[subType] = EditorSpecProperty(subTypes[subType], baseType: name);
      }
    }
  }

  @nonVirtual
  void registerSubType(String baseType, String name, Map<String, EditorPropertyType> properties) {
    _schema[name] = EditorSpecProperty(properties, baseType: baseType);
  }
}

/// An empty implementation of [IProperties] to be used when there are no Properties to declare.
class NoProperties with IProperties {
  @override
  void registerProperties() {
    // No properties to register
  }
}

/// The Lowder's Property preset.
class BaseProperties with IProperties {
  static final _instance = BaseProperties._();
  BaseProperties._();
  factory BaseProperties() => _instance;

  @override
  void registerProperties() {
    registerAbstractType("KModel", {});
    registerAbstractType("KRequest", {
      "url": Types.string,
      "path": Types.string,
      "method": const EditorPropertyListType(["get", "post", "put", "delete", "patch"]),
      "pathParameters": const EditorPropertyType("KModel"),
      "queryArgs": const EditorPropertyType("KModel"),
      "body": const EditorPropertyType("KModel"),
    });
    registerSpecType("KConfirmMessage", (_) => null, {
      "title": Types.string,
      "message": Types.string,
      "attributes": Types.json,
    });
    registerSpecType("Decorator", (_) => null, {
      "width": Types.int,
      "height": Types.int,
      "padding": Types.intArray,
      "alignment": Types.alignment,
      "constraints": Types.boxConstraints,
      "decoration": Types.boxDecoration,
    });

    registerSpecType(Types.safeArea.type, (_) => null, {
      "left": Types.bool,
      "top": Types.bool,
      "right": Types.bool,
      "bottom": Types.bool,
      "minimum": Types.intArray,
    });

    registerListType(Types.kOperator.type, (v) => v, ["==", "!=", ">", ">=", "<", "<=", "contain", "not contain"]);
    registerListType(Types.materialType.type, getMaterialType, ["canvas", "card", "circle", "button", "transparency"]);
    registerListType(Types.appBarLeadingIcon.type, getAppBarLeadingWidget, ["back", "close"]);
    registerListType(Types.alignment.type, getAlignment, [
      "topLeft",
      "topCenter",
      "topRight",
      "bottomLeft",
      "bottomCenter",
      "bottomRight",
      "centerLeft",
      "center",
      "centerRight"
    ]);
    registerListType(
        Types.tableVerticalAlignment.type, getTableCellVerticalAlignment, ["top", "middle", "bottom", "baseline", "fill"]);
    registerListType(Types.verticalDirection.type, getVerticalDirection, ["up", "down"]);
    registerListType(
        Types.crossAxisAlignment.type, getCrossAxisAlignment, ["center", "start", "end", "stretch", "baseline"]);
    registerListType(Types.mainAxisAlignment.type, getMainAxisAlignment,
        ["center", "start", "end", "spaceEvenly", "spaceAround", "spaceBetween"]);
    registerListType(Types.mainAxisSize.type, getMainAxisSize, ["min", "max"]);
    registerListType(Types.fontWeight.type, getFontWeight,
        ["normal", "bold", "100", "200", "300", "400", "500", "600", "700", "800", "900"]);
    registerListType(Types.fontStyle.type, getFontStyle, ["normal", "italic"]);
    registerListType(Types.textAlign.type, getTextAlign, ["left", "right", "center", "justify"]);
    registerListType(Types.textAlignVertical.type, getTextAlignVertical, ["top", "center", "bottom"]);
    registerListType(Types.textOverflow.type, getTextOverflow, ["clip", "ellipsis", "fade", "visible"]);
    registerListType(Types.textInputType.type, getTextInputType,
        ["datetime", "email", "multiline", "name", "number", "int", "decimal", "phone", "url", "password"]);
    registerListType(Types.textCapitalization.type, getTextCapitalization, ["words", "sentences", "characters", "none"]);
    registerListType(Types.textDecoration.type, getTextDecoration, ["overline", "underline", "lineThrough"]);
    registerListType(Types.floatingLabelBehavior.type, getFloatingLabelBehavior, ["auto", "always", "never"]);
    registerListType(Types.floatingActionButtonLocation.type, getFloatingActionButtonLocation, [
      "centerTop",
      "centerFloat",
      "centerDocked",
      "startTop",
      "startFloat",
      "startDocked",
      "endTop",
      "endFloat",
      "endDocked"
    ]);
    registerListType(Types.boxShape.type, getBoxShape, ["rectangle", "circle"]);
    registerListType(Types.borderType.type, (v) => v, ["all", "vertical", "horizontal", "left", "top", "right", "bottom"]);
    registerListType(Types.axis.type, getAxis, ["vertical", "horizontal"]);
    registerListType(
        Types.boxFit.type, getBoxFit, ["none", "fill", "contain", "cover", "fitWidth", "fitHeight", "scaleDown"]);
    registerListType(Types.tabBarIndicatorSize.type, getTabBarIndicatorSize, ["tab", "label"]);
    registerListType(Types.collapseMode.type, getCollapseMode, ["pin", "parallax", "none"]);
    registerListType(Types.stretchMode.type, getStretchMode, ["fadeTitle", "blurBackground", "zoomBackground"]);
    registerListType(Types.navigationRailLabelType.type, getNavigationRailLabelType, ["none", "selected", "all"]);
    registerListType(Types.routeTransitionBuilder.type, getRouteTransitionsBuilder,
        ["slideLeft", "slideRight", "slideUp", "size", "scale", "fade", "none"]);

    registerSpecType(Types.kCondition.type, (spec) => spec != null ? Lowder.properties.evaluateCondition(spec) : false, {
      "and": Types.kCondition,
      "or": Types.kCondition,
    }, subTypes: {
      "OperatorCondition": {
        "left": Types.string,
        "operator": Types.kOperator,
        "right": Types.string,
      }
    });

    registerValueSpecType(Types.kFormatter.type, formatValue, {}, subTypes: {
      "KFormatterTranslate": {
        "transform": const EditorPropertyListType(["upper", "lower", "capitalize", "title", "none"]),
        "attributes": Types.json,
      },
      "KFormatterDate": {
        "format": Types.string,
      },
      "KFormatterTime": {
        "format": Types.string,
      },
      "KFormatterNumber": {
        "format": Types.string,
      },
      "KFormatterCurrency": {
        "symbol": Types.string,
        "decimalDigits": Types.int,
      },
      "KFormatterNone": {},
    });

    registerValueSpecType(Types.tabController.type, getTabController, {
      "length": Types.int,
      "initialIndex": Types.int,
    });
    // registerSpecProperty("EdgeInsets", getInsets, EditorSpecProperty({
    //   "left": EditorPropertyType.int(),
    //   "top": EditorPropertyType.int(),
    //   "right": EditorPropertyType.int(),
    //   "bottom": EditorPropertyType.int(),
    // }));

    registerSpecType(Types.boxConstraints.type, getBoxConstraints, {
      "minWidth": Types.int,
      "maxWidth": Types.int,
      "minHeight": Types.int,
      "maxHeight": Types.int,
    });

    registerSpecType(Types.size.type, getSize, {"width": Types.double, "height": Types.double});

    registerSpecType(Types.tableBorder.type, getTableBorder, {
      "left": Types.borderSide,
      "top": Types.borderSide,
      "right": Types.borderSide,
      "bottom": Types.borderSide,
      "horizontalInside": Types.borderSide,
      "verticalInside": Types.borderSide,
    });
    registerSpecType(Types.border.type, getBorder, {
      "type": Types.borderType,
      "color": Types.color,
      "width": Types.int,
    });
    registerSpecType(Types.borderSide.type, getBorderSide, {
      "color": Types.color,
      "width": Types.int,
    });
    registerSpecType(Types.shapeBorder.type, getShapeBorder, {
      "type": const EditorPropertyListType(["circle", "roundedRectangle", "beveledRectangle", "continuousRectangle"]),
      "borderRadius": Types.intArray,
      "color": Types.color,
      "width": Types.double,
    });

    registerSpecType(Types.shadow.type, getShadow, {
      "color": Types.color,
      "blurRadius": Types.double,
      "offset": Types.double,
    });
    registerSpecType(Types.boxShadow.type, getBoxShadow, {
      "color": Types.color,
      "blurRadius": Types.double,
      "spreadRadius": Types.double,
      "offset": Types.double,
    });
    registerSpecType(Types.boxDecoration.type, getBoxDecoration, {
      "color": Types.color,
      "border": Types.border,
      "borderRadius": Types.intArray,
      "boxShape": Types.boxShape,
      "boxShadow": Types.boxShadow,
      "gradient": Types.gradient,
    });

    registerSpecType(Types.notchedShape.type, getNotchedShape, {}, subTypes: {
      "CircularNotchedRectangle": {},
      "AutomaticNotchedShape": {
        "host": Types.shapeBorder,
        "guest": Types.shapeBorder,
      },
    });

    registerSpecType(Types.textStyle.type, getTextStyle, {
      "fontFamily": Types.string,
      "fontSize": Types.int,
      "fontWeight": Types.fontWeight,
      "fontStyle": Types.fontStyle,
      "height": Types.double,
      "wordSpacing": Types.double,
      "letterSpacing": Types.double,
      "overflow": Types.textOverflow,
      "decoration": Types.textDecoration,
      "color": Types.color,
      "backgroundColor": Types.color,
    });
    registerSpecType(Types.toolbarOptions.type, getContextMenuBuilder, {
      "copy": Types.bool,
      "cut": Types.bool,
      "paste": Types.bool,
      "delete": Types.bool,
      "selectAll": Types.bool,
      "liveTextInput": Types.bool,
    });
    registerSpecType(Types.inputBorder.type, getInputBorder, {
      "color": Types.color,
      "width": Types.int,
      "borderRadius": Types.intArray,
    }, subTypes: {
      "OutlineInputBorder": {"gapPadding": Types.double},
      "UnderlineInputBorder": {"gapPadding": Types.double},
    });
    registerValueSpecType(Types.inputDecoration.type, getInputDecoration, {
      "alignLabelWithHint": Types.bool,
      "isCollapsed": Types.bool,
      "isDense": Types.bool,
      "constraints": Types.boxConstraints,
      "border": Types.inputBorder,
      "disabledBorder": Types.inputBorder,
      "enabledBorder": Types.inputBorder,
      "errorBorder": Types.inputBorder,
      "focusedBorder": Types.inputBorder,
      "focusedErrorBorder": Types.inputBorder,
      "contentPadding": Types.intArray,
      "labelText": Types.string,
      "labelStyle": Types.textStyle,
      "errorText": Types.string,
      "errorStyle": Types.textStyle,
      "focusColor": Types.color,
      "fillColor": Types.color,
      "hoverColor": Types.color,
      "hintText": Types.string,
      "hintStyle": Types.textStyle,
      "prefixText": Types.string,
      "prefixStyle": Types.textStyle,
      "suffixText": Types.string,
      "suffixStyle": Types.textStyle,
      "helperText": Types.string,
      "helperStyle": Types.textStyle,
      "floatingLabelStyle": Types.textStyle,
      "floatingLabelBehavior": Types.floatingLabelBehavior,
    });
    registerSpecType(Types.textInputFormatter.type, getTextInputFormatters, {
      "allow": Types.string,
      "deny": Types.string,
      "mask": Types.string,
      "maskFilter": Types.string,
    });
    registerListType(Types.textInputAction.type, getTextInputAction, [
      "none",
      "done",
      "continueAction",
      "go",
      "next",
      "previous",
      "newline",
      "unspecified",
      "send",
      "search",
      "join",
      "route",
      "emergencyCall"
    ]);

    registerSpecType(Types.gradient.type, getGradient, {
      "colors": Types.stringArray,
      "stops": Types.doubleArray,
    }, subTypes: {
      "LinearGradient": {
        "begin": Types.alignment,
        "end": Types.alignment,
      },
      "RadialGradient": {
        "center": Types.alignment,
        "focal": Types.alignment,
        "focalRadius": Types.double,
        "radius": Types.double,
      },
      "SweepGradient": {
        "startAngle": Types.double,
        "endAngle": Types.double,
        "center": Types.alignment,
      }
    });

    registerValueSpecType(Types.imageProvider.type, getImageProvider, {}, subTypes: {
      "AssetImage": {
        "package": Types.string,
      },
      "NetworkImage": {
        "scale": Types.double,
      },
      "MemoryImage": {
        "scale": Types.double,
      },
      "FileImage": {
        "scale": Types.double,
      },
    });

    registerSpecType(Types.iconThemeData.type, getIconThemeData, {
      "color": Types.color,
      "opacity": Types.double,
      "size": Types.double,
      "shadow": Types.shadow,
    });

    registerSpecType(Types.buttonStyle.type, getButtonStyle, {
      "alignment": Types.alignment,
      "padding": Types.intArray,
      "foregroundColor": Types.color,
      "backgroundColor": Types.color,
      "overlayColor": Types.color,
      "shape": Types.shapeBorder,
      "side": Types.borderSide,
      "textStyle": Types.textStyle,
      "fixedSize": Types.size,
      "minimumSize": Types.size,
      "maximumSize": Types.size,
    });

    registerSpecType(Types.loadingIndicator.type, getLoadingIndicator, {
      "color": Types.color,
      "backgroundColor": Types.color,
      "strokeWidth": Types.double,
    });

    registerListType(Types.curve.type, getCurve, [
      "linear",
      "decelerate",
      "fastLinearToSlowEaseIn",
      "fastEaseInToSlowEaseOut",
      "ease",
      "easeIn",
      "easeInToLinear",
      "easeInSine",
      "easeInQuad",
      "easeInCubic",
      "easeInQuart",
      "easeInQuint",
      "easeInExpo",
      "easeInCirc",
      "easeInBack",
      "easeOut",
      "linearToEaseOut",
      "easeOutSine",
      "easeOutQuad",
      "easeOutCubic",
      "easeOutQuart",
      "easeOutQuint",
      "easeOutExpo",
      "easeOutCirc",
      "easeOutBack",
      "easeInOut",
      "easeInOutSine",
      "easeInOutQuad",
      "easeInOutCubic",
      "easeInOutCubicEmphasized",
      "easeInOutQuart",
      "easeInOutQuint",
      "easeInOutExpo",
      "easeInOutCirc",
      "easeInOutBack",
      "fastOutSlowIn",
      "slowMiddle",
      "bounceIn",
      "bounceOut",
      "bounceInOut",
      "elasticIn",
      "elasticOut",
      "elasticInOut",
    ]);
  }

  MaterialType? getMaterialType(String? type) {
    if (type == null || type.isEmpty) {
      return null;
    }

    switch (type) {
      case "canvas":
        return MaterialType.canvas;
      case "card":
        return MaterialType.card;
      case "circle":
        return MaterialType.circle;
      case "button":
        return MaterialType.button;
      case "transparency":
        return MaterialType.transparency;
      default:
        return null;
    }
  }

  Widget? getAppBarLeadingWidget(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "back":
        return const BackButton();
      case "close":
        return const CloseButton();
      default:
        return null;
    }
  }

  Widget? getTabController(dynamic child, Map? spec) {
    if (child == null || spec == null || spec.isEmpty) {
      return child;
    }

    return DefaultTabController(
      length: parseInt(spec["length"]),
      initialIndex: parseInt(spec["initialIndex"]),
      child: child,
    );
  }

  RouteTransitionsBuilder? getRouteTransitionsBuilder(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return (context, animation, secondaryAnimation, child) {
      switch (value) {
        case "fade":
          return FadeTransition(opacity: animation, child: child);
        case "scale":
          return ScaleTransition(scale: animation, child: child);
        case "size":
          return SizeTransition(sizeFactor: animation, child: child);
        case "slideUp":
          return SlideTransition(
            position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)),
            child: child,
          );
        case "slideLeft":
          return SlideTransition(
            position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
            child: child,
          );
        case "slideRight":
          return SlideTransition(
            position: animation.drive(Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)),
            child: child,
          );
        default:
          return child;
      }
    };
  }

  TextInputType getTextInputType(String? inputType) {
    inputType ??= "default";
    switch (inputType) {
      case "datetime":
        return TextInputType.datetime;
      case "email":
        return TextInputType.emailAddress;
      case "multiline":
        return TextInputType.multiline;
      case "name":
        return TextInputType.name;
      case "number":
        return TextInputType.number;
      case "int":
        return const TextInputType.numberWithOptions(signed: false, decimal: false);
      case "decimal":
        return const TextInputType.numberWithOptions(signed: false, decimal: true);
      case "phone":
        return TextInputType.phone;
      case "url":
        return TextInputType.url;
      case "password":
        return TextInputType.visiblePassword;
      default:
        return TextInputType.text;
    }
  }

  TextAlign getTextAlign(String? align) {
    align ??= "default";
    switch (align) {
      case "right":
        return TextAlign.right;
      case "center":
        return TextAlign.center;
      case "justify":
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  TextAlignVertical? getTextAlignVertical(String? align) {
    if (align == null) {
      return null;
    }

    switch (align) {
      case "top":
        return TextAlignVertical.top;
      case "center":
        return TextAlignVertical.center;
      case "bottom":
        return TextAlignVertical.bottom;
      default:
        return null;
    }
  }

  TextOverflow? getTextOverflow(String? overflow) {
    overflow ??= "default";
    switch (overflow) {
      case "clip":
        return TextOverflow.clip;
      case "ellipsis":
        return TextOverflow.ellipsis;
      case "fade":
        return TextOverflow.fade;
      case "visible":
        return TextOverflow.visible;
      default:
        return null;
    }
  }

  TextBaseline? getTextBaseline(String? value) {
    if (value == null) {
      return null;
    }

    switch (value) {
      case "alphabetic":
        return TextBaseline.alphabetic;
      case "ideographic":
        return TextBaseline.ideographic;
      default:
        return null;
    }
  }

  EditableTextContextMenuBuilder? getContextMenuBuilder(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    return (context, editableTextState) {
      final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
      if (!parseBool(spec["copy"], defaultValue: true)) {
        buttonItems.removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.copy);
      }
      if (!parseBool(spec["cut"], defaultValue: true)) {
        buttonItems.removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.cut);
      }
      if (!parseBool(spec["paste"], defaultValue: true)) {
        buttonItems.removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.paste);
      }
      if (!parseBool(spec["delete"], defaultValue: true)) {
        buttonItems.removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.delete);
      }
      if (!parseBool(spec["selectAll"], defaultValue: true)) {
        buttonItems.removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.selectAll);
      }
      if (!parseBool(spec["liveTextInput"], defaultValue: true)) {
        buttonItems
            .removeWhere((ContextMenuButtonItem buttonItem) => buttonItem.type == ContextMenuButtonType.liveTextInput);
      }

      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editableTextState.contextMenuAnchors,
        buttonItems: buttonItems,
      );
    };
  }

  TextCapitalization getTextCapitalization(String? value) {
    value ??= "default";
    switch (value) {
      case "words":
        return TextCapitalization.words;
      case "sentences":
        return TextCapitalization.sentences;
      case "characters":
        return TextCapitalization.characters;
      default:
        return TextCapitalization.none;
    }
  }

  VerticalDirection getVerticalDirection(String? value) {
    if ("up" == value) {
      return VerticalDirection.up;
    }
    return VerticalDirection.down;
  }

  CrossAxisAlignment getCrossAxisAlignment(String? value) {
    value ??= "default";
    switch (value) {
      case "baseline":
        return CrossAxisAlignment.baseline;
      case "start":
        return CrossAxisAlignment.start;
      case "end":
        return CrossAxisAlignment.end;
      case "stretch":
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  MainAxisAlignment getMainAxisAlignment(String? value) {
    value ??= "default";
    switch (value) {
      case "center":
        return MainAxisAlignment.center;
      case "end":
        return MainAxisAlignment.end;
      case "spaceEvenly":
        return MainAxisAlignment.spaceEvenly;
      case "spaceAround":
        return MainAxisAlignment.spaceAround;
      case "spaceBetween":
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
    }
  }

  MainAxisSize getMainAxisSize(String? value) => value == "min" ? MainAxisSize.min : MainAxisSize.max;

  TableCellVerticalAlignment? getTableCellVerticalAlignment(String? value) {
    if (value == null) {
      return null;
    }

    switch (value) {
      case "top":
        return TableCellVerticalAlignment.top;
      case "middle":
        return TableCellVerticalAlignment.middle;
      case "bottom":
        return TableCellVerticalAlignment.bottom;
      case "baseline":
        return TableCellVerticalAlignment.baseline;
      case "fill":
        return TableCellVerticalAlignment.fill;
      default:
        return null;
    }
  }

  BoxConstraints? getBoxConstraints(Map? spec) {
    if (spec == null ||
        (spec["minWidth"] == null && spec["maxWidth"] == null && spec["minHeight"] == null && spec["maxHeight"] == null)) {
      return null;
    }

    return BoxConstraints(
      minWidth: parseDouble(spec["minWidth"], defaultValue: 0),
      maxWidth: parseDouble(spec["maxWidth"], defaultValue: double.infinity),
      minHeight: parseDouble(spec["minHeight"], defaultValue: 0),
      maxHeight: parseDouble(spec["maxHeight"], defaultValue: double.infinity),
    );
  }

  Alignment? getAlignment(String? value) {
    if (value == null) return null;

    switch (value) {
      case "topLeft":
        return Alignment.topLeft;
      case "topCenter":
        return Alignment.topCenter;
      case "topRight":
        return Alignment.topRight;
      case "bottomLeft":
        return Alignment.bottomLeft;
      case "bottomCenter":
        return Alignment.bottomCenter;
      case "bottomRight":
        return Alignment.bottomRight;
      case "centerLeft":
        return Alignment.centerLeft;
      case "center":
        return Alignment.center;
      case "centerRight":
        return Alignment.centerRight;
      default:
        return null;
    }
  }

  WrapAlignment getWrapAlignment(String? value) {
    value ??= "default";

    switch (value) {
      case "center":
        return WrapAlignment.center;
      case "end":
        return WrapAlignment.end;
      case "spaceEvenly":
        return WrapAlignment.spaceEvenly;
      case "spaceAround":
        return WrapAlignment.spaceAround;
      case "spaceBetween":
        return WrapAlignment.spaceBetween;
      default:
        return WrapAlignment.start;
    }
  }

  WrapCrossAlignment getWrapCrossAlignment(String? value) {
    value ??= "default";
    switch (value) {
      case "center":
        return WrapCrossAlignment.center;
      case "end":
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }

  Decoration? getBoxDecoration(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    List<BoxShadow>? shadowList;
    var shadow = getBoxShadow(spec["boxShadow"]);
    if (shadow != null) {
      shadowList = [shadow];
    }

    return BoxDecoration(
      color: tryParseColor(spec["color"]),
      border: getBorder(spec["border"]),
      borderRadius: getBorderRadius(spec["borderRadius"]),
      shape: getBoxShape(spec["boxShape"]) ?? BoxShape.rectangle,
      boxShadow: shadowList,
      gradient: getGradient(spec["gradient"]),
    );
  }

  InputDecoration? getInputDecoration(dynamic widgets, Map? spec) {
    if (spec == null || spec.isEmpty) return null;
    Map? widgetMap;
    if (widgets is Map) {
      widgetMap = widgets;
    }

    return InputDecoration(
      isCollapsed: parseBool(spec["isCollapsed"]),
      isDense: tryParseBool(spec["isDense"]),
      alignLabelWithHint: tryParseBool(spec["alignLabelWithHint"]),
      constraints: getBoxConstraints(spec["constraints"]),
      border: getInputBorder(spec["border"]),
      disabledBorder: getInputBorder(spec["disabledBorder"]),
      enabledBorder: getInputBorder(spec["enabledBorder"]),
      errorBorder: getInputBorder(spec["errorBorder"]),
      focusedBorder: getInputBorder(spec["focusedBorder"]),
      focusedErrorBorder: getInputBorder(spec["focusedErrorBorder"]),
      contentPadding: Lowder.properties.getInsets(spec["contentPadding"]),
      errorText: spec["errorText"] != null ? Lowder.properties.getText(spec["errorText"], "errorMessage") : null,
      errorStyle: getTextStyle(spec["errorStyle"]),
      label: widgetMap?["label"],
      labelText: spec["labelText"] != null ? Lowder.properties.getText(spec["labelText"], "label") : null,
      labelStyle: getTextStyle(spec["labelStyle"]),
      focusColor: tryParseColor(spec["focusColor"]),
      filled: tryParseColor(spec["fillColor"]) != null,
      fillColor: tryParseColor(spec["fillColor"]),
      hoverColor: tryParseColor(spec["hoverColor"]),
      hintText: spec["hintText"] != null ? Lowder.properties.getText(spec["hintText"], "hintText") : null,
      hintStyle: getTextStyle(spec["hintStyle"]),
      floatingLabelStyle: getTextStyle(spec["floatingLabelStyle"]),
      floatingLabelBehavior: getFloatingLabelBehavior(spec["floatingLabelBehavior"]),
      prefix: widgetMap?["prefix"],
      prefixIcon: widgetMap?["prefixIcon"],
      prefixText: spec["prefixText"] != null ? Lowder.properties.getText(spec["prefixText"], "prefixText") : null,
      prefixStyle: getTextStyle(spec["prefixStyle"]),
      suffix: widgetMap?["suffix"],
      suffixIcon: widgetMap?["suffixIcon"],
      suffixText: spec["suffixText"] != null ? Lowder.properties.getText(spec["suffixText"], "suffixText") : null,
      suffixStyle: getTextStyle(spec["suffixStyle"]),
      helperText: spec["helperText"] != null ? Lowder.properties.getText(spec["helperText"], "helperText") : null,
      helperStyle: getTextStyle(spec["helperStyle"]),
      icon: widgetMap?["icon"],
    );
  }

  FloatingLabelBehavior? getFloatingLabelBehavior(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "always":
        return FloatingLabelBehavior.always;
      case "never":
        return FloatingLabelBehavior.never;
      default:
        return FloatingLabelBehavior.auto;
    }
  }

  FloatingActionButtonLocation? getFloatingActionButtonLocation(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "centerTop":
        return FloatingActionButtonLocation.centerTop;
      case "centerFloat":
        return FloatingActionButtonLocation.centerFloat;
      case "centerDocked":
        return FloatingActionButtonLocation.centerDocked;
      case "startTop":
        return FloatingActionButtonLocation.startTop;
      case "startFloat":
        return FloatingActionButtonLocation.startFloat;
      case "startDocked":
        return FloatingActionButtonLocation.startDocked;
      case "endTop":
        return FloatingActionButtonLocation.endTop;
      case "endFloat":
        return FloatingActionButtonLocation.endFloat;
      case "endDocked":
        return FloatingActionButtonLocation.endDocked;
      default:
        return null;
    }
  }

  NotchedShape? getNotchedShape(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    var type = spec["_type"] ?? "default";
    switch (type) {
      case "CircularNotchedRectangle":
        return const CircularNotchedRectangle();
      case "AutomaticNotchedShape":
        final hostShape = getShapeBorder(spec["host"]);
        if (hostShape == null) return null;
        return AutomaticNotchedShape(hostShape, getShapeBorder(spec["guest"]));
      default:
        return null;
    }
  }

  TableBorder? getTableBorder(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    return TableBorder(
      left: getBorderSide(spec["left"]) ?? BorderSide.none,
      top: getBorderSide(spec["top"]) ?? BorderSide.none,
      right: getBorderSide(spec["right"]) ?? BorderSide.none,
      bottom: getBorderSide(spec["bottom"]) ?? BorderSide.none,
      horizontalInside: getBorderSide(spec["horizontalInside"]) ?? BorderSide.none,
      verticalInside: getBorderSide(spec["verticalInside"]) ?? BorderSide.none,
    );
  }

  Border? getBorder(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    var type = spec["type"] ?? "all";
    var border = getBorderSide(spec)!;

    switch (type) {
      case "vertical":
        return Border.symmetric(vertical: border);
      case "horizontal":
        return Border.symmetric(horizontal: border);
      case "left":
        return Border(left: border);
      case "top":
        return Border(top: border);
      case "right":
        return Border(right: border);
      case "bottom":
        return Border(bottom: border);
      default:
        return Border.fromBorderSide(border);
    }
  }

  BorderSide? getBorderSide(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }
    return BorderSide(
      color: parseColor(spec["color"], defaultColor: Colors.black),
      width: parseDouble(spec["width"], defaultValue: 1.0),
    );
  }

  InputBorder? getInputBorder(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    var type = spec["_type"] ?? "default";
    var borderSide = BorderSide(
      color: parseColor(spec["color"], defaultColor: Colors.black),
      width: parseDouble(spec["width"], defaultValue: 1.0),
    );

    switch (type) {
      case "OutlineInputBorder":
        return OutlineInputBorder(
          borderSide: borderSide,
          borderRadius: getBorderRadius(spec["borderRadius"]) ?? const BorderRadius.all(Radius.circular(4.0)),
          gapPadding: parseDouble(spec["gapPadding"], defaultValue: 4.0),
        );
      default:
        return UnderlineInputBorder(
            borderSide: borderSide,
            borderRadius: getBorderRadius(spec["borderRadius"]) ??
                const BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)));
    }
  }

  Shadow? getShadow(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    return Shadow(
      color: parseColor(spec["color"], defaultColor: const Color(0xFF000000)),
      blurRadius: parseDouble(spec["blurRadius"], defaultValue: 0.0),
      offset: getOffset(spec["offset"]) ?? Offset.zero,
    );
  }

  BoxShadow? getBoxShadow(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    return BoxShadow(
      color: parseColor(spec["color"], defaultColor: const Color(0xFF000000)),
      blurRadius: parseDouble(spec["blurRadius"], defaultValue: 0.0),
      spreadRadius: parseDouble(spec["spreadRadius"], defaultValue: 0.0),
      offset: getOffset(spec["offset"]) ?? Offset.zero,
    );
  }

  Offset? getOffset(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return Offset(parseDouble(value), parseDouble(value));
    }

    var parts = value.split("|");
    if (parts.length == 1) {
      return Offset(parseDouble(parts[0]), parseDouble(parts[0]));
    }
    return Offset(parseDouble(parts[0]), parseDouble(parts[1]));
  }

  BoxShape? getBoxShape(String? value) {
    if (value == null) return null;
    switch (value) {
      case "circle":
        return BoxShape.circle;
      default:
        return BoxShape.rectangle;
    }
  }

  Gradient? getGradient(Map? spec) {
    if (spec == null || spec.isEmpty || spec["colors"] == null) {
      return null;
    }

    final colors = <Color>[];
    var colorParts = (spec["colors"] as String).split("|");
    for (var part in colorParts) {
      var color = tryParseColor(part);
      if (color != null) {
        colors.add(color);
      }
    }

    List<double>? stops;
    var stopParts = (spec["stops"] as String).split("|");
    if (stopParts.length == colors.length) {
      stops = <double>[];
      for (var part in stopParts) {
        stops.add(parseDouble(part));
      }
    }

    var type = spec["_type"] ?? "default";
    switch (type) {
      case "SweepGradient":
        return SweepGradient(
          colors: colors,
          stops: stops,
          startAngle: parseDouble(spec["startAngle"], defaultValue: 0.0),
          endAngle: parseDouble(spec["endAngle"], defaultValue: math.pi * 2),
          center: getAlignment(spec["center"]) ?? Alignment.center,
        );
      case "RadialGradient":
        return RadialGradient(
          colors: colors,
          stops: stops,
          center: getAlignment(spec["center"]) ?? Alignment.center,
          focal: getAlignment(spec["focal"]),
          focalRadius: parseDouble(spec["focalRadius"]),
          radius: parseDouble(spec["radius"], defaultValue: 0.5),
        );
      default:
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: getAlignment(spec["begin"]) ?? Alignment.centerLeft,
          end: getAlignment(spec["end"]) ?? Alignment.centerRight,
        );
    }
  }

  BorderRadius? getBorderRadius(dynamic value) {
    if (value == null) return null;
    if (value is num) return BorderRadius.all(Radius.circular(parseDouble(value)));

    var parts = value.split("|");
    if (parts.length == 4) {
      return BorderRadius.only(
        topLeft: Radius.circular(parseDouble(parts[0])),
        topRight: Radius.circular(parseDouble(parts[1])),
        bottomLeft: Radius.circular(parseDouble(parts[2])),
        bottomRight: Radius.circular(parseDouble(parts[3])),
      );
    }

    return BorderRadius.all(Radius.circular(parseDouble(parts[0])));
  }

  TextStyle? getTextStyle(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    return TextStyle(
      fontFamily: spec["fontFamily"],
      fontSize: tryParseDouble(spec["fontSize"]),
      fontWeight: getFontWeight(spec["fontWeight"]),
      fontStyle: getFontStyle(spec["fontStyle"]),
      height: tryParseDouble(spec["height"]),
      wordSpacing: tryParseDouble(spec["wordSpacing"]),
      letterSpacing: tryParseDouble(spec["letterSpacing"]),
      overflow: Lowder.properties.build("TextOverflow", spec["overflow"]),
      color: tryParseColor(spec["color"]),
      backgroundColor: tryParseColor(spec["backgroundColor"]),
      decoration: getTextDecoration(spec["decoration"]),
    );
  }

  List<TextInputFormatter>? getTextInputFormatters(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    final list = <TextInputFormatter>[];
    if (spec["allow"] != null) {
      list.add(FilteringTextInputFormatter.allow(RegExp(spec["allow"])));
    }
    if (spec["deny"] != null) {
      list.add(FilteringTextInputFormatter.deny(RegExp(spec["deny"])));
    }
    if (spec["mask"] != null) {
      Map<String, RegExp>? maskFilter;
      String? maskFilterValue = spec["maskFilter"];
      if (maskFilterValue != null) {
        maskFilter = {};
        var filters = maskFilterValue.split("|");
        for (var filter in filters) {
          var parts = filter.split(":");
          if (parts.length > 1) {
            maskFilter[parts[0].trim()] = RegExp(parts[1].trim());
          } else {
            maskFilter["#"] = RegExp(parts[0].trim());
          }
        }
      }
      list.add(MaskTextInputFormatter(mask: spec["mask"], filter: maskFilter));
    }
    return list;
  }

  TextInputAction? getTextInputAction(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "none":
        return TextInputAction.none;
      case "search":
        return TextInputAction.search;
      case "continueAction":
        return TextInputAction.continueAction;
      case "done":
        return TextInputAction.done;
      case "go":
        return TextInputAction.go;
      case "next":
        return TextInputAction.next;
      case "previous":
        return TextInputAction.previous;
      case "emergencyCall":
        return TextInputAction.emergencyCall;
      case "join":
        return TextInputAction.join;
      case "newline":
        return TextInputAction.newline;
      case "route":
        return TextInputAction.route;
      case "send":
        return TextInputAction.send;
      case "unspecified":
        return TextInputAction.unspecified;
      default:
        return null;
    }
  }

  TextDecoration? getTextDecoration(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "overline":
        return TextDecoration.overline;
      case "underline":
        return TextDecoration.underline;
      case "lineThrough":
        return TextDecoration.lineThrough;
      default:
        return null;
    }
  }

  FontWeight? getFontWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "bold":
        return FontWeight.bold;
      case "100":
        return FontWeight.w100;
      case "200":
        return FontWeight.w200;
      case "300":
        return FontWeight.w300;
      case "400":
        return FontWeight.w400;
      case "500":
        return FontWeight.w500;
      case "600":
        return FontWeight.w600;
      case "700":
        return FontWeight.w700;
      case "800":
        return FontWeight.w800;
      case "900":
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  FontStyle? getFontStyle(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "italic":
        return FontStyle.italic;
      default:
        return FontStyle.normal;
    }
  }

  ButtonStyle? getButtonStyle(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    var padding = Lowder.properties.getInsets(spec["padding"]);
    var textStyle = getTextStyle(spec["textStyle"]);
    var backgroundColor = tryParseColor(spec["backgroundColor"]);
    var foregroundColor = tryParseColor(spec["foregroundColor"]);
    var overlayColor = tryParseColor(spec["overlayColor"]);
    var fixedSize = getSize(spec["fixedSize"]);
    var maximumSize = getSize(spec["maximumSize"]);
    var minimumSize = getSize(spec["minimumSize"]);
    BorderSide? borderSide;
    if (spec["side"] != null && spec["side"]["color"] != null && spec["side"]["width"] != null) {
      borderSide = BorderSide(
        color: parseColor(spec["side"]["color"], defaultColor: Colors.black),
        width: parseDouble(spec["side"]["width"], defaultValue: 1.0),
      );
    }

    return ButtonStyle(
      alignment: getAlignment(spec["alignment"]),
      shape: spec["shape"] != null ? MaterialStateProperty.all(getShapeBorder(spec["shape"])) : null,
      padding: padding != null ? MaterialStateProperty.all<EdgeInsets>(padding) : null,
      foregroundColor: foregroundColor != null ? MaterialStateProperty.all<Color>(foregroundColor) : null,
      backgroundColor: backgroundColor != null ? MaterialStateProperty.all<Color>(backgroundColor) : null,
      overlayColor: overlayColor != null ? MaterialStateProperty.all<Color>(overlayColor) : null,
      side: borderSide != null ? MaterialStateProperty.all<BorderSide>(borderSide) : null,
      textStyle: textStyle != null ? MaterialStateProperty.all<TextStyle>(textStyle) : null,
      fixedSize: fixedSize != null ? MaterialStateProperty.all<Size>(fixedSize) : null,
      maximumSize: maximumSize != null ? MaterialStateProperty.all<Size>(maximumSize) : null,
      minimumSize: minimumSize != null ? MaterialStateProperty.all<Size>(minimumSize) : null,
      visualDensity: const VisualDensity(vertical: VisualDensity.minimumDensity, horizontal: VisualDensity.maximumDensity),
    );
  }

  OutlinedBorder? getShapeBorder(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    var borderRadius = getBorderRadius(spec["borderRadius"]) ?? BorderRadius.zero;
    BorderSide borderSide = BorderSide.none;
    if (spec["color"] != null && spec["width"] != null) {
      borderSide = BorderSide(
        color: parseColor(spec["color"], defaultColor: Colors.black),
        width: parseDouble(spec["width"], defaultValue: 1.0),
      );
    }

    switch (spec["type"]) {
      case "roundedRectangle":
        return RoundedRectangleBorder(side: borderSide, borderRadius: borderRadius);
      case "beveledRectangle":
        return BeveledRectangleBorder(side: borderSide, borderRadius: borderRadius);
      case "continuousRectangle":
        return ContinuousRectangleBorder(side: borderSide, borderRadius: borderRadius);
      case "circle":
        return CircleBorder(side: borderSide);
      default:
        return null;
    }
  }

  Size? getSize(Map? spec) {
    if (spec == null || spec.isEmpty) return null;

    if (spec["width"] != null && spec["height"] != null) {
      return Size(parseDouble(spec["width"]), parseDouble(spec["height"]));
    } else if (spec["width"] != null) {
      return Size.fromWidth(parseDouble(spec["width"]));
    } else if (spec["height"] != null) {
      return Size.fromHeight(parseDouble(spec["height"]));
    } else {
      return null;
    }
  }

  Axis? getAxis(String? value) {
    if (value == "vertical") return Axis.vertical;
    if (value == "horizontal") return Axis.horizontal;
    return null;
  }

  IconThemeData? getIconThemeData(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    final shadow = getShadow(spec["shadow"]);
    return IconThemeData(
      color: tryParseColor(spec["color"]),
      opacity: tryParseDouble(spec["opacity"]),
      size: tryParseDouble(spec["size"]),
      shadows: shadow != null ? [shadow] : null,
    );
  }

  NavigationRailLabelType? getNavigationRailLabelType(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value) {
      case "none":
        return NavigationRailLabelType.none;
      case "selected":
        return NavigationRailLabelType.selected;
      case "all":
        return NavigationRailLabelType.all;
      default:
        return null;
    }
  }

  TabBarIndicatorSize? getTabBarIndicatorSize(String? value) {
    if (value == "label") return TabBarIndicatorSize.label;
    if (value == "tab") return TabBarIndicatorSize.tab;
    return null;
  }

  CollapseMode? getCollapseMode(String? value) {
    if (value == null || value.isEmpty) return null;

    switch (value) {
      case "pin":
        return CollapseMode.pin;
      case "parallax":
        return CollapseMode.parallax;
      default:
        return CollapseMode.none;
    }
  }

  StretchMode? getStretchMode(String? value) {
    if (value == null || value.isEmpty) return null;

    switch (value) {
      case "fadeTitle":
        return StretchMode.fadeTitle;
      case "blurBackground":
        return StretchMode.blurBackground;
      default:
        return StretchMode.zoomBackground;
    }
  }

  BoxFit? getBoxFit(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    switch (value) {
      case "none":
        return BoxFit.none;
      case "fill":
        return BoxFit.fill;
      case "contain":
        return BoxFit.contain;
      case "cover":
        return BoxFit.cover;
      case "fitHeight":
        return BoxFit.fitHeight;
      case "fitWidth":
        return BoxFit.fitWidth;
      case "scaleDown":
        return BoxFit.scaleDown;
      default:
        return null;
    }
  }

  ImageProvider? getImageProvider(dynamic value, Map? spec) {
    if (value == null) {
      return null;
    }

    if (spec == null || spec.isEmpty) {
      // try to infer provider type
      if (value is Uint8List) {
        spec = {"_type": "MemoryImage"};
      } else if (value is String) {
        if (value.startsWith("assets/")) {
          spec = {"_type": "AssetImage"};
        } else if (value.startsWith("http")) {
          spec = {"_type": "NetworkImage"};
        } else {
          spec = {"_type": "FileImage"};
        }
      } else {
        return null;
      }
    }

    switch (spec["_type"]) {
      case "AssetImage":
        return AssetImage(value, package: spec["package"]);
      case "NetworkImage":
        return NetworkImage(value, scale: parseDouble(spec["scale"], defaultValue: 1));
      case "MemoryImage":
        return MemoryImage(value, scale: parseDouble(spec["scale"], defaultValue: 1));
      case "FileImage":
        return FileImage(File(value), scale: parseDouble(spec["scale"], defaultValue: 1));
      default:
        return null;
    }
  }

  Widget? getLoadingIndicator(Map? spec) {
    if (spec == null) {
      return null;
    }
    return CircularProgressIndicator(
      color: tryParseColor(spec["color"]),
      backgroundColor: tryParseColor(spec["backgroundColor"]),
      strokeWidth: parseDouble(spec["strokeWidth"], defaultValue: 4.0),
    );
  }

  String formatValue(dynamic value, Map? spec) {
    if (value == null) {
      return "";
    }

    value = value.toString();
    if (spec != null) {
      switch (spec["_type"]) {
        case "KFormatterTranslate":
          final attributes = Map<String, dynamic>.from(spec["attributes"] ?? {});
          if (spec["transform"] == "upper") {
            return Strings.getUpper(value, attributes: attributes);
          } else if (spec["transform"] == "lower") {
            return Strings.getLower(value, attributes: attributes);
          } else if (spec["transform"] == "capitalize") {
            return Strings.getCapitalized(value, attributes: attributes);
          } else if (spec["transform"] == "title") {
            return Strings.getTitle(value, attributes: attributes);
          }
          return Strings.get(value);
        case "KFormatterDateTime":
          final format = spec["format"] ?? Strings.get("_date_time_format_");
          return DateFormat(format).format(parseDateTime(value));
        case "KFormatterDate":
          final format = spec["format"] ?? Strings.get("_date_format_");
          return DateFormat(format).format(parseDateTime(value));
        case "KFormatterTime":
          final format = spec["format"] ?? Strings.get("_time_format_");
          return DateFormat(format).format(parseDateTime(value));
        case "KFormatterNumber":
          final format = spec["format"] ?? Strings.get("_number_format_");
          return NumberFormat(format).format(parseDouble(value));
        case "KFormatterCurrency":
          return NumberFormat.currency(
                  symbol: spec["symbol"] ?? Strings.get("_currency_symbol_"),
                  decimalDigits: parseInt(spec["decimalDigits"], defaultValue: 2))
              .format(parseDouble(value));
      }
    }
    return value;
  }

  Curve? getCurve(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    switch (value) {
      case "linear":
        return Curves.linear;
      case "decelerate":
        return Curves.decelerate;
      case "fastLinearToSlowEaseIn":
        return Curves.fastLinearToSlowEaseIn;
      case "fastEaseInToSlowEaseOut":
        return Curves.fastEaseInToSlowEaseOut;
      case "ease":
        return Curves.ease;
      case "easeIn":
        return Curves.easeIn;
      case "easeInToLinear":
        return Curves.easeInToLinear;
      case "easeInSine":
        return Curves.easeInSine;
      case "easeInQuad":
        return Curves.easeInQuad;
      case "easeInCubic":
        return Curves.easeInCubic;
      case "easeInQuart":
        return Curves.easeInQuart;
      case "easeInQuint":
        return Curves.easeInQuint;
      case "easeInExpo":
        return Curves.easeInExpo;
      case "easeInCirc":
        return Curves.easeInCirc;
      case "easeInBack":
        return Curves.easeInBack;
      case "easeOut":
        return Curves.easeOut;
      case "linearToEaseOut":
        return Curves.linearToEaseOut;
      case "easeOutSine":
        return Curves.easeOutSine;
      case "easeOutQuad":
        return Curves.easeOutQuad;
      case "easeOutCubic":
        return Curves.easeOutCubic;
      case "easeOutQuart":
        return Curves.easeOutQuart;
      case "easeOutQuint":
        return Curves.easeOutQuint;
      case "easeOutExpo":
        return Curves.easeOutExpo;
      case "easeOutCirc":
        return Curves.easeOutCirc;
      case "easeOutBack":
        return Curves.easeOutBack;
      case "easeInOut":
        return Curves.easeInOut;
      case "easeInOutSine":
        return Curves.easeInOutSine;
      case "easeInOutQuad":
        return Curves.easeInOutQuad;
      case "easeInOutCubic":
        return Curves.easeInOutCubic;
      case "easeInOutCubicEmphasized":
        return Curves.easeInOutCubicEmphasized;
      case "easeInOutQuart":
        return Curves.easeInOutQuart;
      case "easeInOutQuint":
        return Curves.easeInOutQuint;
      case "easeInOutExpo":
        return Curves.easeInOutExpo;
      case "easeInOutCirc":
        return Curves.easeInOutCirc;
      case "easeInOutBack":
        return Curves.easeInOutBack;
      case "fastOutSlowIn":
        return Curves.fastOutSlowIn;
      case "slowMiddle":
        return Curves.slowMiddle;
      case "bounceIn":
        return Curves.bounceIn;
      case "bounceOut":
        return Curves.bounceOut;
      case "bounceInOut":
        return Curves.bounceInOut;
      case "elasticIn":
        return Curves.elasticIn;
      case "elasticOut":
        return Curves.elasticOut;
      case "elasticInOut":
        return Curves.elasticInOut;
      default:
        return null;
    }
  }
}
