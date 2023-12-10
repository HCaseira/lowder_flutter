import 'package:lowder/factory/actions.dart';
import 'package:lowder/factory/action_factory.dart';
import 'package:lowder/model/action_context.dart';
import 'package:lowder/model/editor_node.dart';
import 'package:lowder/model/node_spec.dart';
import 'package:lowder/util/parser.dart';

class SolutionActions extends ActionFactory with IActions {
  @override
  void registerActions() {
    registerSilentAction("Math", onMath, properties: {
      "input": Types.double,
      "operation": const EditorPropertyListType(
          ["add", "subtract", "multiply", "divide"]),
      "value": Types.double
    });
  }

  Future<SilentActionResult> onMath(
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
        SilentActionResult(false);
    }

    return SilentActionResult(true, returnData: result);
  }
}
