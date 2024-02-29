import 'dart:async';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../model/editor_node.dart';
import '../model/node_spec.dart';
import '../schema.dart';
import '../util/parser.dart';
import '../util/extensions.dart';
import '../util/strings.dart';
import '../widget/lowder.dart';
import '../widget/bloc_handler.dart';
import '../widget/bloc_list.dart';
import 'action_factory.dart';
import 'properties.dart';
import 'property_factory.dart';
import 'widget_factory.dart';

typedef WidgetBuilderFunc = Widget Function(BuildParameters params);

/// An interface for registering a Solution's Widgets.
mixin IWidgets {
  final Map<String, WidgetBuilderFunc> _widgetBuilders = {};
  final Map<String, EditorWidget> _schema = {};

  Map<String, WidgetBuilderFunc> get builders => _widgetBuilders;
  Map<String, EditorWidget> get schema => _schema;
  WidgetFactory get builder => Lowder.widgets;
  ActionFactory get events => Lowder.actions;
  PropertyFactory get properties => Lowder.properties;

  @nonVirtual
  Map<String, Map<String, dynamic>> getSchema() {
    var schema = <String, Map<String, dynamic>>{};
    for (var key in _schema.keys) {
      schema[key] = _schema[key]!.toJson();
    }
    return schema;
  }

  void registerWidgets();

  @nonVirtual
  void registerWidget(
    String name,
    WidgetBuilderFunc builder, {
    bool abstract = false,
    String? baseType = EditorWidget.widget,
    Map<String, EditorWidgetType>? widgets,
    Map<String, EditorActionType>? actions,
    Map<String, EditorPropertyType>? properties,
    List<String>? tags,
  }) {
    _widgetBuilders[name] = builder;
    _schema[name] = EditorWidget(
      abstract: abstract,
      baseType: baseType,
      widgets: widgets,
      actions: actions,
      properties: properties,
      tags: tags,
    );
  }
}

/// An empty implementation of [IWidgets] to be used when there are no Widgets to declare.
class NoWidgets with IWidgets {
  @override
  void registerWidgets() {
    // No widgets to register
  }
}

