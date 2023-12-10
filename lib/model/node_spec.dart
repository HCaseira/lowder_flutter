import 'dart:developer';
import '../util/extensions.dart';
import '../widget/lowder.dart';

/// Class representing a Model's Node.
class NodeSpec {
  final String type;
  final Map props;
  final Map actions;

  String? get id => props["_id"];

  NodeSpec(this.type, this.props, {this.actions = const {}});

  NodeSpec clone() {
    return NodeSpec(type, props.clone(), actions: actions.clone());
  }

  factory NodeSpec.fromMap(Map spec) {
    final specClone = spec.clone();
    return NodeSpec(
      specClone.remove("_type"),
      specClone.remove("properties") ?? {},
      actions: specClone.remove("actions") ?? {},
    );
  }
}

/// Class representing a Model's RootNode like a Screen, Template, Component, etc.
class RootNodeSpec extends NodeSpec {
  @override
  final String id;
  final String? name;
  RootNodeSpec(this.id, this.name, super.type, super.props, {super.actions});

  factory RootNodeSpec.fromMap(Map spec) {
    final specClone = spec.clone();
    return RootNodeSpec(
      specClone.remove("_id") ?? "",
      specClone.remove("name"),
      specClone.remove("_type"),
      specClone.remove("properties") ?? {},
      actions: specClone.remove("actions") ?? {},
    );
  }

  @override
  RootNodeSpec clone() {
    return RootNodeSpec(id, name, type, props.clone(),
        actions: actions.clone());
  }
}

/// Class representing a Model's Widget Node.
class WidgetNodeSpec extends RootNodeSpec {
  final String? template;
  final Map widgets;
  final Map extra;

  WidgetNodeSpec(String id, String? name, String type, this.template, Map props,
      Map actions, this.widgets, this.extra)
      : super(id, name, type, props, actions: actions);

  dynamic buildProp(String key, {dynamic argument}) {
    final properties = Lowder.widgets.getPropertySchema(type);
    if (properties[key] == null) {
      log("No builder for key $key ($type)");
      return null;
    }
    return properties[key]!.build(props[key], argument: argument);
  }

  @override
  WidgetNodeSpec clone() {
    final spec = extra.clone()
      ..addAll({
        "_id": id,
        "name": name,
        "_type": type,
        "_template": template,
        "properties": props.clone(),
        "actions": actions.clone(),
        "widgets": widgets.clone(),
      });
    return WidgetNodeSpec.fromMap(spec);
  }

  factory WidgetNodeSpec.fromMap(Map spec) {
    final specClone = spec.clone();
    return WidgetNodeSpec(
      specClone.remove("_id") ?? "",
      specClone.remove("name"),
      specClone.remove("_type"),
      specClone.remove("_template"),
      specClone.remove("properties") ?? {},
      specClone.remove("actions") ?? {},
      specClone.remove("widgets") ?? {},
      specClone,
    );
  }
}

/// Class representing a Model's Action Node.
class ActionNodeSpec extends RootNodeSpec {
  ActionNodeSpec(super.id, super.name, super.type, super.props, Map actions)
      : super(actions: actions);

  @override
  ActionNodeSpec clone() {
    return ActionNodeSpec(id, name, type, props.clone(), actions.clone());
  }

  Map toMap() {
    return {
      "_id": id,
      "name": name,
      "_type": type,
      "properties": props.clone(),
      "actions": actions.clone(),
    };
  }

  factory ActionNodeSpec.fromMap(Map spec) {
    final specClone = spec.clone();
    return ActionNodeSpec(
      specClone.remove("_id") ?? "",
      specClone.remove("name"),
      specClone.remove("_type"),
      specClone.remove("properties") ?? {},
      specClone.remove("actions") ?? {},
    );
  }
}
