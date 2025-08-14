import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_event.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../factory/widget_factory.dart';
import '../model/action_context.dart';
import '../model/node_spec.dart';
import '../model/solution_exception.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../widget/lowder.dart';
import '../widget/screen.dart';
import 'actions.dart';
import 'property_factory.dart';

typedef ActionFunction = void Function();
typedef ActionValueFunction<T> = void Function(T value);

/// Class that handles Action related operations.
class ActionFactory {
  final log = Logger("ActionFactory");
  final Map<String, dynamic> _actionExecutors = {};
  final Map<String, PageLoadFunction> _pageLoadExecutors = {};

  WidgetFactory get widgets => Lowder.widgets;
  PropertyFactory get properties => Lowder.properties;
  BuildContext get appContext => Lowder.navigatorKey.currentContext!;
  NavigatorState get appNavigator =>
      Navigator.of(appContext, rootNavigator: true);

  LocalBloc createLocalBloc() => LocalBloc(InitialState());
  ListBloc createListBloc() => ListBloc(InitialState());

  /// Schema loading
  @nonVirtual
  void loadActions(IActions actions) {
    _actionExecutors.addAll(actions.executors);
    _pageLoadExecutors.addAll(actions.pageLoadExecutors);
  }

  /// Returns a [Function] for a give Action [type].
  Function? getResolver(String type) {
    return _actionExecutors[type];
  }

  /// Returns a [PageLoadFunction] for a give PageAction [type].
  PageLoadFunction? getPageLoadResolver(String type) {
    return _pageLoadExecutors[type];
  }

  /// Returns a [ActionFunction] that executes an Action based on it's [actionSpec].
  ActionFunction? getFunction(BuildContext context, dynamic actionSpec,
      Map state, Map? evaluatorContext) {
    if (actionSpec == null) return null;
    if (EditorBloc.editMode) return () {};
    if (actionSpec is ActionFunction) return actionSpec;

    final nodeSpec =
        actionSpec is NodeSpec ? actionSpec : NodeSpec.fromMap(actionSpec);

    return () {
      run(context, nodeSpec, state, null, evaluatorContext);
    };
  }

  /// Returns a [ActionValueFunction<T>] that executes an Action based on it's [actionSpec].
  ActionValueFunction<T>? getValueFunction<T>(BuildContext context,
      dynamic actionSpec, Map state, Map? evaluatorContext) {
    if (actionSpec == null) return null;
    if (EditorBloc.editMode) return (v) {};
    if (actionSpec is ActionValueFunction<Object?>) return actionSpec;

    final nodeSpec =
        actionSpec is NodeSpec ? actionSpec : NodeSpec.fromMap(actionSpec);

    return (val) {
      if (actionSpec != null) {
        run(context, nodeSpec, state, val, evaluatorContext);
      }
    };
  }

  /// Executes a [PageLoadFunction]
  void executePageLoadAction(
      BuildContext buildContext,
      ListBloc bloc,
      int page,
      int pageSize,
      List fullData,
      Map? actionSpec,
      Map state,
      Map? actionContext,
      {dynamic value}) {
    if (actionSpec == null) {
      return;
    }

    NodeSpec action = NodeSpec.fromMap(actionSpec);
    final props = action.props;
    final actionCtx = <dynamic, dynamic>{
      "page": page,
      "pageSize": pageSize,
    }..addAll(actionContext ?? {});

    final evaluatorContext = getEvaluatorContext(value, state, actionCtx);
    properties.evaluateMap(props, evaluatorContext);

    if (props["executeCondition"] != null &&
        !properties.evaluateCondition(props["executeCondition"])) {
      return;
    }

    final context =
        ActionContext(state, actionContext ?? {}, value, buildContext);
    final event =
        LoadPageActionEvent(action, context, page, pageSize, fullData);
    bloc.add(event);
  }

  /// Starts the execution of an [action]
  @nonVirtual
  Future<void> run(BuildContext buildContext, NodeSpec action, Map state,
      Object? eventValue, Map? actionContext) async {
    if (!await preRun(buildContext, action.props)) {
      return;
    }
    if (!buildContext.mounted) {
      log.severe("BuildContext is not mounted after preRun.");
      return;
    }

    final runState = actionContext ?? {};
    var currentValue = eventValue;
    NodeSpec? currentAction = action.clone();

    while (currentAction != null) {
      if (!buildContext.mounted) {
        log.severe(
            "BuildContext is not mounted while trying to execute Action '${currentAction.type}' (${currentAction.id})");
        return;
      }

      final context =
          ActionContext(state.clone(), runState, currentValue, buildContext);
      if (!await preExecute(currentAction, context)) {
        break;
      }

      final result = await execute(currentAction, context);
      currentAction = await postExecute(currentAction, result, context);
      currentValue = result.returnData;
    }
    onExecuted();
  }