/// The Lowder's Widget preset.
class BaseWidgets with IWidgets {
  @override
  void registerWidgets() {
    registerWidget("Screen", (_) => const SizedBox(),
        baseType: null,
        abstract: true,
        properties: {"routeName": Types.string, "state": Types.json},
        widgets: {"body": EditorWidgetType.rootWidget()},
        actions: {"onEnter": EditorActionType.action()});
    registerWidget("RootWidget", (_) => const SizedBox(),
        baseType: null,
        abstract: true,
        properties: {"template": const EditorPropertyType("KTemplate")});
    registerWidget("PreferredSizeWidget", (_) => const SizedBox(),
        baseType: null,
        abstract: true,
        properties: {
          "template": const EditorPropertyType("KTemplate"),
          "heroTag": Types.string,
          "safeArea": Types.bool,
          "buildCondition": Types.kCondition
        });
    registerWidget("Widget", (_) => const SizedBox(),
        baseType: null,
        abstract: true,
        properties: {
          "template": const EditorPropertyType("KTemplate"),
          "decorator": const EditorPropertyType("Decorator"),
          "wrapExpanded": Types.bool,
          "visible": Types.bool,
          "margin": Types.intArray,
          "heroTag": Types.string,
          "safeArea": Types.safeArea,
          "buildCondition": Types.kCondition
        });

    final componentProperties = {
      "component": const EditorPropertyType("KComponent"),
      // "state": Types.json,
    };
    registerWidget("PreferredSizeComponent", buildComponent,
        baseType: EditorWidget.preferredSizeWidget,
        properties: componentProperties);
    registerWidget("WidgetComponent", buildComponent,
        properties: componentProperties);

    registerWidget("material", buildMaterial,
        baseType: EditorWidget.rootWidget,
        properties: {
          "type": Types.materialType,
          "shape": Types.shapeBorder,
          "borderRadius": Types.intArray,
          "elevation": Types.double,
          "color": Types.color,
          "shadowColor": Types.color
        },
        widgets: {
          "child": EditorWidgetType.widget()
        },
        tags: [
          "structure & navigation"
        ]);
    registerWidget("scaffold", buildScaffold,
        baseType: EditorWidget.rootWidget,
        properties: {
          "tabController": Types.tabController,
          "backgroundColor": Types.color,
          "extendBody": Types.bool,
          "extendBodyBehindAppBar": Types.bool,
          "resizeToAvoidBottomInset": Types.bool,
          "floatingActionButtonLocation": Types.floatingActionButtonLocation
        },
        widgets: {
          "appBar": EditorWidgetType.preferredSizeWidget(),
          "drawer": EditorWidgetType.widget(),
          "navigationRail": EditorWidgetType("navigationRail"),
          "body": EditorWidgetType.widget(),
          "bottomSheet": EditorWidgetType.widget(),
          "bottomNavigationBar": EditorWidgetType.widget(),
          "floatingActionButton": EditorWidgetType.widget(),
          "persistentFooterButtons": EditorWidgetType.widget(isArray: true)
        },
        tags: [
          "common",
          "structure & navigation"
        ]);
    registerWidget("sliverScaffold", buildSliverScaffold,
        baseType: EditorWidget.rootWidget,
        properties: {
          "tabController": Types.tabController,
          "backgroundColor": Types.color,
          "shrinkWrap": Types.bool,
          "reverse": Types.bool,
          "scrollDirection": Types.axis,
          "extendBody": Types.bool,
          "extendBodyBehindAppBar": Types.bool,
          "floatingActionButtonLocation": Types.floatingActionButtonLocation,
          "keyboardDismissBehavior": Types.keyboardDismissBehavior
        },
        widgets: {
          "appBar": EditorWidgetType("sliverAppBar"),
          "drawer": EditorWidgetType.widget(),
          "children": EditorWidgetType.widget(isArray: true),
          "bottomSheet": EditorWidgetType.widget(),
          "bottomNavigationBar": EditorWidgetType.widget(),
          "floatingActionButton": EditorWidgetType.widget(),
          "persistentFooterButtons": EditorWidgetType.widget(isArray: true)
        },
        tags: [
          "sliver",
          "structure & navigation"
        ]);

    registerWidget("appBar", buildAppBar,
        baseType: EditorWidget.preferredSizeWidget,
        properties: {
          "title": Types.string,
          "centerTitle": Types.bool,
          "leadingIcon": Types.appBarLeadingIcon,
          "foregroundColor": Types.color,
          "backgroundColor": Types.color,
          "surfaceTintColor": Types.color,
          "systemUiOverlayStyle":
              const EditorPropertyListType(["light", "dark"]),
          "shadowColor": Types.color,
          "elevation": Types.double,
          "scrolledUnderElevation": Types.double,
          "toolbarHeight": Types.int,
          "toolbarOpacity": Types.double,
          "bottomOpacity": Types.double,
          "automaticallyImplyLeading": Types.bool
        },
        widgets: {
          "leading": EditorWidgetType.widget(),
          "titleWidget": EditorWidgetType.widget(),
          "actions": EditorWidgetType.widget(isArray: true),
          "bottom": EditorWidgetType.preferredSizeWidget()
        },
        tags: [
          "common",
          "structure & navigation"
        ]);
    registerWidget("sliverAppBar", buildSliverAppBar,
        baseType: "",
        properties: {
          "title": Types.string,
          "centerTitle": Types.bool,
          "titlePadding": Types.intArray,
          "leadingIcon": Types.appBarLeadingIcon,
          "backgroundColor": Types.color,
          "foregroundColor": Types.color,
          "systemUiOverlayStyle":
              const EditorPropertyListType(["light", "dark"]),
          "elevation": Types.double,
          "scrolledUnderElevation": Types.double,
          "collapsedHeight": Types.int,
          "expandedHeight": Types.int,
          "expandedTitleScale": Types.double,
          "collapseMode": Types.collapseMode,
          "stretchMode": Types.stretchMode,
          "floating": Types.bool,
          "pinned": Types.bool,
          "snap": Types.bool,
          "stretch": Types.bool
        },
        actions: {
          "onStretchTrigger": EditorActionType.action()
        },
        widgets: {
          "leading": EditorWidgetType.widget(),
          "titleWidget": EditorWidgetType.widget(),
          "background": EditorWidgetType.widget(),
          "actions": EditorWidgetType.widget(isArray: true),
          "bottom": EditorWidgetType.preferredSizeWidget()
        },
        tags: [
          "sliver",
          "structure & navigation"
        ]);
    registerWidget("PreferredSize", buildPreferredSize,
        baseType: EditorWidget.preferredSizeWidget,
        properties: {"size": Types.size},
        widgets: {"child": EditorWidgetType.widget()});
    registerWidget("navigationRail", (params) => buildNavigationRail(params),
        properties: {
          "selectedIndex": Types.int,
          "useIndicator": Types.bool,
          "indicatorColor": Types.color,
          "backgroundColor": Types.color,
          "minWidth": Types.double,
          "minExtendedWidth": Types.double,
          "labelType": Types.navigationRailLabelType,
          "selectedLabelTextStyle": Types.textStyle,
          "selectedIconTheme": Types.iconThemeData,
          "unselectedLabelTextStyle": Types.textStyle,
          "unselectedIconTheme": Types.iconThemeData,
          "groupAlignment": Types.double,
          "elevation": Types.double,
          "extended": Types.bool,
        },
        widgets: {
          "destinations":
              EditorWidgetType("NavigationRailDestination", isArray: true),
          "leading": EditorWidgetType.widget(),
          "trailing": EditorWidgetType.widget(),
          "toggle": EditorWidgetType.widget()
        },
        tags: [
          "structure & navigation"
        ]);
    registerWidget("NavigationRailDestination", (_) => const SizedBox(),
        abstract: true,
        baseType: null,
        properties: {
          "label": Types.string,
          "iconCode": Types.int,
          "selectedIconCode": Types.int,
          "padding": Types.intArray,
          "buildCondition": Types.kCondition
        },
        tags: [
          "structure & navigation"
        ]);
    registerWidget("ActionDestination", (_) => const SizedBox(),
        baseType: "NavigationRailDestination",
        actions: {"onTap": EditorActionType.action()});
    registerWidget("ScreenDestination", (_) => const SizedBox(),
        baseType: "NavigationRailDestination",
        properties: {"screen": Types.screen});
    registerWidget("drawer", buildDrawer, properties: {
      "backgroundColor": Types.color,
      "elevation": Types.double,
      "shape": Types.shapeBorder
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "structure & navigation"
    ]);
    registerWidget("drawerHeader", buildDrawerHeader, properties: {
      "padding": Types.intArray,
      "decoration": Types.boxDecoration
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "structure & navigation"
    ]);
    registerWidget("userDrawerHeader", buildUserDrawerHeader, properties: {
      "accountName": Types.string,
      "accountEmail": Types.string,
      "accountPicture": Types.string,
      "accountPictureSize": Types.double,
      "decoration": Types.boxDecoration,
      "arrowColor": Types.color
    }, actions: {
      "onTap": EditorActionType.action()
    }, widgets: {
      "accountNameWidget": EditorWidgetType.widget(),
      "accountEmailWidget": EditorWidgetType.widget(),
      "accountPictureWidget": EditorWidgetType.widget()
    }, tags: [
      "structure & navigation"
    ]);
    registerWidget("bottomAppBar", buildBottomAppBar, properties: {
      "color": Types.color,
      "elevation": Types.int,
      "notchMargin": Types.int,
      "shape": Types.notchedShape
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "structure & navigation"
    ]);
    registerWidget("bottomNavigationBar", buildBottomNavigationBar,
        properties: {
          "startIndex": Types.int,
          "type": const EditorPropertyListType(["fixed", "shifting"]),
          "layout":
              const EditorPropertyListType(["centered", "linear", "spread"]),
          "elevation": Types.int,
          "backgroundColor": Types.color,
          "iconSize": Types.double,
          "selectedFontSize": Types.double,
          "selectedItemColor": Types.color,
          "unselectedFontSize": Types.double,
          "unselectedItemColor": Types.color
        },
        widgets: {
          "children": EditorWidgetType("bottomNavigationBarItem", isArray: true)
        },
        tags: [
          "structure & navigation"
        ]);
    registerWidget("bottomNavigationBarItem", (_) => const SizedBox(),
        baseType: "",
        properties: {
          "iconCode": Types.int,
          "activeIconCode": Types.int,
          "label": Types.string,
          "tooltip": Types.string,
          "backgroundColor": Types.color
        },
        actions: {
          "onTap": EditorActionType.action()
        },
        widgets: {
          "icon": EditorWidgetType.widget(),
          "activeIcon": EditorWidgetType.widget()
        },
        tags: [
          "structure & navigation"
        ]);

    registerWidget("sizedBox", buildSizedBox,
        properties: {"width": Types.int, "height": Types.int},
        tags: ["layout", "decoration", "common"]);
    registerWidget("center", buildCenter,
        properties: {"widthFactor": Types.double, "heightFactor": Types.int},
        widgets: {"child": EditorWidgetType.widget()},
        tags: ["layout"]);
    registerWidget("container", buildContainer, properties: {
      "width": Types.int,
      "height": Types.int,
      "padding": Types.intArray,
      "alignment": Types.alignment,
      "constraints": Types.boxConstraints,
      "decoration": Types.boxDecoration
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "layout",
      "decoration"
    ]);
    registerWidget("AnimatedContainer", buildAnimatedContainer, properties: {
      "width": Types.int,
      "height": Types.int,
      "padding": Types.intArray,
      "alignment": Types.alignment,
      "constraints": Types.boxConstraints,
      "decoration": Types.boxDecoration,
      "duration": Types.int,
      "curve": Types.curve,
    }, actions: {
      "onEnd": EditorActionType.action(),
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "animation",
      "layout",
      "decoration"
    ]);
    registerWidget("card", buildCard, properties: {
      "color": Types.color,
      "surfaceTintColor": Types.color,
      "shadowColor": Types.color,
      "elevation": Types.double,
      "shape": Types.shapeBorder,
      "margin": Types.intArray
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "decoration",
      "common"
    ]);
    registerWidget("stack", buildStack,
        properties: {"alignment": Types.alignment},
        widgets: {"children": EditorWidgetType.widget(isArray: true)},
        tags: ["layout"]);
    registerWidget("Positioned", buildPositioned, properties: {
      "left": Types.double,
      "top": Types.double,
      "right": Types.double,
      "bottom": Types.double,
      "width": Types.double,
      "height": Types.double
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "layout"
    ]);
    registerWidget("AnimatedPositioned", buildAnimatedPositioned, properties: {
      "left": Types.double,
      "top": Types.double,
      "right": Types.double,
      "bottom": Types.double,
      "width": Types.double,
      "height": Types.double,
      "duration": Types.int,
      "curve": Types.curve
    }, actions: {
      "onEnd": EditorActionType.action()
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "animation",
      "layout"
    ]);

    final rowProperties = EditorWidget(properties: {
      "verticalDirection": Types.verticalDirection,
      "crossAxisAlignment": Types.crossAxisAlignment,
      "mainAxisAlignment": Types.mainAxisAlignment,
      "mainAxisSize": Types.mainAxisSize
    }, widgets: {
      "children": EditorWidgetType.widget(isArray: true)
    });
    registerWidget("row", buildRow,
        properties: rowProperties.properties,
        actions: rowProperties.actions,
        widgets: rowProperties.widgets,
        tags: ["common", "layout"]);
    registerWidget("column", buildColumn,
        properties: rowProperties.properties,
        actions: rowProperties.actions,
        widgets: rowProperties.widgets,
        tags: ["common", "layout"]);
    registerWidget("wrap", buildWrap, properties: {
      "direction": Types.axis,
      "alignment": Types.mainAxisAlignment,
      "spacing": Types.double,
      "runAlignment": Types.mainAxisAlignment,
      "runSpacing": Types.double,
      "verticalDirection": Types.verticalDirection,
      "crossAxisAlignment":
          const EditorPropertyListType(["start", "center", "end"])
    }, widgets: {
      "children": EditorWidgetType.widget(isArray: true)
    }, tags: [
      "layout"
    ]);

    registerWidget("SingleChildScrollView", buildSingleChildScrollView,
        properties: {
          "padding": Types.intArray,
          "reverse": Types.bool,
          "scrollDirection": Types.axis,
          "keyboardDismissBehavior": Types.keyboardDismissBehavior
        },
        widgets: {
          "child": EditorWidgetType.widget()
        },
        tags: [
          "common",
          "scrolling"
        ]);
    registerWidget("scrollView", buildScrollView, properties: {
      "padding": Types.intArray,
      "reverse": Types.bool,
      "scrollDirection": Types.axis,
      "keyboardDismissBehavior": Types.keyboardDismissBehavior
    }, widgets: {
      "children": EditorWidgetType.widget(isArray: true)
    }, tags: [
      "scrolling"
    ]);

    final blocListProps = {
      "loadingIndicator": Types.loadingIndicator,
      "noEntriesMessage": Types.string,
      "noEntriesStyle": Types.textStyle
    };
    final blocListActions = {
      "loadPage": EditorActionType.listAction(),
      "onSelect": EditorActionType.action(),
    };
    final blocListWidgets = {
      "child": EditorWidgetType.widget(),
      "noEntriesWidget": EditorWidgetType.widget(),
    };

    final listViewProps = {
      "padding": Types.intArray,
      "shrinkWrap": Types.bool,
      "reverse": Types.bool,
      "scrollDirection": Types.axis,
      "primary": Types.bool,
      "keyboardDismissBehavior": Types.keyboardDismissBehavior
    };
    registerWidget("listView", buildListView,
        properties: {...listViewProps, ...blocListProps},
        actions: blocListActions,
        widgets: {...blocListWidgets, "separator": EditorWidgetType.widget()},
        tags: ["common", "data list"]);
    registerWidget("staticListView", buildStaticListView,
        properties: listViewProps,
        widgets: {"children": EditorWidgetType.widget(isArray: true)},
        tags: ["layout", "scrolling"]);

    final gridViewProps = {
      "crossAxisCount": Types.int,
      "mainAxisSpacing": Types.double,
      "crossAxisSpacing": Types.double,
      "childAspectRatio": Types.double,
      "scrollDirection": Types.axis,
      "reverse": Types.bool,
      "shrinkWrap": Types.bool,
      "padding": Types.intArray,
      "primary": Types.bool,
      "keyboardDismissBehavior": Types.keyboardDismissBehavior
    };
    registerWidget("gridView", buildGridView,
        properties: {
          ...gridViewProps,
          ...blocListProps,
        },
        actions: blocListActions,
        widgets: blocListWidgets,
        tags: ["data list"]);
    registerWidget("staticGridView", buildStaticGridView,
        properties: gridViewProps,
        widgets: {"children": EditorWidgetType.widget(isArray: true)},
        tags: ["layout", "scrolling"]);

    final pageViewProps = {
      "initialPage": Types.int,
      "viewportFraction": Types.double,
      "pageSnapping": Types.bool,
      "padEnds": Types.bool,
      "scrollDirection": Types.axis,
      "reverse": Types.bool,
      "keepPage": Types.bool,
    };
    registerWidget("pageView", buildPageView,
        properties: {...pageViewProps, ...blocListProps},
        actions: {
          ...blocListActions,
          "onPageChanged": EditorActionType.action()
        },
        widgets: blocListWidgets,
        tags: ["data list"]);
    registerWidget("staticPageView", buildStaticPageView,
        properties: pageViewProps,
        widgets: {"children": EditorWidgetType.widget(isArray: true)},
        actions: {"onPageChanged": EditorActionType.action()},
        tags: ["layout", "scrolling"]);

    registerWidget("tableView", buildTable, properties: {
      "border": Types.tableBorder,
      "verticalAlignment": Types.tableVerticalAlignment,
      "rowDecoration": Types.boxDecoration,
      "rowOddDecoration": Types.boxDecoration,
      "shrinkWrap": Types.bool
    }, actions: {
      "loadPage": EditorActionType.listAction(),
      "onSelect": EditorActionType.action()
    }, widgets: {
      "children": EditorWidgetType.widget(isArray: true),
      "noEntriesWidget": EditorWidgetType.widget()
    }, tags: [
      "data list"
    ]);
    registerWidget("dataTableView", buildDataTable, properties: {
      "alias": Types.string,
      "selectionType": const EditorPropertyListType(["single", "multiple"]),
      "sortable": Types.bool,
      "border": Types.tableBorder,
      "decoration": Types.boxDecoration,
      "dividerThickness": Types.double,
      "columnSpacing": Types.double,
      "checkboxHorizontalMargin": Types.double,
      "horizontalMargin": Types.double,
      "showBottomBorder": Types.bool,
      "headingRowColor": Types.color,
      "headingRowHeight": Types.double,
      "headingTextStyle": Types.textStyle,
      "dataRowColor": Types.color,
      "dataRowHeight": Types.double,
      "dataTextStyle": Types.textStyle,
      "rowColor": Types.color,
      "rowOddColor": Types.color,
      "shrinkWrap": Types.bool
    }, actions: {
      "loadPage": EditorActionType.listAction(),
      "onSelect": EditorActionType.action()
    }, widgets: {
      "columns": EditorWidgetType.widget(isArray: true),
      "children": EditorWidgetType.widget(isArray: true),
      "noEntriesWidget": EditorWidgetType.widget()
    }, tags: [
      "data list"
    ]);

    registerWidget("tabView", buildTabView, properties: {
      "padding": Types.intArray,
      "indicator": Types.boxDecoration,
      "indicatorColor": Types.color,
      "indicatorPadding": Types.intArray,
      "indicatorSize": Types.tabBarIndicatorSize,
      "indicatorWeight": Types.double,
      "initialIndex": Types.int,
      "isScrollable": Types.bool,
      "labelColor": Types.color,
      "labelPadding": Types.intArray,
      "labelStyle": Types.textStyle,
      "unselectedLabelColor": Types.color,
      "unselectedLabelStyle": Types.textStyle,
      "dividerHeight": Types.double,
      "dividerColor": Types.color,
      "overlayColor": Types.color,
      "verticalDirection": Types.verticalDirection,
      "crossAxisAlignment": Types.crossAxisAlignment,
      "mainAxisAlignment": Types.mainAxisAlignment,
      "mainAxisSize": Types.mainAxisSize
    }, widgets: {
      "tabs": EditorWidgetType.widget(isArray: true),
      "children": EditorWidgetType.widget(isArray: true)
    }, tags: [
      "structure & navigation"
    ]);
    registerWidget("tabBar", buildTabBar,
        baseType: EditorWidget.preferredSizeWidget,
        properties: {
          "padding": Types.intArray,
          "indicator": Types.boxDecoration,
          "indicatorColor": Types.color,
          "indicatorPadding": Types.intArray,
          "indicatorSize": Types.tabBarIndicatorSize,
          "indicatorWeight": Types.double,
          "isScrollable": Types.bool,
          "labelColor": Types.color,
          "labelPadding": Types.intArray,
          "labelStyle": Types.textStyle,
          "unselectedLabelColor": Types.color,
          "unselectedLabelStyle": Types.textStyle,
          "dividerHeight": Types.double,
          "dividerColor": Types.color,
          "overlayColor": Types.color
        },
        widgets: {
          "tabs": EditorWidgetType.widget(isArray: true)
        },
        tags: [
          "structure & navigation"
        ]);
    registerWidget("tabBarView", buildTabBarView,
        widgets: {"children": EditorWidgetType.widget(isArray: true)},
        tags: ["structure & navigation"]);

    registerWidget("listTile", buildListTile, properties: {
      "iconCode": Types.int,
      "value": Types.string,
      "subValue": Types.string,
      "enabled": Types.bool,
      "listTileStyle": const EditorPropertyListType(["drawer", "list"]),
      "contentPadding": Types.intArray,
      "horizontalTitleGap": Types.double,
      "shape": Types.shapeBorder,
      "iconColor": Types.color,
      "textColor": Types.color,
      "tileColor": Types.color,
      "focusColor": Types.color,
      "hoverColor": Types.color
    }, actions: {
      "onTap": EditorActionType.action()
    }, widgets: {
      "leading": EditorWidgetType.widget(),
      "title": EditorWidgetType.widget(),
      "subtitle": EditorWidgetType.widget(),
      "trailing": EditorWidgetType.widget()
    }, tags: [
      "layout",
      "action"
    ]);
    registerWidget("expanded", buildExpanded,
        properties: {"flex": Types.int},
        widgets: {"child": EditorWidgetType.widget()},
        tags: ["layout"]);
    registerWidget("inkWell", buildInkWell, properties: {
      "borderRadius": Types.intArray,
      "customBorder": Types.shapeBorder,
      "overlayColor": Types.color,
      "highlightColor": Types.color,
      "splashColor": Types.color,
      "hoverColor": Types.color,
      "focusColor": Types.color,
    }, actions: {
      "onTap": EditorActionType.action(),
      "onLongPress": EditorActionType.action(),
      "onDoubleTap": EditorActionType.action(),
      "onTapDown": EditorActionType.action(),
      "onTapUp": EditorActionType.action(),
    }, widgets: {
      "child": EditorWidgetType.widget(),
    }, tags: [
      "action"
    ]);

    registerWidget("richText", buildRichText, properties: {
      "textAlign": Types.textAlign,
      "maxLines": Types.int,
      "softWrap": Types.bool,
      "overflow": Types.textOverflow
    }, widgets: {
      "children": EditorWidgetType("TextSpan", isArray: true)
    }, tags: [
      "text"
    ]);
    registerWidget("TextSpan", (_) => const SizedBox(),
        baseType: "",
        properties: {
          "value": Types.string,
          "style": Types.textStyle
        },
        actions: {
          "onTap": EditorActionType.action(),
        },
        tags: [
          "text"
        ]);
    registerWidget("text", buildText, properties: {
      "alias": Types.string,
      "value": Types.string,
      "format": Types.kFormatter,
      "maxLines": Types.int,
      "semanticsLabel": Types.string,
      "softWrap": Types.bool,
      "overflow": Types.textOverflow,
      "style": Types.textStyle,
      "textAlign": Types.textAlign
    }, tags: [
      "common",
      "text"
    ]);
    final textFormFieldProperties = EditorWidget(properties: {
      "value": Types.string,
      "alias": Types.string,
      "obscureText": Types.bool,
      "enabled": Types.bool,
      "autocorrect": Types.bool,
      "keyboardType": Types.textInputType,
      "textInputAction": Types.textInputAction,
      "minLines": Types.int,
      "maxLines": Types.int,
      "required": Types.bool,
      "minLength": Types.int,
      "maxLength": Types.int,
      "requiredMessage": Types.string,
      "minLengthMessage": Types.string,
      "maxLengthMessage": Types.string,
      "regex": Types.string,
      "regexMessage": Types.string,
      "textAlign": Types.textAlign,
      "textAlignVertical": Types.textAlignVertical,
      "style": Types.textStyle,
      "disabledStyle": Types.textStyle,
      "readOnly": Types.bool,
      "autofocus": Types.bool,
      "enableSuggestions": Types.bool,
      "expands": Types.bool,
      "toolbarOptions": Types.toolbarOptions,
      "textCapitalization": Types.textCapitalization,
      "decoration": Types.inputDecoration,
      "inputFormatters": Types.textInputFormatter,
      "onChangedDebounce": Types.int,
    }, actions: {
      "onChanged": EditorActionType.action(),
      "onFieldSubmitted": EditorActionType.action(),
    }, widgets: {
      "icon": EditorWidgetType.widget(),
      "label": EditorWidgetType.widget(),
      "prefix": EditorWidgetType.widget(),
      "prefixIcon": EditorWidgetType.widget(),
      "suffix": EditorWidgetType.widget(),
      "suffixIcon": EditorWidgetType.widget(),
    });
    //registerWidget("textField", buildTextFormField, textFormFieldProperties);
    registerWidget("textFormField", buildTextFormField,
        properties: textFormFieldProperties.properties,
        widgets: textFormFieldProperties.widgets,
        actions: textFormFieldProperties.actions,
        tags: ["common", "input"]);
    registerWidget("datePicker", buildDatePicker,
        baseType: "textFormField",
        properties: {
          "value": Types.string,
          "firstDate": Types.string,
          "lastDate": Types.string,
          "mode": const EditorPropertyListType(["dateTime", "date", "time"]),
          "label": Types.string,
        },
        tags: [
          "input"
        ]);
    registerWidget("select", buildSelect,
        baseType: "textFormField",
        properties: {
          "valueKey": Types.string,
          "textKey": Types.string,
          "dialogTitle": Types.string,
          "dialogMaxWidth": Types.int,
          "dialogMaxHeight": Types.int,
        },
        actions: {
          "loadValue": EditorActionType.listAction(),
          "loadData": EditorActionType.listAction(),
        },
        widgets: {
          "dialogHeader": EditorWidgetType.widget(),
          "dialogList": EditorWidgetType.widget(),
          "dialogListTile": EditorWidgetType.widget(),
        },
        tags: [
          "input",
          "data list"
        ]);
    final boolInputProperties = EditorWidget(properties: {
      "value": Types.bool,
      "alias": Types.string,
      "enabled": Types.bool,
      "required": Types.bool,
      "requiredMessage": Types.string,
      "contentPadding": Types.intArray,
      "activeColor": Types.color,
      "hoverColor": Types.color,
      "title": Types.string,
      "subtitle": Types.string,
      "shape": Types.shapeBorder,
      "direction": const EditorPropertyListType(["leading", "trailing"])
    }, actions: {
      "onChanged": EditorActionType.action()
    }, widgets: {
      "titleWidget": EditorWidgetType.widget(),
      "subtitleWidget": EditorWidgetType.widget(),
      "secondary": EditorWidgetType.widget(),
    });
    registerWidget("checkbox", buildCheckbox,
        properties: {
          "checkColor": Types.color,
          "triState": Types.bool,
        }..addAll(boolInputProperties.properties!),
        actions: boolInputProperties.actions,
        widgets: boolInputProperties.widgets,
        tags: ["input"]);
    registerWidget("switch", buildSwitch,
        properties: {
          "activeTrackColor": Types.color,
          "inactiveThumbColor": Types.color,
          "inactiveTrackColor": Types.color,
        }..addAll(boolInputProperties.properties!),
        actions: boolInputProperties.actions,
        widgets: boolInputProperties.widgets,
        tags: ["input"]);

    registerWidget("slider", buildSlider, properties: {
      "alias": Types.string,
      "value": Types.double,
      "min": Types.double,
      "max": Types.double,
      "divisions": Types.int,
      "thumbColor": Types.color,
      "activeColor": Types.color,
      "inactiveColor": Types.color,
      "secondaryTrackValue": Types.double,
      "secondaryActiveColor": Types.color,
      "label": Types.string,
      "enabled": Types.bool
    }, actions: {
      "onChanged": EditorActionType.action()
    }, tags: [
      "input"
    ]);

    final buttonProperties = EditorWidget(properties: {
      "text": Types.string,
      "style": Types.buttonStyle,
    }, actions: {
      "onPressed": EditorActionType.action()
    }, widgets: {
      "child": EditorWidgetType.widget()
    });
    registerWidget("textButton", buildTextButton,
        properties: buttonProperties.properties,
        actions: buttonProperties.actions,
        widgets: buttonProperties.widgets,
        tags: ["button", "action"]);
    registerWidget("elevatedButton", buildElevatedButton,
        properties: buttonProperties.properties,
        actions: buttonProperties.actions,
        widgets: buttonProperties.widgets,
        tags: ["common", "button", "action"]);
    registerWidget("outlinedButton", buildOutlinedButton,
        properties: buttonProperties.properties,
        actions: buttonProperties.actions,
        widgets: buttonProperties.widgets,
        tags: ["button", "action"]);
    registerWidget("iconButton", buildIconButton, properties: {
      "iconCode": Types.int,
      "iconSize": Types.double,
      "tooltip": Types.string,
      "color": Types.color,
      "focusColor": Types.color,
      "hoverColor": Types.color,
      "splashColor": Types.color,
      "highlightColor": Types.color,
      "disabledColor": Types.color,
      "padding": Types.intArray,
      "alignment": Types.alignment,
      "style": Types.buttonStyle,
      "constraints": Types.boxConstraints,
    }, actions: {
      "onPressed": EditorActionType.action()
    }, widgets: {
      "icon": EditorWidgetType.widget()
    }, tags: [
      "button",
      "action"
    ]);
    registerWidget("floatingActionButton", buildFloatingActionButton,
        properties: {
          "iconCode": Types.int,
          "tooltip": Types.string,
          "mini": Types.bool,
          "shape": Types.shapeBorder,
          "backgroundColor": Types.color,
          "foregroundColor": Types.color,
          "hoverColor": Types.color,
          "splashColor": Types.color,
          "focusColor": Types.color,
          "elevation": Types.double,
          "focusElevation": Types.double,
          "highlightElevation": Types.double,
          "hoverElevation": Types.double,
          "disabledElevation": Types.double,
        },
        actions: {
          "onPressed": EditorActionType.action()
        },
        widgets: {
          "child": EditorWidgetType.widget()
        },
        tags: [
          "button",
          "action"
        ]);

    registerWidget("dropdownButton", buildDropdownButton, properties: {
      "value": Types.string,
      "values": Types.json,
      "nameKey": Types.string,
      "valueKey": Types.string,
      "alias": Types.string,
      "required": Types.bool,
      "enabled": Types.bool,
      "style": Types.textStyle,
      "disabledStyle": Types.textStyle,
      "focusColor": Types.color,
      "dropdownColor": Types.color,
      "iconEnabledColor": Types.color,
      "iconDisabledColor": Types.color,
      "elevation": Types.int,
      "itemHeight": Types.double,
      "alignment": Types.alignment,
      "decoration": Types.inputDecoration,
      "iconSize": Types.double,
      "menuMaxHeight": Types.double
    }, actions: {
      "onChanged": EditorActionType.action()
    }, widgets: {
      "hint": EditorWidgetType.widget(),
      "icon": EditorWidgetType.widget(),
      "label": EditorWidgetType.widget(),
      "prefix": EditorWidgetType.widget(),
      "suffix": EditorWidgetType.widget()
    }, tags: [
      "button"
    ]);
    registerWidget("popupMenuButton", buildPopupMenuButton, properties: {
      "values": Types.json,
      "nameKey": Types.string,
      "valueKey": Types.string,
      "alias": Types.string,
      "color": Types.color,
      "tooltip": Types.string,
      "shape": Types.shapeBorder,
      "padding": Types.intArray,
      "enabled": Types.bool,
      "offset": Types.doubleArray,
      "elevation": Types.double,
      "iconSize": Types.double
    }, actions: {
      "onSelected": EditorActionType.action()
    }, widgets: {
      "icon": EditorWidgetType.widget(),
      "child": EditorWidgetType.widget()
    }, tags: [
      "button"
    ]);

    registerWidget("Hero", buildHero,
        properties: {"tag": Types.string},
        widgets: {"child": EditorWidgetType.widget()},
        tags: ["animation"]);
    registerWidget("icon", buildIcon, properties: {
      "iconCode": Types.int,
      "color": Types.color,
      "size": Types.double,
      "semanticLabel": Types.string
    }, tags: [
      "asset",
      "common",
      "decoration"
    ]);
    registerWidget("image", buildImage, properties: {
      "value": Types.string,
      "alias": Types.string,
      "color": Types.color,
      "width": Types.double,
      "height": Types.double,
      "alignment": Types.alignment,
      "fit": Types.boxFit,
      "provider": Types.imageProvider,
    }, widgets: {
      "fallback": EditorWidgetType.widget()
    }, tags: [
      "asset",
      "common",
      "decoration"
    ]);
    registerWidget("circleAvatar", buildCircleAvatar, properties: {
      "foregroundValue": Types.string,
      "foregroundProvider": Types.imageProvider,
      "backgroundValue": Types.string,
      "backgroundProvider": Types.imageProvider,
      "foregroundColor": Types.color,
      "backgroundColor": Types.color,
      "radius": Types.double
    }, widgets: {
      "child": EditorWidgetType.widget()
    }, tags: [
      "asset"
    ]);

    registerWidget("CircularProgressIndicator", buildCircularProgressIndicator,
        properties: {
          "color": Types.color,
          "strokeWidth": Types.double,
          "strokeAlign": Types.double
        },
        actions: {
          "doWork": EditorActionType.action()
        });

    registerWidget("Badge", buildBadge, properties: {
      "label": Types.string,
      "alignment": Types.alignment,
      "padding": Types.intArray,
      "textStyle": Types.textStyle,
      "textColor": Types.color,
      "backgroundColor": Types.color,
      "isLabelVisible": Types.kCondition,
    }, widgets: {
      "label": EditorWidgetType.widget(),
      "child": EditorWidgetType.widget()
    });

    registerWidget("BlocBuilder", buildBlocBuilder, properties: {
      "type": const EditorPropertyListType(["local", "global"]),
    }, widgets: {
      "child": EditorWidgetType.widget(),
      "states": EditorWidgetType("BuildState", isArray: true),
    });
    registerWidget("BuildState", (_) => const SizedBox(),
        baseType: null,
        properties: {"state": Types.string},
        widgets: {"child": EditorWidgetType.widget()});

    registerWidget("BlocConsumer", buildBlocBuilder, properties: {
      "type": const EditorPropertyListType(["local", "global"]),
    }, widgets: {
      "child": EditorWidgetType.widget(),
      "states": EditorWidgetType("BlocBuilderState", isArray: true),
    });
    registerWidget("BlocBuilderState", (_) => const SizedBox(),
        abstract: true,
        baseType: null,
        properties: {"state": Types.string},
        actions: {"listener": EditorActionType.action()});
    registerWidget("StateBuilder", (_) => const SizedBox(),
        baseType: "BlocBuilderState",
        widgets: {"child": EditorWidgetType.widget()});
    registerWidget("StateListener", (_) => const SizedBox(),
        baseType: "BlocBuilderState");
  }

