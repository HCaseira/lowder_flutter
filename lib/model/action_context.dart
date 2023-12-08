import 'package:flutter/widgets.dart';

class ActionContext {
  final Map state;
  final Map actionContext;
  final dynamic actionValue;
  final BuildContext buildContext;

  ActionContext(this.state, this.actionContext, this.actionValue, this.buildContext);
}

class ActionResult {
  final bool success;
  final dynamic returnData;
  final Map? nextAction;

  ActionResult(this.success, {this.returnData, this.nextAction});
}

class SilentActionResult extends ActionResult {
  SilentActionResult(super.success, {super.returnData, super.nextAction});
}

class HttpActionResult extends ActionResult {
  HttpActionResult(super.success, {super.returnData, super.nextAction});
}

class GlobalActionResult extends ActionResult {
  GlobalActionResult(super.success, {super.returnData, super.nextAction});
}

class RetryAction {
  final bool retry;
  RetryAction(this.retry);
}