  /// An initial run of validations upon starting a [run].
  /// E.g.: form validation.
  @protected
  Future<bool> preRun(BuildContext context, Map actionProps) async {
    try {
      final form =
          LowderScreen.of(context)?.formKey.currentState ?? Form.of(context);
      form.save();
      if (parseBool(actionProps["validateForm"]) && !form.validate()) {
        return false;
      }
    } catch (e) {
      // log("[$runtimeType] Form not found.");
    }
    return true;
  }

  /// An initial run of validations before executing an Action.
  /// E.g.: a confirmation message like "Are you sure you want to delete this record?".
  @protected
  Future<bool> preExecute(NodeSpec action, ActionContext context) async {
    final props = action.props;
    final evaluatorContext = getEvaluatorContext(
        context.actionValue, context.state, context.actionContext);
    properties.evaluateMap(props, evaluatorContext);

    if (props["executeCondition"] != null &&
        !properties.evaluateCondition(props["executeCondition"])) {
      log.warningWithContext(
          "Execute condition not met for Action '${action.type}' (${action.id}).",
          props["executeCondition"]);
      return false;
    }

    if (props["confirmation"] is Map) {
      final confirmSpec = props["confirmation"] as Map;
      return await widgets.showConfirmation(
        title: confirmSpec["title"],
        message: confirmSpec["message"],
        props: confirmSpec,
      );
    }

    log.infoWithContext(
        "Executing Action '${action.type}' (${action.id})",
        {}
          ..addAll({"action": props})
          ..addAll(evaluatorContext));
    return true;
  }

  /// The [action]'s actual execution.
  @nonVirtual
  Future<ActionResult> execute(NodeSpec action, ActionContext context) async {
    if (!context.buildContext.mounted) {
      log.severe("BuildContext is not mounted (${action.type})");
      return ActionResult(false);
    }

    final resolver = getResolver(action.type);
    if (resolver == null) {
      log.severe("Action resolver for '${action.type}' not found");
      return ActionResult(false);
    }

    if (!(resolver is ExecutorFunction<SilentActionResult> ||
        resolver is ExecutorFunction<SilentActionResult> ||
        parseBool(action.props["silent"]))) {
      onExecuting();
    }

    late ActionResult result;
    try {
      result = await resolver(action, context);
      log.infoWithContext("Action '${action.type}' executed successfully", {
        "returnData": result.returnData,
        "next": result.nextAction == null
            ? null
            : {
                "id": result.nextAction?["_id"],
                "type": result.nextAction?["_type"],
              }
      });
    } catch (e, stack) {
      log.severe("Error executing action '${action.type}'", e, stack);
      if ((await handleException(action, context, e)).retry) {
        return execute(action, context);
      }
      result = ActionResult(false);
    }
    onExecuted();
    return result;
  }

  /// Handles the [ActionResult] of an executed [action] and determines the next Action to be executed if any.
  @protected
  Future<NodeSpec?> postExecute(
      NodeSpec action, ActionResult result, ActionContext context) async {
    if (result.returnData != null || action.props["returnName"] != null) {
      final key = action.props["returnName"] ?? "value";
      context.actionContext[key] = result.returnData;
    }

    if (!result.success) {
      if (action.actions["onFailure"] is Map) {
        return NodeSpec.fromMap(action.actions["onFailure"]);
      }

      if (result.failureMessage != null && result.failureMessage!.isNotEmpty) {
        showErrorMessage(result.failureMessage!);
      }
      return null;
    }

    var nextActionSpec = result.nextAction;
    if (nextActionSpec == null && action.actions["nextAction"] != null) {
      nextActionSpec = action.actions["nextAction"];
    }
    return nextActionSpec != null ? NodeSpec.fromMap(nextActionSpec) : null;
  }

  /// Returns a Map with the evaluation context used when sanitizing properties of a [NodeSpec].
  /// Used to resolve properties that use placeholders as values, like "${state.firstName}" or "${env.api_uri}".
  Map getEvaluatorContext(Object? value, Map state, Map? specContext) =>
      Lowder.properties.getEvaluatorContext(value, state, specContext);

