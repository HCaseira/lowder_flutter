import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../bloc/editor_bloc.dart';
import '../model/editor_node.dart';
import '../model/node_spec.dart';
import '../schema.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../widget/lowder.dart';
import '../widget/bloc_handler.dart';
import '../widget/edit_widget.dart';
import '../widget/screen.dart';
import 'action_factory.dart';
import 'property_factory.dart';
import 'widgets.dart';

/// Class that handles Widget related operations.
class WidgetFactory {
  static DialogRoute? activityIndicatorRoute;
  final log = Logger("WidgetFactory");
  final Map<String, EditorWidget> _schema = {};
  final Map<String, WidgetBuilderFunc> _widgetBuilders = {};
  ActionFactory get actions => Lowder.actions;
  PropertyFactory get properties => Lowder.properties;
  BuildContext get appContext => Lowder.navigatorKey.currentContext!;
  NavigatorState get appNavigator =>
      Navigator.of(appContext, rootNavigator: true);

  /// Schema loading
  @nonVirtual
  void loadWidgets(IWidgets widgets) {
    _schema.addAll(widgets.schema);
    _widgetBuilders.addAll(widgets.builders);
  }

  /// Returns a Widget's propery schema.
  Map<String, EditorPropertyType> getPropertySchema(String type) {
    final schema = _schema[type]!;
    final props = <String, EditorPropertyType>{}
      ..addAll(schema.properties ?? {});
    var baseType = schema.baseType;
    while (baseType != null && baseType.isNotEmpty) {
      if (_schema[baseType] == null) {
        log.severe("Type '$baseType' not found.");
        break;
      }
      var baseTypeSchema = _schema[baseType]!;
      props.addAll(baseTypeSchema.properties ?? {});
      baseType = baseTypeSchema.baseType;
    }
    return props;
  }

  /// Creates a [MaterialPageRoute] for a given Screen [spec].
  MaterialPageRoute buildRoute(WidgetNodeSpec spec, {Map? state}) {
    return MaterialPageRoute(
      settings: RouteSettings(name: spec.name, arguments: spec),
      builder: (context) => buildScreen(context, spec, state: state),
    );
  }

  /// Builds a [LowderScreen] based on its [spec].
  Widget buildScreen(BuildContext context, WidgetNodeSpec spec, {Map? state}) {
    state ??= {};
    return internalBuildScreen(context, spec, state);
  }

  /// Tries to execute a [Widget] build from a [spec].
  Widget? tryBuildWidget(
      BuildContext context, dynamic spec, Map state, Map? parentContext) {
    if (spec == null) {
      return null;
    } else if (spec is Widget) {
      return spec;
    } else if (spec is! Map) {
      return null;
    }
    return buildWidget(context, spec, state, parentContext);
  }

  /// Transforms a Map spec to a WidgetNodeSpec spec and executes [buildWidgetFromSpec].
  Widget buildWidget(
      BuildContext context, Map spec, Map state, Map? parentContext) {
    return buildWidgetFromSpec(
        context, WidgetNodeSpec.fromMap(spec), state, parentContext);
  }

  /// Executes a [Widget] build from a [spec].
  Widget buildWidgetFromSpec(BuildContext context, WidgetNodeSpec spec,
      Map state, Map? parentContext) {
    preBuild(context, spec, state, parentContext);
    final widget = createWidget(context, spec, state, parentContext);
    if (widget is NoWidget) {
      return widget;
    }
    return postBuild(context, widget, spec);
  }

  /// Builds a [LowderScreen] based on its [spec].
  @protected
  Widget internalBuildScreen(
      BuildContext context, WidgetNodeSpec spec, Map screenState) {
    preBuild(context, spec, screenState, null);
    return LowderScreen(spec, screenState);
  }

  /// Creates a [Widget] based on its [spec].
  @protected
  Widget createWidget(BuildContext context, WidgetNodeSpec spec, Map state,
      Map? parentContext) {
    if (!EditorBloc.editMode && spec.props["buildCondition"] != null) {
      if (!properties.build(
          Types.kCondition.type, spec.props["buildCondition"])) {
        return const NoWidget();
      }
    }

    if (!_widgetBuilders.containsKey(spec.type)) {
      log.severe("Widget builder for type '${spec.type}' not found");
      return const SizedBox();
    }

    final params = BuildParameters(context, spec, state, parentContext);
    return _widgetBuilders[spec.type]!(params);
  }

