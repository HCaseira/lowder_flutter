# Flutter Lowder Demo

This is a demo of a 'Flutter Lowder' app.

```dart
import 'package:flutter/material.dart';
import 'package:lowder/factory/action_factory.dart';
import 'package:lowder/factory/property_factory.dart';
import 'package:lowder/factory/widget_factory.dart';
import 'package:lowder/widget/lowder.dart';
import 'factory/actions.dart';
import 'factory/properties.dart';
import 'factory/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DemoApp());
}

class DemoApp extends Lowder {
  DemoApp({super.environment, super.editorMode, super.editorServer, super.key})
      : super("Demo Solution");

  @override
  AppState createState() => _DemoAppState();
  @override
  WidgetFactory createWidgetFactory() => SolutionWidgets();
  @override
  ActionFactory createActionFactory() => SolutionActions();
  @override
  PropertyFactory createPropertyFactory() => SolutionProperties();

  @override
  List<SolutionSpec> get solutions => [
        SolutionSpec(
          "Demo Solution",
          filePath: "assets/solution.low",
          widgets: SolutionWidgets(),
          actions: SolutionActions(),
          properties: SolutionProperties(),
        ),
      ];

  @override
  getTheme() => ThemeData.dark(useMaterial3: true);
}

class _DemoAppState extends AppState with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

## Registering new Widgets

Below is an example of how to make new Widgets available to the Editor.

Here we're registering a new Widget named "EditableText", with the resolver function "buildEditableText", and four properties named "alias", "value", "style" and "editableStyle".
The resolver will build a [StatefulBuilder] that can switch from a [Text] to a [TextFormField], so the user can edit its value.

The "alias" property refers to a key on the Screen's `state` Map for obtaining and storing its value.
The "value" property sets the Widget's initial value.
The "style" and "editableStyle" properties enables style customization for the [Text] and [TextFormField] widgets.

```dart
import 'package:flutter/material.dart';
import 'package:lowder/factory/widgets.dart';
import 'package:lowder/factory/widget_factory.dart';
import 'package:lowder/model/editor_node.dart';

class SolutionWidgets extends WidgetFactory with IWidgets {
  @override
  void registerWidgets() {
    registerWidget("EditableText", buildEditableText, properties: {
      "alias": Types.string,
      "value": Types.string,
      "style": Types.textStyle,
      "editableStyle": Types.textStyle,
    });
  }

  Widget buildEditableText(BuildParameters params) {
    bool editable = false;
    final style = Types.textStyle.build(params.props["style"]);
    final editableStyle = Types.textStyle.build(params.props["editableStyle"]);
    final alias = params.props["alias"] ?? params.id;
    final value = "${params.props["value"] ?? ""}";
    final controller = TextEditingController()..text = value;

    return StatefulBuilder(builder: (context, setState) {
      Widget child;
      if (!editable) {
        child = Text(controller.text, style: style);
      } else {
        child = TextFormField(
          controller: controller,
          style: editableStyle ?? style,
          onSaved: (val) {
            if (alias != null) {
              params.state[alias] = val;
            }
          },
        );
      }

      return Row(
        children: [
          Expanded(child: child),
          if (!editable)
            InkWell(
              onTap: () => setState(() => editable = !editable),
              child: const Icon(Icons.edit),
            )
        ],
      );
    });
  }
}
```

## Registering new Actions

Below is an example of how to make new Actions available to the Editor.

Here we're registering a new Action named "Math", with the resolver function "onMath", and three properties named "input", "operation" and "value".
Both "input" and "value" are double, while "operation" is a set of possible values.
The resolver will execute an addition, subtraction, multiplication, or division using the "input" and "value" values and return the result. 

```dart
import 'package:lowder/factory/actions.dart';
import 'package:lowder/factory/action_factory.dart';
import 'package:lowder/model/action_context.dart';
import 'package:lowder/model/editor_node.dart';
import 'package:lowder/model/node_spec.dart';
import 'package:lowder/util/parser.dart';

class SolutionActions extends ActionFactory with IActions {
  @override
  void registerActions() {
    registerAction("Math", onMath, properties: {
      "input": Types.double,
      "operation": const EditorPropertyListType(
          ["add", "subtract", "multiply", "divide"]),
      "value": Types.double
    });
  }

  Future<ActionResult> onMath(
      NodeSpec action, ActionContext context) async {
    final input = parseDouble(action.props["input"]);
    final value = parseDouble(action.props["value"]);
    late double result;
    switch (action.props["operation"] ?? "") {
      case "add":
        result = input + value;
        break;
      case "subtract":
        result = input - value;
        break;
      case "multiply":
        result = input * value;
        break;
      case "divide":
        result = input / value;
        break;
      default:
        ActionResult(false);
    }

    return ActionResult(true, returnData: result);
  }
}
```

## Registering new Properties

Below is an example of how to make new Properties available to the Editor.

Here we're registering a new Property named "BorderSide", with the resolver function "getBorderSide", and two properties named "color" and "width".

The "color" value sets the color of the [BorderSide].
The "width" value sets the width of the [BorderSide].

```dart
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

  BorderSide? getBorderSide(Map? spec) {
    if (spec == null || spec.isEmpty) {
      return null;
    }

    return BorderSide(
      color: parseColor(spec["color"], defaultColor: Colors.black),
      width: parseDouble(spec["width"], defaultValue: 1.0),
    );
  }
}
```

Now a Widget can use this property like this:
```dart
registerWidget("DemoWidget", (params) {
    return Container(
        width: params.buildProp("width"),
        height: params.buildProp("height"),
        color: params.buildProp("color"),
        decoration: BoxDecoration(
            border: Border.fromBorderSide(params.buildProp("borderSide"))),
    );
}, properties: {
    "width": Types.double,
    "height": Types.double,
    "color": Types.color,
    "borderSide": const EditorPropertyType("BorderSide"),
});
```

## String Evaluation

A value of a property can be a reference to objects within an evaluation context.

String evaluation occurs upon building a Widget or an Action, in which each of the Node's properties will be sanitized.

### How to refer to an object

An object can be refered using a syntax like `${state.address}`. In this case we're referring to the key `address` of the Screen's `state` Map.

### What objects exist during evaluation

Some of the objects are:

* `env`: refers to the Model's `environment variables`, managed in the editor. E.g. `${env.api_url}`.

* `global`: refers to a static Map accessible via `Lowder.globalVariables` where global key/value pairs can be stored, like the users profile or an access token. E.g. `${global.user.name}`.

* `state`: refers to a Map each Screen has where its state is stored. E.g. `${state.email}`.

* `media`: a Map containing some media properties like `isWeb`, `isMobile`, `isAndroid`, `portrait`, etc.

* `entry`: available only when working with a List, where upon building each row, the `entry` object will be available referring to an element of the array of data. `${entry.firstName} ${entry.lastName}`.

Feel free to make your own objects available during evaluation by overriding the method `getEvaluatorContext` of the `PropertyFactory`.
