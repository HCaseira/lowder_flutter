import 'package:flutter/widgets.dart';

/// A structure containing contextual objects for an Action's execution.
class ActionContext {
  final Map state;
  final Map actionContext;
  final dynamic actionValue;
  final BuildContext buildContext;

  ActionContext(
      this.state, this.actionContext, this.actionValue, this.buildContext);
}

/// A class to return an Action's execution result.
/// [success] - a boolean indicating if an Action was successfully executed.
/// [returnData] - an optional data to be returned from the Action's execution.
/// [nextAction] - an optional Map with an Action specification (e.g.: an 'IfAction' evaluates a condition
/// and either the 'true' Action or the 'false' Action will be returned).
class ActionResult {
  final bool success;
  final dynamic returnData;
  final Map? nextAction;

  ActionResult(this.success, {this.returnData, this.nextAction});
}

/// An [ActionResult] variation, indicating ActionFactory that an 'action indicator' should not be displayed.
class SilentActionResult extends ActionResult {
  SilentActionResult(super.success, {super.returnData, super.nextAction});
}

/// An [ActionResult] variation, indicating ActionFactory that in case of error, a Http error handling should be called.
/// E.g.: give oportunity to renew an expired access token.
class HttpActionResult extends ActionResult {
  HttpActionResult(super.success, {super.returnData, super.nextAction});
}

/// A class used by ActionFactory to determine if a failed Action should by retried.
class RetryAction {
  final bool retry;
  RetryAction(this.retry);
}