  /// Evaluates properties and applies the template.
  @protected
  void preBuild(BuildContext context, WidgetNodeSpec spec, Map state,
      Map? parentContext) {
    final evaluatorContext = getEvaluatorContext(null, state, parentContext);
    final template = getTemplate(spec.template);
    mergeTemplateAndState(spec, template, state, evaluatorContext);
  }

  /// Handles generic convenience properties from a [spec],
  /// like decoration, margin or visibility.
  @protected
  Widget postBuild(BuildContext context, Widget widget, WidgetNodeSpec spec) {
    widget = handleHero(context, widget, spec);
    widget = handleDecorator(context, widget, spec);
    widget = handleMargin(context, widget, spec);
    if (EditorBloc.editMode &&
        widget is! PreferredSizeWidget &&
        widget is! Expanded) {
      widget = EditWidget(spec.id, widget);
    }
    widget = handleExpanded(context, widget, spec);
    widget = handleSafeArea(context, widget, spec);
    widget = handleVisibility(context, widget, spec);
    return widget;
  }

  /// Handles convenience 'hero' property.
  @protected
  Widget handleHero(BuildContext context, Widget widget, WidgetNodeSpec spec) {
    if (spec.props["heroTag"] != null) {
      final hero = Hero(
          tag: spec.props["heroTag"],
          child: Material(type: MaterialType.transparency, child: widget));
      if (widget is PreferredSizeWidget) {
        widget = PreferredSize(
          preferredSize: Size.fromHeight(widget.preferredSize.height),
          child: hero,
        );
      } else {
        widget = hero;
      }
    }
    return widget;
  }

  /// Handles convenience 'decoration' property.
  @protected
  Widget handleDecorator(
      BuildContext context, Widget widget, WidgetNodeSpec spec) {
    if (spec.props["decorator"] != null && spec.props["decorator"].length > 0) {
      widget = buildWidget(
          context,
          {
            "_id": "",
            "_type": "container",
            "properties": spec.props["decorator"],
            "widgets": {
              "child": widget,
            }
          },
          {},
          null);
    }
    return widget;
  }

  /// Handles convenience 'wrapExpanded' property.
  @protected
  Widget handleExpanded(
      BuildContext context, Widget widget, WidgetNodeSpec spec) {
    if (parseBool(spec.props["wrapExpanded"])) {
      widget = Expanded(child: widget);
    }
    return widget;
  }

  /// Handles convenience 'margin' property.
  @protected
  Widget handleMargin(
      BuildContext context, Widget widget, WidgetNodeSpec spec) {
    final insets =
        properties.getInsets(spec.props["wrapPadding"] ?? spec.props["margin"]);
    if (insets != null) {
      widget = Padding(padding: insets, child: widget);
    }
    return widget;
  }

  /// Handles convenience 'safeArea' property.
  @protected
  Widget handleSafeArea(
      BuildContext context, Widget widget, WidgetNodeSpec spec) {
    final prop = spec.props["wrapSafeArea"] ?? spec.props["safeArea"];
    if (prop is Map) {
      return SafeArea(
        left: parseBool(prop["left"], defaultValue: true),
        top: parseBool(prop["top"], defaultValue: true),
        right: parseBool(prop["right"], defaultValue: true),
        bottom: parseBool(prop["bottom"], defaultValue: true),
        minimum: properties.getInsets(prop["minimum"]) ?? EdgeInsets.zero,
        child: widget,
      );
    } else if (parseBool(prop)) {
      return SafeArea(child: widget);
    }
    return widget;
  }

  /// Handles convenience 'visible' property.
  @protected
  Widget handleVisibility(
      BuildContext context, Widget widget, WidgetNodeSpec spec) {
    if (!parseBool(spec.props["visible"], defaultValue: true)) {
      widget = Visibility(visible: false, child: widget);
    }
    return widget;
  }

  /// Convenience method to instantiate a [LocalBlocConsumer] and facilitate overriding.
  Widget getLocalBlocConsumer(BlocBuilderFunction builder,
          {BlocListenerFunction? listener}) =>
      LocalBlocConsumer(builder, defaultListener: listener);

  /// Convenience method to instantiate a [GlobalBlocConsumer] and facilitate overriding.
  Widget getGlobalBlocConsumer(BlocBuilderFunction builder,
          {BlocListenerFunction? listener, WidgetNodeSpec? node}) =>
      GlobalBlocConsumer(builder, defaultListener: listener, node: node);

