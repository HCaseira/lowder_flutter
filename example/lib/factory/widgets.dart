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