  /// Exception handling when executing an [action]
  Future<RetryAction> handleException(
      NodeSpec action, ActionContext context, Object e) async {
    if (e is SolutionException) {
      showErrorMessage(e.message);
    } else if (e is http.ClientException ||
        e is SocketException ||
        e is WebSocketException) {
      final title =
          Lowder.editorMode ? e.toString() : "communication_error_message";
      if (await widgets.showConfirmation(
          title: title, message: "try_again_question")) {
        return RetryAction(true);
      }
    } else if (Lowder.editorMode) {
      showErrorMessage(e.toString());
    } else {
      showErrorMessage("unknown_error_message");
    }
    return RetryAction(false);
  }

  /// Method used to make Http calls.
  /// Conveniently placed in this class to facilitate overrides.
  Future<HttpResponse> httpCall(Uri uri, String method,
      {Object? body, Map<String, String>? headers, Encoding? encoding}) async {
    http.Response response;
    switch (method) {
      case "post":
        response = await http.post(uri,
            body: body, headers: headers, encoding: encoding);
        break;
      case "put":
        response = await http.put(uri,
            body: body, headers: headers, encoding: encoding);
        break;
      case "patch":
        response = await http.patch(uri,
            body: body, headers: headers, encoding: encoding);
        break;
      case "delete":
        response = await http.delete(uri, headers: headers);
        break;
      default:
        response = await http.get(uri, headers: headers);
        break;
    }

    // Error message handling
    final responseBody = response.body;
    var reasonPhrase = response.reasonPhrase;
    if (!response.isSuccess && responseBody.isNotEmpty) {
      try {
        final map = json.decodeWithReviver(responseBody) as Map;
        reasonPhrase = map["reasonPhrase"] ??
            map["statusMessage"] ??
            map["statusText"] ??
            reasonPhrase;
      } catch (e) {/* Do nothing*/}
    }

    return HttpResponse(
      response.statusCode,
      responseBody,
      reasonPhrase: reasonPhrase,
      headers: response.headers,
      extra: {"response": response},
    );
  }

  /// Method used to handle Http errors.
  /// Conveniently placed in this class to facilitate overrides.
  Future<RetryAction> onHttpError(
      HttpResponse response, NodeSpec action, ActionContext context) async {
    if (response.statusCode == 401) {
      showErrorMessage("invalid_session_message");
    } else {
      showErrorMessage("communication_error_message");
    }
    return RetryAction(false);
  }

  /// Method used to handle a successful Http call.
  /// Conveniently placed in this class to facilitate overrides.
  HttpActionResult onHttpSuccess(
      HttpResponse response, NodeSpec action, ActionContext context) {
    final data = (response.headers[HttpHeaders.contentTypeHeader] ?? "")
            .contains("application/json")
        ? json.decodeWithReviver(response.body)
        : response.body;

    return HttpActionResult(true, returnData: data);
  }

  /// Method used to make Http calls.
  /// Conveniently placed in this class to facilitate overrides.
  Map<String, String> getHttpDefaultHeaders(
      {String? contentType, Map<String, String>? otherHeaders}) {
    final headers = <String, String>{};

    if (contentType != null && contentType.isNotEmpty) {
      headers["Content-Type"] = contentType;
    }

    final accessToken = Lowder.globalVariables["access_token"];
    if (accessToken != null && accessToken.isNotEmpty) {
      headers["Authorization"] = "Bearer $accessToken";
    }

    if (otherHeaders != null) {
      headers.addAll(otherHeaders);
    }

    return headers;
  }

  /// Method executed immediately before executing an Action.
  /// Launches an activity indicator.
  void onExecuting() => widgets.showActivityIndicator();

  /// Method executed after executing an Action.
  /// Removes an activity indicator.
  void onExecuted() => widgets.hideActivityIndicator();

  /// Convenience method to display an error method to the user.
  void showErrorMessage(String message) =>
      widgets.showMessage(type: "error", message: message);
}

/// Utility class to abstract the http client's response object.
class HttpResponse {
  final int statusCode;
  final String? reasonPhrase;
  final String body;
  final Map<String, String> headers;
  final Map<String, dynamic>? extra;

  HttpResponse(this.statusCode, this.body,
      {this.reasonPhrase, this.headers = const {}, this.extra});

  bool get isSuccess => (statusCode ~/ 100) == 2;
}