  /// Builds a dialog displaying [message].
  Future<void> showMessage(
      {String type = "info",
      String? message,
      Map? props,
      GestureTapCallback? onTap,
      BuildContext? context}) async {
    if (message == null || message.isEmpty) {
      return;
    }

    Color bgColor;
    Color textColor;
    switch (type) {
      case "success":
        bgColor = Colors.green;
        textColor = Colors.white;
        break;
      case "warning":
        bgColor = Colors.yellow.shade600;
        textColor = Colors.black87;
        break;
      case "error":
        bgColor = Colors.red.shade600;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.blue.shade600;
        textColor = Colors.white;
        break;
    }

    context ??= appContext;
    final widget = GestureDetector(
      onTap: () {
        appNavigator.pop();
        if (onTap != null) {
          onTap();
        }
      },
      child: Text(properties.getText(message, "errorMessage")),
    );

    showGeneralDialog(
      context: context,
      barrierLabel: "",
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
            child: AlertDialog(
          content: widget,
          contentTextStyle: TextStyle(color: textColor, fontSize: 15),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          alignment: Alignment.topCenter,
          backgroundColor: bgColor,
          elevation: 5,
        ));
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, -0.2), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
    );
  }

  /// Builds a confirmation dialog with a given [title] and [message].
  Future<bool> showConfirmation(
      {String? title,
      String? message,
      Map? props,
      BuildContext? context}) async {
    if (title == null && message == null) {
      return true;
    }

    final attributes = Map<String, dynamic>.from(props?["attributes"] ?? {});
    final titleText = title != null
        ? Text(properties.getText(title, "dialogTitle", attributes: attributes))
        : null;
    final content = message != null
        ? Text(properties.getText(message, "message", attributes: attributes))
        : null;
    final result = await showDialog<bool>(
        context: context ?? appContext,
        builder: (context) {
          return AlertDialog(
            title: titleText,
            content: content,
            actions: [
              TextButton(
                  child: Text(properties.getText("no", "dialogButton")),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                  child: Text(properties.getText("yes", "dialogButton")),
                  onPressed: () => Navigator.of(context).pop(true)),
            ],
          );
        });

    return result ?? false;
  }

  /// Shows the activity indicator.
  void showActivityIndicator({BuildContext? context, Map? props}) {
    if (activityIndicatorRoute != null) {
      return;
    }

    activityIndicatorRoute = DialogRoute(
      context: context ?? appContext,
      builder: (context) => buildActivityIndicator(context),
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
    );
    appNavigator.push(activityIndicatorRoute!);
  }

  /// Hides the activity indicator.
  void hideActivityIndicator() {
    if (activityIndicatorRoute != null) {
      if (activityIndicatorRoute!.canPop) {
        appNavigator.removeRoute(activityIndicatorRoute!);
      }
      activityIndicatorRoute = null;
    }
  }

  /// Builds the generic activity indicator used throughout the app.
  Widget buildActivityIndicator(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Sanitizes the properties of a [spec] using [template] and string evaluation.
  /// E.g.: a property valued "${state.firstName}" will have its value replaced with the [state]'s "firstName" key value.
  @protected
  void mergeTemplateAndState(
      WidgetNodeSpec spec, Map template, Map state, Map parentContext) {
    properties.evaluateMap(spec.props, parentContext);
    var newTemplate = template.clone();
    properties.evaluateMap(newTemplate, parentContext);

    // Use Template to set Property values, if not existing
    mergeMaps(spec.props, newTemplate);

    // Set Widget's value via its alias
    var alias = spec.props["alias"] ?? spec.id;
    if (state.containsKey(alias)) {
      spec.props["value"] = state[alias];
    } else if (spec.props.containsKey("value")) {
      state[alias] = spec.props["value"];
    }

    // Evaluate State keys starting with Widget's Id
    for (var key in state.keys) {
      if (key.startsWith("${spec.id}.")) {
        var prop = key.replaceFirst("${spec.id}.", "");
        var value = state[key];
        dynamic evaluatedValue;
        if (value is Map) {
          evaluatedValue =
              properties.evaluateValue(value.clone(), parentContext);
        } else if (value is List<Map>) {
          evaluatedValue =
              properties.evaluateValue(value.clone(), parentContext);
        } else {
          evaluatedValue = properties.evaluateValue(value, parentContext);
        }
        spec.props[prop] = evaluatedValue;
        if (value is Map || value is List<Map>) {
          // Since we don't know where the key belongs, we'll set it in all Spec Maps
          // Only properties should be evaluated in build-time
          spec.widgets[prop] = value;
          spec.actions[prop] = value;
        }
      }
    }
  }

  /// Utility method to merge two Maps.
  void mergeMaps(Map map1, Map map2) {
    for (var key in map2.keys) {
      var map1Value = map1[key];
      var map2Value = map2[key];

      if (map2Value is Map) {
        if (map1Value == null) {
          map1Value = {};
          map1[key] = map1Value;
        }
        mergeMaps(map1Value, map2Value);
      } else if (map1Value == null) {
        map1[key] = map2Value;
      }
    }
  }

  /// Returns the Template node with the given [id] from the Model.
  Map getTemplate(String? id) {
    if (id == null) {
      return {};
    }
    final finalTemplate = {};
    var template = Schema.getTemplate(id);
    while (template != null) {
      var props = template.props.clone();
      mergeMaps(finalTemplate, props);
      id = template.template;
      if (id == null) {
        break;
      }
      template = Schema.getTemplate(id);
    }
    return finalTemplate;
  }

  /// Convenience method returning a generic validator for string input Widgets.
  StringValueValidationFunction getStringValidator(Map spec) {
    var required = parseBool(spec["required"]);
    final minLength = parseInt(spec["minLength"]);
    final maxLength = parseInt(spec["maxLength"]);
    if (minLength > 0) {
      required = true;
    }

    final requiredText = Lowder.properties.getText(
        spec["requiredMessage"] ?? "required_field_message", "errorMessage");
    final minLengthText = Lowder.properties.getText(
        spec["minLengthMessage"] ?? "_minimum_length_message_", "errorMessage",
        attributes: {"length": minLength});
    final maxLengthText = Lowder.properties.getText(
        spec["maxLengthMessage"] ?? minLength == maxLength
            ? "_exact_length_message_"
            : "_maximum_length_message_",
        "errorMessage",
        attributes: {"length": maxLength});

    final regex = spec["regex"] != null ? RegExp(spec["regex"]) : null;
    final regexMessage = Lowder.properties.getText(
        spec["regexMessage"] ?? "invalid_value_message", "errorMessage");

    return (value) {
      var valueLength = value?.length ?? 0;
      if (valueLength == 0) {
        if (required) return requiredText;
        return null;
      }
      if (valueLength < minLength) {
        if (minLength == maxLength) {
          return maxLengthText;
        }
        if (valueLength > 0) {
          return minLengthText;
        }
        return requiredText;
      }
      if (maxLength > 0 && valueLength > maxLength) {
        return maxLengthText;
      }
      if (value != null && regex != null && !regex.hasMatch(value)) {
        return regexMessage;
      }
      return null;
    };
  }

  /// Convenience method returning a generic validator for bool input Widgets.
  CheckboxValidationFunction getCheckboxValidator(Map spec) {
    var required = parseBool(spec["required"]);
    var requiredText = Lowder.properties.getText(
        spec["requiredMessage"] ?? "required_field_message", "errorMessage");

    return (value) {
      if (required && (value == null || !value)) {
        return requiredText;
      }
      return null;
    };
  }

  /// Returns a Map with the evaluation context used when sanitizing properties of a [NodeSpec].
  /// Used to resolve properties that use placeholders as values, like "${state.firstName}" or "${env.api_uri}".
  Map getEvaluatorContext(Object? value, Map state, Map? specContext) =>
      Lowder.properties.getEvaluatorContext(value, state, specContext);
}

typedef StringValueValidationFunction = String? Function(String? value);
typedef CheckboxValidationFunction = String? Function(bool? value);

/// A structure containing contextual objects for a Widget's build.
class BuildParameters {
  /// The [BuildContext] from where the build function was triggered.
  final BuildContext context;

  /// The Model object representing the Widget Node.
  final WidgetNodeSpec spec;

  /// The existing state of the Screen from which the build was triggered.
  final Map state;

  /// An optional Map containing contextual values.
  /// E.g. Lists will set an "entry" attribute as context, referring an element from the array of data.
  final Map? parentContext;

  BuildParameters(this.context, this.spec, this.state, this.parentContext);

  String get id => spec.id;
  Map get props => spec.props;
  Map get actions => spec.actions;
  Map get widgets => spec.widgets;

  /// Convenience method to resolve the value of a property.
  dynamic buildProp(String key, {dynamic argument}) =>
      spec.buildProp(key, argument: argument);
}

/// Dummy Widget returned when a BuildCondition is false
class NoWidget extends SizedBox {
  const NoWidget({super.key});
}