  @protected
  Widget buildComponent(BuildParameters params) {
    final spec = params.spec;
    WidgetNodeSpec? componentSpec;
    if (spec.props["component"] != null) {
      componentSpec = Schema.getComponent(spec.props["component"]);
    }
    if (componentSpec == null) {
      return Container();
    }

    /// Using the same component multiple times in the same Screen may have issues related to Widget's Ids
    /// Maybe when building Component's widget tree, ids should be generated so they can be unique

    // format: <widgetId>.<property type>.<property key>
    final exposedProps = Map<String, dynamic>.from(
        componentSpec.extra["exposedProperties"] ?? {});
    for (String key in exposedProps.keys) {
      if (exposedProps[key] == null || exposedProps[key].isEmpty) {
        continue;
      }

      dynamic value;
      var keyParts = (exposedProps[key] as String).split(".");
      var propertyType = keyParts.removeAt(1);
      var stateKey = keyParts.join(".");
      params.state.remove(
          stateKey); // To avoid inheriting this property from previous component build

      switch (propertyType) {
        case "action":
          if (!spec.actions.containsKey(key)) {
            continue;
          }
          value = spec.actions[key];
          break;
        case "property":
          if (!spec.props.containsKey(key)) {
            continue;
          }
          value = spec.props[key];
          break;
        case "widget":
          if (!spec.widgets.containsKey(key)) {
            continue;
          }
          value = spec.widgets[key];
          break;
        default:
          continue;
      }

      params.state[stateKey] = value;
    }

    // final componentState = Map<String, dynamic>.from(spec.props["state"] ?? {});
    // params.state.addAll(componentState);
    // for (String key in spec.props.keys) {
    //   if (key.split(".").length == 2) {
    //     params.state[key] = spec.props[key];
    //   }
    // }
    // for (String key in spec.widgets.keys) {
    //   if (key.split(".").length == 2) {
    //     params.state[key] = spec.widgets[key];
    //   }
    // }
    // for (String key in spec.actions.keys) {
    //   if (key.split(".").length == 2) {
    //     params.state[key] = spec.actions[key];
    //   }
    // }

    return builder.buildWidgetFromSpec(
        params.context, componentSpec, params.state, params.parentContext);
  }

  @protected
  Widget buildScaffold(BuildParameters params) {
    final props = params.spec.props;
    final widgets = params.spec.widgets;

    List<Widget>? persistentFooterButtons;
    if (widgets["persistentFooterButtons"] != null) {
      persistentFooterButtons = <Widget>[];
      for (Map childSpec in widgets["persistentFooterButtons"] as List<Map>) {
        persistentFooterButtons.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    var appBar = builder.tryBuildWidget(
        params.context, widgets["appBar"], params.state, params.parentContext);
    if (appBar is! PreferredSizeWidget) {
      appBar = null;
    }
    final bottomSheet = builder.tryBuildWidget(params.context,
        widgets["bottomSheet"], params.state, params.parentContext);
    final bottomNavigationBar = builder.tryBuildWidget(params.context,
        widgets["bottomNavigationBar"], params.state, params.parentContext);
    final floatingActionButton = builder.tryBuildWidget(params.context,
        widgets["floatingActionButton"], params.state, params.parentContext);
    var body = builder.tryBuildWidget(
        params.context, widgets["body"], params.state, params.parentContext);
    final drawer = builder.tryBuildWidget(
        params.context, widgets["drawer"], params.state, params.parentContext);

    if (widgets["navigationRail"] != null) {
      final navigationRail = builder.buildWidget(params.context,
          widgets["navigationRail"], params.state, params.parentContext);
      body = Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          navigationRail,
          if (body != null) Expanded(child: body),
        ],
      );
    }

    Widget widget = Scaffold(
      key: properties.getKey(params.id),
      backgroundColor: tryParseColor(props["backgroundColor"]),
      body: body,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      extendBody: parseBool(props["extendBody"]),
      extendBodyBehindAppBar: parseBool(props["extendBodyBehindAppBar"]),
      resizeToAvoidBottomInset: tryParseBool(props["resizeToAvoidBottomInset"]),
      appBar: appBar != null ? appBar as PreferredSizeWidget : null,
      floatingActionButtonLocation:
          params.buildProp("floatingActionButtonLocation"),
    );

    if (props["tabController"] != null) {
      widget = DefaultTabController(
        length: parseInt(props["tabController"]["length"]),
        initialIndex: parseInt(props["tabController"]["initialIndex"]),
        child: widget,
      );
    }

    return widget;
  }

  @protected
  Widget buildMaterial(BuildParameters params) {
    return Material(
      key: properties.getKey(params.id),
      type: params.buildProp("type") ?? MaterialType.canvas,
      shape: params.buildProp("shape"),
      borderRadius: params.buildProp("borderRadius"),
      elevation: parseDouble(params.props["elevation"]),
      color: tryParseColor(params.props["color"]),
      shadowColor: tryParseColor(params.props["shadowColor"]),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildSliverScaffold(BuildParameters params) {
    final props = params.spec.props;
    final widgets = params.spec.widgets;

    List<Widget>? persistentFooterButtons;
    if (widgets["persistentFooterButtons"] != null) {
      persistentFooterButtons = <Widget>[];
      for (Map childSpec in widgets["persistentFooterButtons"] as List<Map>) {
        persistentFooterButtons.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    final appBar = builder.tryBuildWidget(
        params.context, widgets["appBar"], params.state, params.parentContext);
    final bottomSheet = builder.tryBuildWidget(params.context,
        widgets["bottomSheet"], params.state, params.parentContext);
    final bottomNavigationBar = builder.tryBuildWidget(params.context,
        widgets["bottomNavigationBar"], params.state, params.parentContext);
    final floatingActionButton = builder.tryBuildWidget(params.context,
        widgets["floatingActionButton"], params.state, params.parentContext);
    final drawer = builder.tryBuildWidget(
        params.context, widgets["drawer"], params.state, params.parentContext);

    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    final scrollView = CustomScrollView(
      key: properties.getKey(params.id),
      reverse: parseBool(params.props["reverse"]),
      shrinkWrap: parseBool(params.props["shrinkWrap"]),
      scrollDirection: params.buildProp("scrollDirection") ?? Axis.vertical,
      keyboardDismissBehavior: params.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      slivers: [
        if (appBar != null) appBar,
        SliverList(delegate: SliverChildListDelegate(children)),
      ],
    );

    Widget widget = Scaffold(
      key: properties.getKey(params.id),
      backgroundColor: tryParseColor(props["backgroundColor"]),
      body: scrollView,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      extendBody: parseBool(props["extendBody"]),
      extendBodyBehindAppBar: parseBool(props["extendBodyBehindAppBar"]),
      floatingActionButtonLocation:
          params.buildProp("floatingActionButtonLocation"),
    );

    if (props["tabController"] != null) {
      widget = DefaultTabController(
        length: parseInt(props["tabController"]["length"]),
        initialIndex: parseInt(props["tabController"]["initialIndex"]),
        child: widget,
      );
    }

    return widget;
  }

  @protected
  Widget buildAppBar(BuildParameters params) {
    var leading = builder.tryBuildWidget(params.context,
        params.widgets["leading"], params.state, params.parentContext);
    leading ??= params.buildProp("leadingIcon");

    var title = builder.tryBuildWidget(params.context,
        params.widgets["titleWidget"], params.state, params.parentContext);
    if (title == null && params.props["title"] != null) {
      title = Text(properties.getText(params.props["title"], "appBar"));
    }

    var bottom = builder.tryBuildWidget(params.context,
        params.widgets["bottom"], params.state, params.parentContext);
    if (bottom is! PreferredSizeWidget) {
      bottom = null;
    }

    final actions = <Widget>[];
    if (params.widgets["actions"] != null) {
      for (Map actionSpec in params.widgets["actions"] as List<Map>) {
        actions.add(builder.buildWidget(
            params.context, actionSpec, params.state, params.parentContext));
      }
    }

    final backgroundColor = tryParseColor(params.props["backgroundColor"]);
    final systemUiOverlayStyleProp = params.props["systemUiOverlayStyle"];
    final systemUiOverlayStyle = systemUiOverlayStyleProp == null
        ? null
        : systemUiOverlayStyleProp == "dark"
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light;

    return AppBar(
      key: properties.getKey(params.id),
      foregroundColor: tryParseColor(params.props["foregroundColor"]),
      backgroundColor: backgroundColor,
      surfaceTintColor:
          tryParseColor(params.props["surfaceTintColor"]) ?? backgroundColor,
      shadowColor: tryParseColor(params.props["shadowColor"]),
      systemOverlayStyle: systemUiOverlayStyle,
      leading: leading,
      title: title,
      automaticallyImplyLeading: parseBool(
          params.props["automaticallyImplyLeading"],
          defaultValue: true),
      centerTitle: tryParseBool(params.props["centerTitle"]),
      elevation: tryParseDouble(params.props["elevation"]),
      scrolledUnderElevation:
          tryParseDouble(params.props["scrolledUnderElevation"]),
      bottom: bottom != null ? bottom as PreferredSizeWidget : null,
      bottomOpacity:
          parseDouble(params.props["bottomOpacity"], defaultValue: 1),
      toolbarHeight: tryParseDouble(params.props["toolbarHeight"]),
      toolbarOpacity:
          parseDouble(params.props["toolbarOpacity"], defaultValue: 1),
      actions: actions,
    );
  }

  @protected
  Widget buildSliverAppBar(BuildParameters params) {
    var leading = builder.tryBuildWidget(params.context,
        params.widgets["leading"], params.state, params.parentContext);
    leading ??= params.buildProp("leadingIcon");

    var title = builder.tryBuildWidget(params.context,
        params.widgets["titleWidget"], params.state, params.parentContext);
    if (title == null && params.props["title"] != null) {
      title = Text(properties.getText(params.props["title"], "appBar"));
    }

    var bottom = builder.tryBuildWidget(params.context,
        params.widgets["bottom"], params.state, params.parentContext);
    if (bottom is! PreferredSizeWidget) {
      bottom = null;
    }

    final actions = <Widget>[];
    if (params.widgets["actions"] != null) {
      for (Map actionSpec in params.widgets["actions"] as List<Map>) {
        actions.add(builder.buildWidget(
            params.context, actionSpec, params.state, params.parentContext));
      }
    }

    final flexible = FlexibleSpaceBar(
      title: title,
      centerTitle: tryParseBool(params.props["centerTitle"]),
      titlePadding: properties.getInsets(params.props["titlePadding"]),
      expandedTitleScale:
          parseDouble(params.props["expandedTitleScale"], defaultValue: 1.5),
      collapseMode: params.buildProp("collapseMode") ?? CollapseMode.parallax,
      stretchModes: [
        params.buildProp("stretchMode") ?? StretchMode.zoomBackground
      ],
      background: builder.tryBuildWidget(params.context,
          params.widgets["background"], params.state, params.parentContext),
    );

    final systemUiOverlayStyleProp = params.props["systemUiOverlayStyle"];
    final systemUiOverlayStyle = systemUiOverlayStyleProp == null
        ? null
        : systemUiOverlayStyleProp == "dark"
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light;

    return SliverAppBar(
      key: properties.getKey(params.id),
      backgroundColor: tryParseColor(params.props["backgroundColor"]),
      foregroundColor: tryParseColor(params.props["foregroundColor"]),
      systemOverlayStyle: systemUiOverlayStyle,
      //title: title,
      //centerTitle: tryParseBool(params.props["centerTitle"]),
      elevation: tryParseDouble(params.props["elevation"]),
      scrolledUnderElevation:
          tryParseDouble(params.props["scrolledUnderElevation"]),
      leading: leading,
      bottom: bottom != null ? bottom as PreferredSizeWidget : null,
      //toolbarHeight: tryParseDouble(params.props["toolbarHeight"]),
      actions: actions,
      expandedHeight: tryParseDouble(params.props["expandedHeight"]),
      collapsedHeight: tryParseDouble(params.props["collapsedHeight"]),
      //onStretchTrigger: params.actions["onStretchTrigger"] != null ? widgetEvents.getFunction(params.context, params.actions["onStretchTrigger"], params.state) : null,
      floating: parseBool(params.props["floating"]),
      pinned: parseBool(params.props["pinned"]),
      snap: parseBool(params.props["snap"]) &&
          parseBool(params.props["floating"]),
      stretch: parseBool(params.props["stretch"]),
      flexibleSpace: flexible,
    );
  }

  @protected
  Widget buildPreferredSize(BuildParameters params) {
    return PreferredSize(
      key: properties.getKey(params.id),
      preferredSize: params.buildProp("size") ?? Size.zero,
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
              params.state, params.parentContext) ??
          const SizedBox(),
    );
  }

  @protected
  Widget buildNavigationRail(BuildParameters params) {
    final props = params.props;
    final destinations = <NavigationRailDestination>[];
    final destinationActions = <Function?>[];
    final destinationsSpec = params.widgets["destinations"];
    if (destinationsSpec != null) {
      for (var spec in destinationsSpec) {
        var specProps = spec["properties"] ?? {};
        if (!EditorBloc.editMode &&
            specProps["buildCondition"] != null &&
            !properties.evaluateCondition(specProps["buildCondition"])) {
          continue;
        }

        var type = spec["_type"];
        var iconCode = parseInt(specProps["iconCode"]);
        var selectedIconCode = parseInt(specProps["selectedIconCode"]);
        String label = specProps["label"] ?? "";

        if (type == "ScreenDestination") {
          var screen = Schema.getScreen(specProps["screen"]);
          if (screen == null) {
            continue;
          }
          if (label.isEmpty) {
            label = screen.name ?? label;
          }
          if (iconCode == 0) {
            iconCode = parseInt(screen.props["iconCode"]);
          }
          if (selectedIconCode == 0) {
            selectedIconCode = parseInt(screen.props["selectedIconCode"]);
          }

          destinationActions.add(() {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              final navigator = Navigator.of(params.context);
              navigator.popUntil((route) => route.isFirst);
              if (!Lowder.editorMode) {
                navigator.pushReplacement(builder.buildRoute(screen));
              } else {
                navigator.push(builder.buildRoute(screen));
              }
            });
          });
        } else {
          var specActions = spec["actions"] ?? {};
          destinationActions.add(events.getFunction(params.context,
              specActions["onTap"], params.state, params.parentContext));
        }

        destinations.add(NavigationRailDestination(
          icon: Icon(IconData(iconCode, fontFamily: "MaterialIcons")),
          selectedIcon:
              Icon(IconData(selectedIconCode, fontFamily: "MaterialIcons")),
          label: Text(properties.getText(label, "menu")),
          padding: properties.getInsets(specProps["padding"]),
        ));
      }
    }

    final minWidth = parseDouble(props["minWidth"], defaultValue: 72);
    final minExtendedWidth =
        parseDouble(props["minExtendedWidth"], defaultValue: 256);
    final groupAlignment =
        parseDouble(props["groupAlignment"], defaultValue: -1);

    return StatefulBuilder(builder: (context, setState) {
      final selectedIndex = parseInt(
          Lowder.globalVariables["${params.id}.selectedIndex"],
          defaultValue: parseInt(params.props["selectedIndex"]));
      var extended = parseBool(Lowder.globalVariables["${params.id}.extended"],
          defaultValue: parseBool(props["extended"]));

      var leadingWidget = builder.tryBuildWidget(params.context,
          params.widgets["leading"], params.state, params.parentContext);
      if (leadingWidget != null && groupAlignment != -1) {
        leadingWidget = Expanded(child: leadingWidget);
      }

      final trailing = builder.tryBuildWidget(params.context,
          params.widgets["trailing"], params.state, params.parentContext);
      var trailingWidget = trailing;
      if (params.widgets["toggle"] != null) {
        trailingWidget = Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (trailing != null) trailing,
            InkWell(
              onTap: () => setState(() {
                extended = !extended;
                Lowder.globalVariables["${params.id}.extended"] = extended;
              }),
              child: builder.buildWidget(
                  params.context,
                  params.widgets["toggle"],
                  params.state.clone()..addAll({"extended": extended}),
                  params.parentContext),
            ),
          ],
        );
        if (groupAlignment != 1) {
          trailingWidget = Expanded(child: trailingWidget);
        }
      }

      return SizedBox(
          width: extended ? minExtendedWidth : minWidth,
          child: NavigationRail(
            key: properties.getKey(params.id),
            selectedIndex: selectedIndex,
            destinations: destinations,
            elevation: tryParseDouble(props["elevation"]),
            extended: extended,
            useIndicator: tryParseBool(props["useIndicator"]),
            indicatorColor: tryParseColor(props["indicatorColor"]),
            backgroundColor: tryParseColor(props["backgroundColor"]),
            minWidth: minWidth,
            minExtendedWidth: minExtendedWidth,
            labelType: params.buildProp("labelType"),
            selectedLabelTextStyle: params.buildProp("selectedLabelTextStyle"),
            selectedIconTheme: params.buildProp("selectedIconTheme"),
            unselectedLabelTextStyle:
                params.buildProp("unselectedLabelTextStyle"),
            unselectedIconTheme: params.buildProp("unselectedIconTheme"),
            groupAlignment: groupAlignment,
            leading: leadingWidget,
            trailing: trailingWidget,
            onDestinationSelected: (idx) {
              Lowder.globalVariables["${params.id}.selectedIndex"] = idx;
              final action = destinationActions[idx];
              if (action != null) {
                action();
              }
            },
          ));
    });
  }

  @protected
  Widget buildDrawer(BuildParameters params) {
    return Drawer(
      key: properties.getKey(params.id),
      elevation: tryParseDouble(params.props["elevation"]),
      backgroundColor: tryParseColor(params.props["backgroundColor"]),
      shape: params.buildProp("shape"),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildDrawerHeader(BuildParameters params) {
    return DrawerHeader(
      key: properties.getKey(params.id),
      padding: properties.getInsets(params.props["padding"]) ??
          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      decoration: params.buildProp("decoration"),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildUserDrawerHeader(BuildParameters params) {
    Widget? accountName = builder.tryBuildWidget(
        params.context,
        params.widgets["accountNameWidget"],
        params.state,
        params.parentContext);
    accountName ??= params.props["accountName"] != null
        ? Text(params.props["accountName"])
        : null;
    Widget? accountEmail = builder.tryBuildWidget(
        params.context,
        params.widgets["accountEmailWidget"],
        params.state,
        params.parentContext);
    accountEmail ??= params.props["accountEmail"] != null
        ? Text(params.props["accountEmail"])
        : null;
    Widget? currentAccountPicture = builder.tryBuildWidget(
        params.context,
        params.widgets["accountPictureWidget"],
        params.state,
        params.parentContext);

    final accountPicture = params.props["accountPicture"];
    if (currentAccountPicture == null && accountPicture != null) {
      var uri = Uri.tryParse(accountPicture);
      if (uri != null) {
        currentAccountPicture =
            CircleAvatar(backgroundImage: NetworkImage(accountPicture));
      } else {
        currentAccountPicture = CircleAvatar(child: Text(accountPicture));
      }
    }

    return UserAccountsDrawerHeader(
      key: properties.getKey(params.id),
      accountName: accountName,
      accountEmail: accountEmail,
      currentAccountPicture: currentAccountPicture,
      currentAccountPictureSize: Size.square(
          parseDouble(params.props["accountPictureSize"], defaultValue: 72.0)),
      decoration: params.buildProp("decoration"),
      arrowColor:
          parseColor(params.props["arrowColor"], defaultColor: Colors.white),
      onDetailsPressed: events.getFunction(params.context,
          params.actions["onTap"], params.state, params.parentContext),
    );
  }

  @protected
  Widget buildBottomAppBar(BuildParameters params) {
    return BottomAppBar(
      key: properties.getKey(params.id),
      color: tryParseColor(params.props["color"]),
      elevation: tryParseDouble(params.props["elevation"]),
      notchMargin: parseDouble(params.props["notchMargin"], defaultValue: 4.0),
      shape: params.buildProp("shape"),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildBottomNavigationBar(BuildParameters params) {
    var currentIdx = parseInt(params.props["startIndex"]);
    final type = params.props["type"] == "shifting"
        ? BottomNavigationBarType.shifting
        : BottomNavigationBarType.fixed;

    var landscapeLayout = BottomNavigationBarLandscapeLayout.centered;
    if (params.props["layout"] != null) {
      switch (params.props["layout"]) {
        case "linear":
          landscapeLayout = BottomNavigationBarLandscapeLayout.linear;
          break;
        case "spread":
          landscapeLayout = BottomNavigationBarLandscapeLayout.spread;
          break;
        default:
          landscapeLayout = BottomNavigationBarLandscapeLayout.centered;
          break;
      }
    }

    final children = <WidgetNodeSpec>[];
    if (params.widgets["children"] != null) {
      for (var childSpec in params.widgets["children"]) {
        children.add(WidgetNodeSpec.fromMap(childSpec));
      }
    }

    final items = <BottomNavigationBarItem>[];
    for (var child in children) {
      final icon = child.widgets["icon"] != null
          ? builder.buildWidget(params.context, child.widgets["icon"],
              params.state, params.parentContext)
          : Icon(IconData(parseInt(child.props["iconCode"]),
              fontFamily: "MaterialIcons"));
      final activeIcon = child.widgets["activeIcon"] != null
          ? builder.buildWidget(params.context, child.widgets["activeIcon"],
              params.state, params.parentContext)
          : child.props["activeIconCode"] != null
              ? Icon(IconData(parseInt(child.props["activeIconCode"]),
                  fontFamily: "MaterialIcons"))
              : null;

      items.add(BottomNavigationBarItem(
        icon: icon,
        activeIcon: activeIcon,
        label: properties.getText(child.props["label"], "label"),
        tooltip: child.props["tooltip"] != null
            ? properties.getText(child.props["tooltip"], "label")
            : null,
        backgroundColor: tryParseColor(child.props["backgroundColor"]),
      ));
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return BottomNavigationBar(
          key: properties.getKey(params.id),
          items: items,
          backgroundColor: tryParseColor(params.props["backgroundColor"]),
          elevation: tryParseDouble(params.props["elevation"]),
          type: type,
          landscapeLayout: landscapeLayout,
          currentIndex: currentIdx,
          iconSize: parseDouble(params.props["iconSize"], defaultValue: 24.0),
          selectedFontSize:
              parseDouble(params.props["selectedFontSize"], defaultValue: 13.0),
          selectedItemColor: tryParseColor(params.props["selectedItemColor"]),
          unselectedFontSize: parseDouble(params.props["unselectedFontSize"],
              defaultValue: 12.0),
          unselectedItemColor:
              tryParseColor(params.props["unselectedItemColor"]),
          onTap: (idx) {
            setState(() => currentIdx = idx);
            final spec = children[idx];
            if (spec.actions["onTap"] != null) {
              events.run(
                  params.context,
                  NodeSpec.fromMap(spec.actions["onTap"]),
                  params.state,
                  null,
                  params.parentContext);
            }
          },
        );
      },
    );
  }

  @protected
  Widget buildCenter(BuildParameters params) {
    return Center(
      key: properties.getKey(params.id),
      widthFactor: tryParseDouble(params.props["widthFactor"]),
      heightFactor: tryParseDouble(params.props["heightFactor"]),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildContainer(BuildParameters params) {
    final child = builder.tryBuildWidget(params.context,
        params.widgets["child"], params.state, params.parentContext);
    final decoration = params.buildProp("decoration");

    return Container(
      key: properties.getKey(params.id),
      width: tryParseDouble(params.props["width"]),
      height: tryParseDouble(params.props["height"]),
      padding: properties.getInsets(params.props["padding"]),
      alignment: params.buildProp("alignment"),
      constraints: params.buildProp("constraints"),
      decoration: decoration,
      clipBehavior: decoration != null ? Clip.antiAlias : Clip.none,
      child: child,
    );
  }

  @protected
  Widget buildAnimatedContainer(BuildParameters params) {
    final onEnd = events.getFunction(params.context, params.actions["onEnd"],
        params.state, params.parentContext);
    final child = builder.tryBuildWidget(params.context,
        params.widgets["child"], params.state, params.parentContext);
    final decoration = params.buildProp("decoration");

    return AnimatedContainer(
      key: properties.getKey(params.id),
      width: tryParseDouble(params.props["width"]),
      height: tryParseDouble(params.props["height"]),
      padding: properties.getInsets(params.props["padding"]),
      alignment: params.buildProp("alignment"),
      constraints: params.buildProp("constraints"),
      decoration: decoration,
      clipBehavior: decoration != null ? Clip.antiAlias : Clip.none,
      curve: params.buildProp("curve") ?? Curves.linear,
      duration: Duration(
          milliseconds: parseInt(params.props["duration"], defaultValue: 500)),
      onEnd: onEnd,
      child: child,
    );
  }

  @protected
  Widget buildCard(BuildParameters params) {
    var color = tryParseColor(params.props["color"]);
    return Card(
      key: properties.getKey(params.id),
      color: color,
      surfaceTintColor:
          tryParseColor(params.props["surfaceTintColor"]) ?? color,
      shadowColor: tryParseColor(params.props["shadowColor"]),
      elevation: tryParseDouble(params.props["elevation"]),
      shape: params.buildProp("shape"),
      clipBehavior: Clip.antiAlias,
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildRow(BuildParameters params) {
    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return Row(
      key: properties.getKey(params.id),
      verticalDirection: params.buildProp("verticalDirection"),
      crossAxisAlignment: params.buildProp("crossAxisAlignment"),
      mainAxisAlignment: params.buildProp("mainAxisAlignment"),
      mainAxisSize: params.props["mainAxisSize"] == "min"
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: children,
    );
  }

  @protected
  Widget buildColumn(BuildParameters params) {
    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return Column(
      key: properties.getKey(params.id),
      verticalDirection: params.buildProp("verticalDirection"),
      crossAxisAlignment: params.buildProp("crossAxisAlignment"),
      mainAxisAlignment: params.buildProp("mainAxisAlignment"),
      mainAxisSize: params.props["mainAxisSize"] == "min"
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: children,
    );
  }

  @protected
  Widget buildWrap(BuildParameters params) {
    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return Wrap(
      key: properties.getKey(params.id),
      direction: params.buildProp("direction") ?? Axis.horizontal,
      verticalDirection: params.buildProp("verticalDirection"),
      spacing: parseDouble(params.props["spacing"]),
      runAlignment:
          BaseProperties().getWrapAlignment(params.props["runAlignment"]),
      runSpacing: parseDouble(params.props["runSpacing"]),
      alignment: params.buildProp("alignment"),
      crossAxisAlignment: BaseProperties()
          .getWrapCrossAlignment(params.props["crossAxisAlignment"]),
      children: children,
    );
  }

  @protected
  Widget buildListTile(BuildParameters params) {
    Widget? leading = builder.tryBuildWidget(params.context,
        params.widgets["leading"], params.state, params.parentContext);
    leading ??= params.props["iconCode"] != null
        ? Icon(IconData(parseInt(params.props["iconCode"]),
            fontFamily: 'MaterialIcons'))
        : null;
    Widget? title = builder.tryBuildWidget(params.context,
        params.widgets["title"], params.state, params.parentContext);
    title ??= params.props["value"] != null
        ? Text(properties.getText(params.props["value"], "listTile"))
        : null;
    Widget? subtitle = builder.tryBuildWidget(params.context,
        params.widgets["subtitle"], params.state, params.parentContext);
    subtitle ??= params.props["subValue"] != null
        ? Text(properties.getText(params.props["subValue"], "listTile"))
        : null;
    ListTileStyle? listTileStyle;
    if (params.props["listTileStyle"] != null) {
      listTileStyle = params.props["listTileStyle"] == "drawer"
          ? ListTileStyle.drawer
          : ListTileStyle.list;
    }

    return ListTile(
      key: properties.getKey(params.id),
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: builder.tryBuildWidget(params.context,
          params.widgets["trailing"], params.state, params.parentContext),
      contentPadding: properties.getInsets(params.props["contentPadding"]),
      horizontalTitleGap: tryParseDouble(params.props["horizontalTitleGap"]),
      style: listTileStyle,
      iconColor: tryParseColor(params.props["iconColor"]),
      textColor: tryParseColor(params.props["textColor"]),
      tileColor: tryParseColor(params.props["tileColor"]),
      focusColor: tryParseColor(params.props["focusColor"]),
      hoverColor: tryParseColor(params.props["hoverColor"]),
      shape: params.buildProp("shape"),
      enabled: parseBool(params.props["enabled"], defaultValue: true),
      onTap: events.getFunction(params.context, params.actions["onTap"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildRichText(BuildParameters params) {
    final spanParts = <TextSpan>[];
    final evaluatorContext = Lowder.properties
        .getEvaluatorContext(null, params.state, params.parentContext);
    for (var child in params.widgets["children"]) {
      properties.evaluateMap(child, evaluatorContext);
      spanParts.add(buildTextSpan(params.context, WidgetNodeSpec.fromMap(child),
          params.state, params.parentContext));
    }

    return RichText(
      key: properties.getKey(params.id),
      text: TextSpan(children: spanParts),
      overflow: params.buildProp("overflow") ?? TextOverflow.clip,
      softWrap: parseBool(params.props["softWrap"], defaultValue: true),
      textAlign: params.buildProp("textAlign"),
      maxLines: tryParseInt(params.props["maxLines"]),
    );
  }

  @protected
  TextSpan buildTextSpan(BuildContext context, WidgetNodeSpec spec, Map state,
      Map? parentContext) {
    TapGestureRecognizer? tapRecognizer;
    final onTap = events.getFunction(
        context, spec.actions["onTap"], state, parentContext);
    if (onTap != null) {
      tapRecognizer = TapGestureRecognizer()..onTap = onTap;
    }

    return TextSpan(
      text: Strings.get(spec.props["value"] ?? ""),
      style: spec.buildProp("style"),
      recognizer: tapRecognizer,
    );
  }

  @protected
  Widget buildText(BuildParameters params) {
    return Text(
      params.buildProp("format", argument: params.props["value"]),
      key: properties.getKey(params.id),
      textAlign: params.buildProp("textAlign"),
      maxLines: tryParseInt(params.props["maxLines"]),
      semanticsLabel: params.props["semanticsLabel"],
      softWrap: tryParseBool(params.props["softWrap"]),
      overflow: params.buildProp("overflow"),
      style: params.buildProp("style"),
    );
  }

  @protected
  Widget buildTextFormField(BuildParameters params) {
    final props = params.props;
    final actions = params.actions;
    final alias = props["alias"] ?? params.id;
    final enabled = parseBool(props["enabled"], defaultValue: true);
    final textStyle =
        enabled ? params.buildProp("style") : params.buildProp("disabledStyle");
    final textInputAction =
        Types.textInputAction.build(props["textInputAction"]);
    final TextEditingController controller = props["controller"] ??
        TextEditingController(text: props["value"]?.toString());
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    final onSaved = props["onSaved"] ??
        (v) {
          if (alias != null) {
            params.state[alias] = v;
          }
        };

    final widgetMap = <String, Widget>{};
    for (var key in params.widgets.keys) {
      widgetMap[key] = builder.buildWidget(params.context, params.widgets[key],
          params.state, params.parentContext);
    }

    var onFieldSubmitted = events.getValueFunction(params.context,
        actions["onFieldSubmitted"], params.state, params.parentContext);
    var onEditingComplete = events.getValueFunction(params.context,
        actions["onEditingComplete"], params.state, params.parentContext);
    final onChangedAction = events.getValueFunction(params.context,
        actions["onChanged"], params.state, params.parentContext);

    ActionValueFunction<String>? onChanged;
    if (onChangedAction != null) {
      final onChangeDebounce =
          parseInt(props["onChangedDebounce"], defaultValue: 500);
      Timer? timer;
      onChanged = (value) {
        if (timer?.isActive ?? false) timer!.cancel();
        timer = Timer(Duration(milliseconds: onChangeDebounce),
            () => onChangedAction(value));
      };
      onFieldSubmitted ??= (value) {
        if (timer?.isActive ?? false) timer!.cancel();
        onChangedAction(value);
      };
    }

    if (onFieldSubmitted != null && onEditingComplete == null) {
      onEditingComplete = (v) {};
    }

    VoidCallback? finalOnEditingComplete;
    if (onEditingComplete != null) {
      finalOnEditingComplete = () => onEditingComplete!(controller.text);
    }

    return TextFormField(
      key: properties.getKey(params.id),
      controller: controller,
      autovalidateMode: AutovalidateMode.disabled,
      obscureText: parseBool(props["obscureText"]),
      enabled: enabled,
      textInputAction: textInputAction,
      autocorrect: parseBool(props["autocorrect"], defaultValue: true),
      keyboardType: params.buildProp("keyboardType"),
      minLines: tryParseInt(props["minLines"]),
      maxLines: parseInt(props["maxLines"], defaultValue: 1),
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textAlign: params.buildProp("textAlign"),
      textAlignVertical: params.buildProp("textAlignVertical"),
      style: textStyle,
      readOnly: parseBool(props["readOnly"]),
      autofocus: parseBool(props["autofocus"]),
      validator: builder.getStringValidator(props),
      enableSuggestions:
          parseBool(props["enableSuggestions"], defaultValue: true),
      expands: parseBool(props["expands"]),
      inputFormatters: params.buildProp("inputFormatters"),
      contextMenuBuilder: params.buildProp("toolbarOptions"),
      textCapitalization: params.buildProp("textCapitalization"),
      decoration: params.buildProp("decoration", argument: widgetMap),
      onTap: events.getFunction(params.context, params.actions["onTap"],
          params.state, params.parentContext),
      onEditingComplete: finalOnEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      onSaved: onSaved,
    );
  }

  @protected
  Widget buildInputDatePickerFormField(BuildParameters params) {
    var alias = params.props["alias"] ?? params.id;
    DateTime? value;
    if (params.props["value"] == "now") {
      value = DateTime.now();
    } else {
      value = tryParseDateTime(params.props["value"]);
    }
    DateTime firstDate;
    if (params.props["firstDate"] == "now") {
      firstDate = DateTime.now();
    } else {
      firstDate = DateTime(1900);
      if (params.props["firstDate"] != null) {
        firstDate =
            parseDateTime(params.props["lastDate"], defaultValue: firstDate);
      }
    }
    DateTime lastDate;
    if (params.props["lastDate"] == "now") {
      lastDate = DateTime.now();
    } else {
      lastDate = DateTime(2100);
      if (params.props["lastDate"] != null) {
        lastDate =
            parseDateTime(params.props["lastDate"], defaultValue: lastDate);
      }
    }

    return InputDatePickerFormField(
      key: properties.getKey(params.id),
      initialDate: value,
      firstDate: firstDate,
      lastDate: lastDate,
      fieldHintText: params.props["hint"],
      fieldLabelText: params.props["label"],
      onDateSubmitted: (v) {},
      onDateSaved: (v) {
        if (alias != null) {
          params.state[alias] = v;
        }
      },
    );
  }

  @protected
  Widget buildDatePicker(BuildParameters params) {
    DateTime? value;
    final pickDate = params.props["mode"] != "time";
    final pickTime = params.props["mode"] != "date";
    final formatSpec = params.props["format"] ??
        {
          "_type": pickDate && pickTime
              ? "KFormatterDateTime"
              : pickDate
                  ? "KFormatterDate"
                  : "KFormatterTime"
        };

    if (params.props["value"] == "now") {
      value = DateTime.now();
    } else {
      value = tryParseDateTime(params.props["value"]);
    }

    final controller = TextEditingController(
        text: properties.build(Types.kFormatter.type, formatSpec,
            argument: value));
    params.props["controller"] = controller;
    final alias = params.props["alias"] ?? params.id;
    params.props["onSaved"] = (v) {
      if (alias != null) {
        params.state[alias] = tryParseDateTime(value);
      }
    };

    DateTime firstDate;
    if (params.props["firstDate"] == "now") {
      firstDate = DateTime.now();
    } else {
      firstDate = DateTime(1900);
      if (params.props["firstDate"] != null) {
        firstDate =
            parseDateTime(params.props["lastDate"], defaultValue: firstDate);
      }
    }
    DateTime lastDate;
    if (params.props["lastDate"] == "now") {
      lastDate = DateTime.now();
    } else {
      lastDate = DateTime(2100);
      if (params.props["lastDate"] != null) {
        lastDate =
            parseDateTime(params.props["lastDate"], defaultValue: lastDate);
      }
    }

    if (!parseBool(params.props["readOnly"])) {
      params.actions["onTap"] = () async {
        final buildContext = params.context;
        final initialValue = value ?? DateTime.now();
        var newValue = value;
        if (pickDate) {
          final date = await showDatePicker(
              context: buildContext,
              initialDate: initialValue,
              firstDate: firstDate,
              lastDate: lastDate);
          if (date == null) {
            return;
          }
          newValue = date;
        }
        if (pickTime && buildContext.mounted) {
          final time = await showTimePicker(
              context: buildContext,
              initialTime: TimeOfDay.fromDateTime(initialValue));
          if (time == null) {
            return;
          }

          final dateValue = newValue ?? initialValue;
          newValue = DateTime(dateValue.year, dateValue.month, dateValue.day,
              time.hour, time.minute);
        }
        if (newValue != value) {
          value = newValue;
          controller.text = Types.kFormatter.build(formatSpec, argument: value);
        }
      };
    }

    return buildTextFormField(params);
  }

  @protected
  Widget buildSelect(BuildParameters params) {
    var value = params.props["value"];
    final stateClone = params.state.clone();
    final valueKey = params.props["valueKey"] ?? "id";
    final textKey = params.props["textKey"] ?? valueKey;
    final alias = params.props["alias"] ?? params.id;
    final controller = TextEditingController();
    params.props["controller"] = controller;
    params.props["onSaved"] = (v) => params.state[alias] = value;

    final headerSpec = params.widgets["dialogHeader"];
    final listTileSpec = params.widgets["dialogListTile"] ??
        {
          "_id": "${params.id}_listTile",
          "_type": "text",
          "properties": {
            "alias": textKey,
            "margin": 10,
          },
        };
    final separatorSpec = {
      "_id": "${params.id}_listSeparator",
      "_type": "container",
      "properties": {
        "height": 1,
        "decoration": {"color": "#33888888"},
      },
    };
    final listSpec = params.widgets["dialogList"] ??
        {
          "_id": "${params.id}_listView",
          "_type": "listView",
          "actions": {
            "loadPage": params.actions["loadData"],
          },
          "widgets": {
            "child": listTileSpec,
            "separator": separatorSpec,
          }
        };
    if (listSpec["actions"] == null) {
      listSpec["actions"] = <String, dynamic>{};
    }
    if (listSpec["actions"]["loadPage"] == null) {
      listSpec["actions"]["loadPage"] = params.actions["loadData"];
    }

    setValue(BuildContext context, v) {
      value = v is Map ? v[valueKey] : v;
      controller.text = v is Map ? v[textKey] : v?.toString() ?? "";
      Navigator.of(context).pop();
    }

    if (!parseBool(params.props["readOnly"])) {
      params.actions["onTap"] = () async {
        showDialog(
          context: params.context,
          useSafeArea: true,
          barrierDismissible: true,
          builder: (context) {
            listSpec["actions"]["onSelect"] = (v) => setValue(context, v);

            final content = Container(
              constraints: BoxConstraints(
                maxWidth: parseDouble(params.props["dialogMaxWidth"],
                    defaultValue: 350),
                maxHeight: parseDouble(params.props["dialogMaxHeight"],
                    defaultValue: 550),
              ),
              child: LocalBlocWidget(
                (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (params.props["dialogTitle"] != null)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                          child: Text(
                            Strings.getCapitalized(params.props["dialogTitle"]),
                            style: DialogTheme.of(context).titleTextStyle ??
                                Theme.of(context).textTheme.titleLarge!,
                          )),
                    if (headerSpec != null)
                      builder.buildWidget(context, headerSpec, stateClone,
                          params.parentContext),
                    Expanded(
                        child: builder.buildWidget(context, listSpec,
                            stateClone, params.parentContext)),
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(Strings.getCapitalized("cancel"))),
                            TextButton(
                                onPressed: () => setValue(context, null),
                                child: Text(Strings.getCapitalized("clear"))),
                          ],
                        )),
                  ],
                ),
              ),
            );
            return Dialog(child: content);
          },
        );
      };
    }
    final widget = buildTextFormField(params);

    final loadValueSpec = params.actions["loadValue"];
    if (value == null || loadValueSpec == null) {
      controller.text = "";
      return widget;
    }

    final bloc = events.createListBloc();
    return BlocConsumer<ListBloc, BaseState>(
      bloc: bloc,
      listener: (context, state) {},
      buildWhen: (oldState, newState) {
        return oldState != newState &&
            (newState is InitialState || newState is PageLoadedState);
      },
      builder: (context, state) {
        if (state is InitialState) {
          events.executePageLoadAction(context, bloc, 1, 1, [], loadValueSpec,
              stateClone, params.parentContext,
              value: value);
        } else if (state is PageLoadedState) {
          if (state.fullData.isNotEmpty) {
            final v = state.fullData.first;
            controller.text = v is Map ? v[textKey] : v?.toString() ?? "";
          }
        }
        return widget;
      },
    );
  }

  @protected
  Widget buildCheckbox(BuildParameters params) {
    final alias = params.props["alias"] ?? params.id;
    final enabled = parseBool(params.props["enabled"], defaultValue: true);
    final triState = parseBool(params.props["triState"]);
    bool? initialValue = triState
        ? tryParseBool(params.props["value"])
        : parseBool(params.props["value"]);
    final controlAffinity = params.props["direction"] == "leading"
        ? ListTileControlAffinity.leading
        : params.props["direction"] == "trailing"
            ? ListTileControlAffinity.trailing
            : ListTileControlAffinity.platform;

    Widget? title = builder.tryBuildWidget(params.context,
        params.widgets["titleWidget"], params.state, params.parentContext);
    title ??= params.props["title"] != null
        ? Text(properties.getText(params.props["title"], "titleMessage"))
        : null;
    Widget? subtitle = builder.tryBuildWidget(params.context,
        params.widgets["subtitleWidget"], params.state, params.parentContext);
    subtitle ??= params.props["subtitle"] != null
        ? Text(properties.getText(params.props["subtitle"], "titleMessage"))
        : null;

    final onChanged = events.getValueFunction<bool?>(params.context,
        params.actions["onChanged"], params.state, params.parentContext);
    final onSaved = params.props["onSaved"] ??
        (v) {
          if (alias != null) {
            params.state[alias] = v;
          }
        };

    return FormField<bool>(
      key:
          UniqueKey(), // otherwise on a ListView, FormField's state would override the real value
      initialValue: initialValue,
      enabled: enabled,
      autovalidateMode: AutovalidateMode.disabled,
      validator: builder.getCheckboxValidator(params.props),
      onSaved: onSaved,
      builder: (state) {
        return CheckboxListTile(
          key: properties.getKey(params.id),
          dense: state.hasError,
          value: state.value,
          tristate: triState,
          controlAffinity: controlAffinity,
          activeColor: tryParseColor(params.props["activeColor"]),
          checkColor: tryParseColor(params.props["checkColor"]),
          shape: params.buildProp("shape"),
          title: title,
          subtitle: state.hasError
              ? Text(properties.getText(state.errorText!, "errorMessage"),
                  style: TextStyle(
                      color: Theme.of(params.context).colorScheme.error))
              : subtitle,
          secondary: builder.tryBuildWidget(params.context,
              params.widgets["secondary"], params.state, params.parentContext),
          contentPadding: properties.getInsets(params.props["contentPadding"]),
          onChanged: enabled
              ? (val) {
                  state.didChange(val);
                  if (onChanged != null) {
                    onChanged(val);
                  }
                }
              : null,
        );
      },
    );
  }

  @protected
  Widget buildSwitch(BuildParameters params) {
    var alias = params.props["alias"] ?? params.id;
    var enabled = parseBool(params.props["enabled"], defaultValue: true);
    var controlAffinity = params.props["direction"] == "leading"
        ? ListTileControlAffinity.leading
        : params.props["direction"] == "trailing"
            ? ListTileControlAffinity.trailing
            : ListTileControlAffinity.platform;

    Widget? title = builder.tryBuildWidget(params.context,
        params.widgets["titleWidget"], params.state, params.parentContext);
    title ??= params.props["title"] != null
        ? Text(properties.getText(params.props["title"], "titleMessage"))
        : null;
    Widget? subtitle = builder.tryBuildWidget(params.context,
        params.widgets["subtitleWidget"], params.state, params.parentContext);
    subtitle ??= params.props["subtitle"] != null
        ? Text(properties.getText(params.props["subtitle"], "titleMessage"))
        : null;

    var onChanged = events.getValueFunction<bool?>(params.context,
        params.actions["onChanged"], params.state, params.parentContext);
    var onSaved = params.props["onSaved"] ??
        (v) {
          if (alias != null) {
            params.state[alias] = v;
          }
        };

    return FormField<bool>(
      key:
          UniqueKey(), // otherwise on a ListView, FormField's state would override the real value when reusing widgets
      initialValue: parseBool(params.props["value"]),
      enabled: enabled,
      autovalidateMode: AutovalidateMode.disabled,
      validator: builder.getCheckboxValidator(params.props),
      onSaved: onSaved,
      builder: (state) {
        return SwitchListTile(
          key: properties.getKey(params.id),
          value: state.value ?? false,
          controlAffinity: controlAffinity,
          activeColor: tryParseColor(params.props["activeColor"]),
          hoverColor: tryParseColor(params.props["hoverColor"]),
          activeTrackColor: tryParseColor(params.props["activeTrackColor"]),
          inactiveThumbColor: tryParseColor(params.props["inactiveThumbColor"]),
          inactiveTrackColor: tryParseColor(params.props["inactiveTrackColor"]),
          shape: params.buildProp("shape"),
          title: title,
          subtitle: state.hasError
              ? Text(properties.getText(state.errorText!, "errorMessage"),
                  style: TextStyle(
                      color: Theme.of(params.context).colorScheme.error))
              : subtitle,
          secondary: builder.tryBuildWidget(params.context,
              params.widgets["secondary"], params.state, params.parentContext),
          contentPadding: properties.getInsets(params.props["contentPadding"]),
          onChanged: enabled
              ? (val) {
                  state.didChange(val);
                  if (onChanged != null) {
                    onChanged(val);
                  }
                }
              : null,
        );
      },
    );
  }

  @protected
  Widget buildSlider(BuildParameters params) {
    final alias = params.props["alias"] ?? params.id;
    final enabled = parseBool(params.props["enabled"], defaultValue: true);

    final onChanged = events.getValueFunction<double?>(params.context,
        params.actions["onChanged"], params.state, params.parentContext);
    final onSaved = params.props["onSaved"] ??
        (v) {
          if (alias != null) {
            params.state[alias] = v;
          }
        };

    return FormField<double>(
      key:
          UniqueKey(), // otherwise on a ListView, FormField's state would override the real value when reusing widgets
      initialValue: parseDouble(params.props["value"]),
      enabled: enabled,
      autovalidateMode: AutovalidateMode.disabled,
      onSaved: onSaved,
      builder: (state) {
        return Slider(
          key: properties.getKey(params.id),
          value: parseDouble(state.value, defaultValue: 0),
          min: parseDouble(params.props["min"]),
          max: parseDouble(params.props["max"], defaultValue: 1),
          divisions: tryParseInt(params.props["divisions"]),
          thumbColor: tryParseColor(params.props["thumbColor"]),
          activeColor: tryParseColor(params.props["activeColor"]),
          inactiveColor: tryParseColor(params.props["inactiveColor"]),
          secondaryActiveColor:
              tryParseColor(params.props["secondaryActiveColor"]),
          secondaryTrackValue:
              tryParseDouble(params.props["secondaryTrackValue"]),
          label: params.props["label"],
          onChanged: enabled
              ? (val) {
                  state.didChange(val);
                  if (onChanged != null) {
                    onChanged(val);
                  }
                }
              : null,
        );
      },
    );
  }

  @protected
  Widget buildSizedBox(BuildParameters params) {
    return SizedBox(
      key: properties.getKey(params.id),
      width: tryParseDouble(params.props["width"]),
      height: tryParseDouble(params.props["height"]),
    );
  }

  @protected
  Widget buildStack(BuildParameters params) {
    var children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return Stack(
      key: properties.getKey(params.id),
      alignment: params.buildProp("alignment") ?? AlignmentDirectional.topStart,
      children: children,
    );
  }

  @protected
  Widget buildPositioned(BuildParameters params) {
    final childSpec = params.widgets["child"];
    final child = childSpec != null
        ? builder.buildWidget(params.context, params.widgets["child"],
            params.state, params.parentContext)
        : const SizedBox();

    return Positioned(
      key: properties.getKey(params.id),
      left: tryParseDouble(params.buildProp("left")),
      top: tryParseDouble(params.buildProp("top")),
      right: tryParseDouble(params.buildProp("right")),
      bottom: tryParseDouble(params.buildProp("bottom")),
      width: tryParseDouble(params.buildProp("width")),
      height: tryParseDouble(params.buildProp("height")),
      child: child,
    );
  }

  @protected
  Widget buildAnimatedPositioned(BuildParameters params) {
    final onEnd = events.getFunction(params.context, params.actions["onEnd"],
        params.state, params.parentContext);
    final childSpec = params.widgets["child"];
    final child = childSpec != null
        ? builder.buildWidget(params.context, params.widgets["child"],
            params.state, params.parentContext)
        : const SizedBox();

    return AnimatedPositioned(
      key: properties.getKey(params.id),
      left: tryParseDouble(params.buildProp("left")),
      top: tryParseDouble(params.buildProp("top")),
      right: tryParseDouble(params.buildProp("right")),
      bottom: tryParseDouble(params.buildProp("bottom")),
      width: tryParseDouble(params.buildProp("width")),
      height: tryParseDouble(params.buildProp("height")),
      curve: params.buildProp("curve") ?? Curves.linear,
      duration: Duration(
          milliseconds: parseInt(params.props["duration"], defaultValue: 500)),
      onEnd: onEnd,
      child: child,
    );
  }

  @protected
  Widget buildExpanded(BuildParameters params) {
    return Expanded(
      key: properties.getKey(params.id),
      flex: parseInt(params.props["flex"], defaultValue: 1),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
              params.state, params.parentContext) ??
          const SizedBox(),
    );
  }

  @protected
  Widget buildCustomScrollView(BuildParameters params) {
    final slivers = <Widget>[];
    if (params.widgets["slivers"] != null) {
      for (Map childSpec in params.widgets["slivers"] as List<Map>) {
        slivers.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return CustomScrollView(
      key: properties.getKey(params.id),
      reverse: parseBool(params.props["reverse"]),
      scrollDirection: params.buildProp("scrollDirection") ?? Axis.vertical,
      slivers: slivers,
    );
  }

  @protected
  Widget buildSingleChildScrollView(BuildParameters params) {
    final child = builder.tryBuildWidget(params.context,
        params.widgets["child"], params.state, params.parentContext);
    return SingleChildScrollView(
      key: properties.getKey(params.id),
      padding: properties.getInsets(params.props["padding"]),
      reverse: parseBool(params.props["reverse"]),
      scrollDirection: params.buildProp("scrollDirection") ?? Axis.vertical,
      keyboardDismissBehavior: params.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      child: child,
    );
  }

  @protected
  Widget buildScrollView(BuildParameters params) {
    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return ListView(
      key: properties.getKey(params.id),
      padding: properties.getInsets(params.props["padding"]),
      reverse: parseBool(params.props["reverse"]),
      scrollDirection: params.buildProp("scrollDirection") ?? Axis.vertical,
      keyboardDismissBehavior: params.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      children: children,
    );
  }

  @protected
  Widget buildListView(BuildParameters params) {
    return BlocList(
      params.spec,
      params.state,
      params.parentContext,
      key: properties.getKey(params.id),
    );
  }

  @protected
  Widget buildGridView(BuildParameters params) {
    return BlocGrid(
      params.spec,
      params.state,
      params.parentContext,
      key: properties.getKey(params.id),
    );
  }

  @protected
  Widget buildPageView(BuildParameters params) {
    return BlocPageView(
      params.spec,
      params.state,
      params.parentContext,
      key: properties.getKey(params.id),
    );
  }

  @protected
  Widget buildTable(BuildParameters params) {
    return BlocTable(
      params.spec,
      params.state,
      params.parentContext,
      key: properties.getKey(params.id),
    );
  }

  @protected
  Widget buildDataTable(BuildParameters params) {
    return BlocDataTable(
      params.spec,
      params.state,
      params.parentContext,
      key: properties.getKey(params.id),
    );
  }

  @protected
  Widget buildStaticListView(BuildParameters params) {
    final spec = params.spec;
    final props = spec.props;

    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return ListView(
      key: properties.getKey(params.id),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      reverse: parseBool(props["reverse"]),
      primary: tryParseBool(props["primary"]),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.vertical,
      keyboardDismissBehavior: spec.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      semanticChildCount: children.length,
      children: children,
    );
  }

  @protected
  Widget buildStaticGridView(BuildParameters params) {
    final spec = params.spec;
    final props = spec.props;

    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return GridView.count(
      key: Lowder.properties.getKey(params.id),
      crossAxisCount: spec.buildProp("crossAxisCount") ?? 1,
      mainAxisSpacing: parseDouble(props["mainAxisSpacing"]),
      crossAxisSpacing: parseDouble(props["crossAxisSpacing"]),
      childAspectRatio:
          parseDouble(props["childAspectRatio"], defaultValue: 1.0),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.vertical,
      reverse: parseBool(props["reverse"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      primary: tryParseBool(props["primary"]),
      keyboardDismissBehavior: params.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      semanticChildCount: children.length,
      children: children,
    );
  }

  @protected
  Widget buildStaticPageView(BuildParameters params) {
    final spec = params.spec;
    final props = spec.props;
    final onPageChanged = events.getValueFunction<int?>(params.context,
        params.actions["onPageChanged"], params.state, params.parentContext);

    final children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    return PageView(
      key: properties.getKey(params.id),
      reverse: parseBool(props["reverse"]),
      pageSnapping: parseBool(props["pageSnapping"], defaultValue: true),
      padEnds: parseBool(props["padEnds"], defaultValue: true),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.horizontal,
      controller: PageController(
        initialPage: parseInt(props["initialPage"]),
        viewportFraction:
            parseDouble(props["viewportFraction"], defaultValue: 1.0),
        keepPage: parseBool(props["keepPage"], defaultValue: true),
      ),
      onPageChanged: onPageChanged,
      children: children,
    );
  }

  @protected
  Widget buildTabView(BuildParameters params) {
    var children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    var tabs = <Widget>[];
    if (params.widgets["tabs"] != null) {
      for (Map childSpec in params.widgets["tabs"] as List<Map>) {
        tabs.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    final overlayColor = tryParseColor(params.props["overlayColor"]);
    return DefaultTabController(
      key: properties.getKey(params.id),
      length: min(children.length, tabs.length),
      initialIndex: parseInt(params.props["initialIndex"]),
      child: Column(
        key: properties.getKey("${params.id}_tabs"),
        mainAxisSize: params.props["mainAxisSize"] == "min"
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: params.buildProp("mainAxisAlignment"),
        crossAxisAlignment: params.buildProp("crossAxisAlignment"),
        verticalDirection: params.buildProp("verticalDirection"),
        children: [
          TabBar(
            tabs: tabs,
            padding: properties.getInsets(params.props["padding"]),
            indicator: params.buildProp("indicator"),
            indicatorColor: tryParseColor(params.props["indicatorColor"]),
            indicatorPadding:
                properties.getInsets(params.props["indicatorPadding"]) ??
                    EdgeInsets.zero,
            indicatorSize: params.buildProp("indicatorSize"),
            indicatorWeight:
                parseDouble(params.props["indicatorWeight"], defaultValue: 2.0),
            isScrollable: parseBool(params.props["isScrollable"]),
            labelColor: tryParseColor(params.props["labelColor"]),
            labelPadding: properties.getInsets(params.props["labelPadding"]),
            labelStyle: params.buildProp("labelStyle"),
            unselectedLabelColor:
                tryParseColor(params.props["unselectedLabelColor"]),
            unselectedLabelStyle: params.buildProp("unselectedLabelStyle"),
            dividerColor: tryParseColor(params.props["dividerColor"]),
            dividerHeight: tryParseDouble(params.props["dividerHeight"]),
            overlayColor: overlayColor != null
                ? MaterialStatePropertyAll<Color>(overlayColor)
                : null,
          ),
          Expanded(
              child: TabBarView(
            key: properties.getKey("${params.id}_tabViews"),
            children: children,
          )),
        ],
      ),
    );
  }

  @protected
  Widget buildTabBar(BuildParameters params) {
    var tabs = <Widget>[];
    if (params.widgets["tabs"] != null) {
      for (Map childSpec in params.widgets["tabs"] as List<Map>) {
        tabs.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }

    final overlayColor = tryParseColor(params.props["overlayColor"]);
    return TabBar(
      key: properties.getKey(params.id),
      tabs: tabs,
      padding: properties.getInsets(params.props["padding"]),
      indicator: params.buildProp("indicator"),
      indicatorColor: tryParseColor(params.props["indicatorColor"]),
      indicatorPadding:
          properties.getInsets(params.props["indicatorPadding"]) ??
              EdgeInsets.zero,
      indicatorSize: params.buildProp("indicatorSize"),
      indicatorWeight:
          parseDouble(params.props["indicatorWeight"], defaultValue: 2.0),
      isScrollable: parseBool(params.props["isScrollable"]),
      labelColor: tryParseColor(params.props["labelColor"]),
      labelPadding: properties.getInsets(params.props["labelPadding"]),
      labelStyle: params.buildProp("labelStyle"),
      unselectedLabelColor: tryParseColor(params.props["unselectedLabelColor"]),
      unselectedLabelStyle: params.buildProp("unselectedLabelStyle"),
      dividerColor: tryParseColor(params.props["dividerColor"]),
      dividerHeight: tryParseDouble(params.props["dividerHeight"]),
      overlayColor: overlayColor != null
          ? MaterialStatePropertyAll<Color>(overlayColor)
          : null,
    );
  }

  @protected
  Widget buildTabBarView(BuildParameters params) {
    var children = <Widget>[];
    if (params.widgets["children"] != null) {
      for (Map childSpec in params.widgets["children"] as List<Map>) {
        children.add(builder.buildWidget(
            params.context, childSpec, params.state, params.parentContext));
      }
    }
    return TabBarView(key: properties.getKey(params.id), children: children);
  }

  @protected
  Widget buildTextButton(BuildParameters params) {
    Widget child;
    if (params.widgets["child"] != null) {
      child = builder.buildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext);
    } else if (params.props["text"] != null) {
      child = Text(properties.getText(params.props["text"], "button"));
    } else {
      child = Container();
    }

    return TextButton(
      key: properties.getKey(params.id),
      style: params.buildProp("style"),
      onPressed: events.getFunction(params.context, params.actions["onPressed"],
          params.state, params.parentContext),
      child: child,
    );
  }

  @protected
  Widget buildElevatedButton(BuildParameters params) {
    Widget child;
    if (params.widgets["child"] != null) {
      child = builder.buildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext);
    } else if (params.props["text"] != null) {
      child = Text(properties.getText(params.props["text"], "button"));
    } else {
      child = Container();
    }

    return ElevatedButton(
      key: properties.getKey(params.id),
      style: params.buildProp("style"),
      onPressed: events.getFunction(params.context, params.actions["onPressed"],
          params.state, params.parentContext),
      child: child,
    );
  }

  @protected
  Widget buildOutlinedButton(BuildParameters params) {
    Widget child;
    if (params.widgets["child"] != null) {
      child = builder.buildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext);
    } else if (params.props["text"] != null) {
      child = Text(properties.getText(params.props["text"], "button"));
    } else {
      child = Container();
    }

    return OutlinedButton(
      key: properties.getKey(params.id),
      style: params.buildProp("style"),
      onPressed: events.getFunction(params.context, params.actions["onPressed"],
          params.state, params.parentContext),
      child: child,
    );
  }

  @protected
  Widget buildFloatingActionButton(BuildParameters params) {
    Widget? child;
    if (params.widgets["child"] != null) {
      child = builder.buildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext);
    } else if (params.props["iconCode"] != null) {
      child = Icon(IconData(parseInt(params.props["iconCode"]),
          fontFamily: 'MaterialIcons'));
    }

    return FloatingActionButton(
      key: properties.getKey(params.id),
      tooltip: params.props["tooltip"] != null
          ? properties.getText(params.props["tooltip"], "label")
          : null,
      mini: parseBool(params.props["mini"]),
      shape: params.buildProp("shape"),
      backgroundColor: tryParseColor(params.props["backgroundColor"]),
      hoverColor: tryParseColor(params.props["hoverColor"]),
      splashColor: tryParseColor(params.props["splashColor"]),
      focusColor: tryParseColor(params.props["focusColor"]),
      foregroundColor: tryParseColor(params.props["foregroundColor"]),
      elevation: tryParseDouble(params.props["elevation"]),
      focusElevation: tryParseDouble(params.props["focusElevation"]),
      highlightElevation: tryParseDouble(params.props["highlightElevation"]),
      hoverElevation: tryParseDouble(params.props["hoverElevation"]),
      disabledElevation: tryParseDouble(params.props["disabledElevation"]),
      onPressed: events.getFunction(params.context, params.actions["onPressed"],
          params.state, params.parentContext),
      child: child,
    );
  }

  @protected
  Widget buildDropdownButton(BuildParameters params) {
    final alias = params.props["alias"] ?? params.id;
    final nameKey = params.props["nameKey"] ?? "name";
    final valueKey = params.props["valueKey"] ?? "id";
    final valueList = getMenuValues(params.props["values"], nameKey, valueKey);

    final menuItems = <DropdownMenuItem<String>>[];
    for (var map in valueList) {
      menuItems.add(DropdownMenuItem<String>(
        value: map[valueKey],
        alignment:
            params.buildProp("alignment") ?? AlignmentDirectional.centerStart,
        child: Text(properties.getText(map[nameKey], "menu"),
            overflow: TextOverflow.ellipsis),
      ));
    }

    final enabled = parseBool(params.props["enabled"], defaultValue: true);
    final textStyle =
        enabled ? params.buildProp("style") : params.buildProp("disabledStyle");
    ValueChanged<String?>? onChangeFunc;
    if (enabled) {
      final onChangeAction = events.getValueFunction<String?>(params.context,
          params.actions["onChanged"], params.state, params.parentContext);
      onChangeFunc = (newValue) {
        if (onChangeAction != null) {
          onChangeAction(newValue);
        }
      };
    }

    final widgetMap = <String, Widget>{};
    for (var key in params.widgets.keys) {
      if (params.widgets[key] is List) {
        continue;
      }
      widgetMap[key] = builder.buildWidget(params.context, params.widgets[key],
          params.state, params.parentContext);
    }

    return DropdownButtonFormField<String>(
      key: properties.getKey(params.id),
      style: textStyle,
      focusColor: tryParseColor(params.props["focusColor"]),
      dropdownColor: tryParseColor(params.props["dropdownColor"]),
      iconEnabledColor: tryParseColor(params.props["iconEnabledColor"]),
      iconDisabledColor: tryParseColor(params.props["iconDisabledColor"]),
      elevation: parseInt(params.props["elevation"], defaultValue: 8),
      isExpanded: true,
      itemHeight: tryParseDouble(params.props["itemHeight"]),
      alignment:
          params.buildProp("alignment") ?? AlignmentDirectional.centerStart,
      decoration: params.buildProp("decoration", argument: widgetMap),
      autovalidateMode: AutovalidateMode.disabled,
      hint: builder.tryBuildWidget(params.context, params.widgets["hint"],
          params.state, params.parentContext),
      value: params.props["value"]?.toString(),
      validator: builder.getStringValidator(params.props),
      icon: builder.tryBuildWidget(params.context, params.widgets["icon"],
          params.state, params.parentContext),
      iconSize: parseDouble(params.props["iconSize"], defaultValue: 24.0),
      menuMaxHeight: tryParseDouble(params.props["menuMaxHeight"]),
      items: menuItems,
      onChanged: onChangeFunc,
      onSaved: (v) {
        if (alias != null) {
          params.state[alias] = v;
        }
      },
    );
  }

  @protected
  Widget buildPopupMenuButton(BuildParameters params) {
    final alias = params.props["alias"] ?? params.id;
    final function = events.getValueFunction<Object?>(params.context,
        params.actions["onSelected"], params.state, params.parentContext);

    final nameKey = params.props["nameKey"] ?? "name";
    final valueKey = params.props["valueKey"] ?? "id";
    final valueList = getMenuValues(params.props["values"], nameKey, valueKey);

    var menuItems = <PopupMenuItem<String>>[];
    for (var map in valueList) {
      menuItems.add(PopupMenuItem<String>(
        value: map[valueKey],
        child: Text(properties.getText(map[nameKey], "menu")),
      ));
    }

    return PopupMenuButton<String>(
      itemBuilder: (a) => menuItems,
      key: properties.getKey(params.id),
      initialValue: params.props["value"]?.toString(),
      color: tryParseColor(params.props["color"]),
      tooltip: params.props["tooltip"] != null
          ? properties.getText(params.props["tooltip"], "label")
          : null,
      shape: params.buildProp("shape"),
      padding: properties.getInsets(params.props["padding"]) ??
          const EdgeInsets.all(8.0),
      enabled: parseBool(params.props["enabled"], defaultValue: true),
      offset: params.buildProp("offset") ?? Offset.zero,
      elevation: tryParseDouble(params.props["elevation"]),
      icon: builder.tryBuildWidget(params.context, params.widgets["icon"],
          params.state, params.parentContext),
      iconSize: tryParseDouble(params.props["iconSize"]),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
      onSelected: (v) {
        if (alias != null) {
          params.state[alias] = v;
        }
        if (function != null) {
          function.call(v);
        }
      },
    );
  }

  @protected
  List<Map<String, dynamic>> getMenuValues(
      dynamic values, String nameKey, String valueKey) {
    final valueList = <Map<String, dynamic>>[];
    if (values is String) {
      final valueSplit = values.split("|");
      for (var val in valueSplit) {
        valueList.add({
          nameKey: val,
          valueKey: val,
        });
      }
    } else if (values is List) {
      for (var val in values) {
        if (val is Map) {
          valueList.add({
            nameKey: val[nameKey] ?? val[valueKey],
            valueKey: val[valueKey],
          });
        } else if (val is String) {
          valueList.add({
            nameKey: val,
            valueKey: val,
          });
        }
      }
    }
    return valueList;
  }

  @protected
  Widget buildIconButton(BuildParameters params) {
    Widget icon;
    if (params.widgets["icon"] != null) {
      icon = builder.buildWidget(params.context, params.widgets["icon"],
          params.state, params.parentContext);
    } else {
      icon = Icon(IconData(parseInt(params.props["iconCode"]),
          fontFamily: 'MaterialIcons'));
    }

    return IconButton(
      key: properties.getKey(params.id),
      icon: icon,
      alignment: params.buildProp("alignment") ?? AlignmentDirectional.center,
      padding: properties.getInsets(params.props["padding"]) ??
          const EdgeInsets.all(8.0),
      iconSize: parseDouble(params.props["iconSize"], defaultValue: 24.0),
      tooltip: params.props["tooltip"] != null
          ? properties.getText(params.props["tooltip"], "label")
          : null,
      color: tryParseColor(params.props["color"]),
      focusColor: tryParseColor(params.props["focusColor"]),
      hoverColor: tryParseColor(params.props["hoverColor"]),
      splashColor: tryParseColor(params.props["splashColor"]),
      highlightColor: tryParseColor(params.props["highlightColor"]),
      disabledColor: tryParseColor(params.props["disabledColor"]),
      style: params.buildProp("style"),
      constraints: params.buildProp("constraints"),
      onPressed: events.getFunction(params.context, params.actions["onPressed"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildHero(BuildParameters params) {
    final child = params.widgets["child"] != null
        ? builder.buildWidget(params.context, params.widgets["child"],
            params.state, params.parentContext)
        : const SizedBox();
    return Hero(
        key: properties.getKey(params.id),
        tag: params.props["tag"] ?? params.id,
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ));
  }

  @protected
  Widget buildIcon(BuildParameters params) {
    return Icon(
      IconData(
        parseInt(params.props["iconCode"]),
        fontFamily: 'MaterialIcons',
      ),
      key: properties.getKey(params.id),
      color: tryParseColor(params.props["color"]),
      size: tryParseDouble(params.props["size"]),
      semanticLabel: params.props["semanticLabel"],
    );
  }

  @protected
  Widget buildInkWell(BuildParameters params) {
    final overlayColor = tryParseColor(params.props["overlayColor"]);
    final onTapUp = events.getValueFunction(params.context,
        params.actions["onTapUp"], params.state, params.parentContext);
    final onTapDown = events.getValueFunction(params.context,
        params.actions["onTapDown"], params.state, params.parentContext);

    return InkWell(
      key: properties.getKey(params.id),
      borderRadius: params.buildProp("borderRadius"),
      customBorder: params.buildProp("customBorder"),
      overlayColor: overlayColor != null
          ? MaterialStateProperty.all<Color>(overlayColor)
          : null,
      highlightColor: tryParseColor(params.props["highlightColor"]),
      splashColor: tryParseColor(params.props["splashColor"]),
      hoverColor: tryParseColor(params.props["hoverColor"]),
      focusColor: tryParseColor(params.props["focusColor"]),
      onTapDown: onTapDown != null
          ? (a) =>
              onTapDown({"x": a.globalPosition.dx, "y": a.globalPosition.dy})
          : null,
      onTapUp: onTapUp != null
          ? (a) => onTapUp({"x": a.globalPosition.dx, "y": a.globalPosition.dy})
          : null,
      onTap: events.getFunction(params.context, params.actions["onTap"],
          params.state, params.parentContext),
      onDoubleTap: events.getFunction(params.context,
          params.actions["onDoubleTap"], params.state, params.parentContext),
      onLongPress: events.getFunction(params.context,
          params.actions["onLongPress"], params.state, params.parentContext),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildImage(BuildParameters params) {
    final props = params.props;
    final fallbackSpec = params.widgets["fallback"];
    var imageProvider = params.buildProp("provider", argument: props["value"]);
    imageProvider ??= const AssetImage("assets/logo");

    return Image(
      key: properties.getKey(params.id),
      image: imageProvider,
      errorBuilder: fallbackSpec != null
          ? (context, ex, stack) {
              return builder.buildWidget(
                  context, fallbackSpec, params.state, params.parentContext);
            }
          : null,
      color: tryParseColor(props["color"]),
      width: tryParseDouble(props["width"]),
      height: tryParseDouble(props["height"]),
      alignment: params.buildProp("alignment") ?? Alignment.center,
      fit: params.buildProp("fit"),
    );
  }

  @protected
  Widget buildCircleAvatar(BuildParameters params) {
    final props = params.spec.props;
    ImageErrorListener? onForegroundImageError;
    ImageErrorListener? onBackgroundImageError;
    var foregroundImage = params.buildProp("foregroundProvider",
        argument: props["foregroundValue"]);
    var backgroundImage = params.buildProp("backgroundProvider",
        argument: props["backgroundValue"]);

    if (foregroundImage != null) {
      onForegroundImageError = (ex, stack) {};
    }
    if (backgroundImage != null) {
      onBackgroundImageError = (ex, stack) {};
    }

    return CircleAvatar(
      key: properties.getKey(params.id),
      radius: tryParseDouble(props["radius"]),
      foregroundImage: foregroundImage,
      onForegroundImageError: onForegroundImageError,
      backgroundImage: backgroundImage,
      onBackgroundImageError: onBackgroundImageError,
      foregroundColor: tryParseColor(props["foregroundColor"]),
      backgroundColor: tryParseColor(props["backgroundColor"]),
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildCircularProgressIndicator(BuildParameters params) {
    final doWorkFunc = events.getFunction(params.context,
        params.actions["doWork"], params.state, params.parentContext);

    if (doWorkFunc != null) {
      Future.delayed(const Duration(milliseconds: 500), doWorkFunc);
    }
    return CircularProgressIndicator(
      key: properties.getKey(params.id),
      color: tryParseColor(params.props["color"]),
      strokeWidth: parseDouble(params.props["strokeWidth"], defaultValue: 4.0),
      strokeAlign: parseDouble(params.props["strokeAlign"]),
    );
  }

  @protected
  Widget buildBadge(BuildParameters params) {
    final props = params.props;

    Widget? label = builder.tryBuildWidget(params.context,
        params.widgets["label"], params.state, params.parentContext);
    label ??= Text("${props["label"] ?? ""}");

    return Badge(
      key: properties.getKey(params.id),
      alignment: params.buildProp("alignment"),
      padding: properties.getInsets(props["padding"]),
      textStyle: params.buildProp("textStyle"),
      textColor: tryParseColor(props["textColor"]),
      backgroundColor: tryParseColor(props["backgroundColor"]),
      isLabelVisible: props["isLabelVisible"] != null
          ? properties.evaluateCondition(props["isLabelVisible"])
          : true,
      label: label,
      child: builder.tryBuildWidget(params.context, params.widgets["child"],
          params.state, params.parentContext),
    );
  }

  @protected
  Widget buildBlocBuilder(BuildParameters params) {
    final children = params.widgets["states"] as List<Map>?;
    if (children == null || children.isEmpty) {
      return const SizedBox();
    }

    final log = Logger("BlocBuilder");
    final stateActions = <String>[];
    final stateWidgets = <String>[];
    final actionMap = <String, Map?>{};
    final widgetMap = <String, Map?>{};
    for (var child in children) {
      final childProps = child["properties"] as Map? ?? {};
      final state = childProps["state"] as String? ?? "";

      if (state.isNotEmpty) {
        stateActions.add(state);
        final childActions = child["actions"] as Map? ?? {};
        actionMap[state] = childActions["listener"] as Map?;

        if (child["_type"] != "StateListener") {
          stateWidgets.add(state);
          final childWidgets = child["widgets"] as Map? ?? {};
          widgetMap[state] = childWidgets["child"] as Map?;
        }
      }
    }

    final parentContext = params.parentContext ?? {};
    final type = params.props["type"] ?? "local";
    final defaultWidgetSpec = params.widgets["child"] as Map?;

    listenWhen(BaseState prev, BaseState next) =>
        prev != next &&
        next is ActionState &&
        stateActions.contains(next.state);
    buildWhen(BaseState prev, BaseState next) =>
        prev != next &&
        next is ActionState &&
        stateWidgets.contains(next.state);

    listener(BuildContext context, BaseState state) {
      if (state is! ActionState) {
        return;
      }

      final actionSpec = actionMap[state.state];
      if (actionSpec == null) {
        return;
      }

      final stateContext = parentContext.clone();
      stateContext.addAll({"stateData": state.data});

      final func = events.getFunction(
          context, actionSpec.clone(), params.state, stateContext);
      if (func != null) {
        log.info(
            "Executing '${actionSpec["name"] ?? actionSpec["_type"]}' from state '${state.state}'");
        func();
      }
    }

    stateBuilder(BuildContext context, BaseState state) {
      Map? widgetSpec;
      if (state is ActionState) {
        widgetSpec = widgetMap[state.state];
      }
      widgetSpec ??= defaultWidgetSpec;
      if (widgetSpec == null) return const SizedBox();

      final stateContext = parentContext.clone();
      if (state is ActionState) {
        stateContext.addAll({"stateData": state.data});
        log.info(
            "Building '${widgetSpec["name"] ?? widgetSpec["_type"]}' from state '${state.state}'");
      }
      params.state.remove(widgetSpec["_id"]);

      return builder.buildWidget(
          context, widgetSpec.clone(), params.state, stateContext);
    }

    return type == "global"
        ? BlocConsumer<GlobalBloc, BaseState>(
            listenWhen: listenWhen,
            listener: listener,
            buildWhen: buildWhen,
            builder: stateBuilder)
        : BlocConsumer<LocalBloc, BaseState>(
            listenWhen: listenWhen,
            listener: listener,
            buildWhen: buildWhen,
            builder: stateBuilder);
  }
}
