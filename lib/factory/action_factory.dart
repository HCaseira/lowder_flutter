import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../bloc/base_bloc.dart';
import '../bloc/base_event.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../factory/widget_factory.dart';
import '../model/action_context.dart';
import '../model/k_node.dart';
import '../model/solution.dart';
import '../model/solution_exception.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../widget/lowder.dart';
import '../widget/screen.dart';
import 'actions.dart';
import 'property_factory.dart';

typedef ActionFunction = void Function();
typedef ActionValueFunction<T> = void Function(T value);

class ActionFactory {
  final Map<String, dynamic> _actionExecutors = {};
  final Map<String, PageLoadFunction> _pageLoadExecutors = {};

  WidgetFactory get widgets => Lowder.widgets;
  PropertyFactory get properties => Lowder.properties;
  BuildContext get appContext => Lowder.navigatorKey.currentContext!;
  NavigatorState get appNavigator => Navigator.of(appContext, rootNavigator: true);

  LocalBloc createLocalBloc() => LocalBloc(InitialState());

  ListBloc createListBloc() => ListBloc(InitialState());

  @nonVirtual
  void loadActions(IActions actions) {
    _actionExecutors.addAll(actions.executors);
    _pageLoadExecutors.addAll(actions.pageLoadExecutors);
  }

  Function? getResolver(String type) {
    return _actionExecutors[type];
  }

  PageLoadFunction? getPageLoadResolver(String type) {
    return _pageLoadExecutors[type];
  }

  ActionFunction? getFunction(BuildContext context, dynamic actionSpec, Map state, Map? evaluatorContext) {
    if (actionSpec == null) return null;
    if (EditorBloc.editMode) return () {};
    if (actionSpec is ActionFunction) return actionSpec;

    final nodeSpec = actionSpec is NodeSpec ? actionSpec : NodeSpec.fromMap(actionSpec);

    return () {
      run(context, nodeSpec, state, null, evaluatorContext);
    };
  }

  ActionValueFunction<T>? getValueFunction<T>(BuildContext context, dynamic actionSpec, Map state, Map? evaluatorContext) {
    if (actionSpec == null) return null;
    if (EditorBloc.editMode) return (v) {};
    if (actionSpec is ActionValueFunction<Object?>) return actionSpec;

    final nodeSpec = actionSpec is NodeSpec ? actionSpec : NodeSpec.fromMap(actionSpec);

    return (val) {
      if (actionSpec != null) {
        run(context, nodeSpec, state, val, evaluatorContext);
      }
    };
  }

  void executePageLoadAction(BuildContext buildContext, ListBloc bloc, int page, int pageSize, List fullData,
      Map? actionSpec, Map state, Map? actionContext,
      {dynamic value}) {
    if (actionSpec == null) {
      return;
    }

    NodeSpec action = NodeSpec.fromMap(actionSpec);
    final props = action.props;
    final evaluatorContext = getEvaluatorContext(value, state, actionContext);
    properties.evaluateMap(props, evaluatorContext);

    if (props["executeCondition"] != null && !properties.evaluateCondition(props["executeCondition"])) {
      return;
    }

    final context = ActionContext(state, actionContext ?? {}, value, buildContext);
    final event = LoadPageActionEvent(action, context, page, pageSize, fullData);
    bloc.add(event);
  }

  @nonVirtual
  Future<void> run(BuildContext buildContext, NodeSpec action, Map state, Object? eventValue, Map? actionContext) async {
    if (!await preRun(buildContext, action.props)) {
      return;
    }
    if (!buildContext.mounted) {
      logError("[$runtimeType] Error: BuildContext is not mounted after preRun.");
      return;
    }

    var currentValue = eventValue;
    NodeSpec? currentAction = action;
    while (currentAction != null) {
      if (!buildContext.mounted) {
        logError("[$runtimeType] Error: BuildContext is not mounted while trying to execute Action ${currentAction.id}");
        return;
      }

      final context = ActionContext(state, actionContext ?? {}, currentValue, buildContext);
      if (!await preExecute(currentAction, context)) {
        break;
      }

      final result = await execute(currentAction, context);
      currentAction = await postExecute(currentAction, result, context);
      currentValue = result.returnData;
    }
    onExecuted();
  }

  @protected
  Future<bool> preRun(BuildContext context, Map actionProps) async {
    try {
      final form = LowderScreen.of(context)?.formKey.currentState ?? Form.of(context);
      form.save();
      if (parseBool(actionProps["validateForm"]) && !form.validate()) {
        return false;
      }
    } catch (e) {
      log("[$runtimeType] Form not found.");
    }
    return true;
  }

  @protected
  Future<bool> preExecute(NodeSpec action, ActionContext context) async {
    final props = action.props;
    final evaluatorContext = getEvaluatorContext(context.actionValue, context.state, context.actionContext);
    properties.evaluateMap(props, evaluatorContext);

    if (props["executeCondition"] != null && !properties.evaluateCondition(props["executeCondition"])) {
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

    return true;
  }

  @nonVirtual
  Future<ActionResult> execute(NodeSpec action, ActionContext context) async {
    if (!context.buildContext.mounted) {
      logError("[$runtimeType] Error: BuildContext is not mounted (${action.type})");
      return ActionResult(false);
    }

    final resolver = getResolver(action.type);
    if (resolver == null) {
      logError("[$runtimeType] Error: Action resolver for '${action.type}' not found");
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
    } catch (e, stack) {
      logError("[$runtimeType] Error executing action '${action.type}'", stackTrace: stack, error: e);
      if ((await handleException(action, context, e)).retry) {
        return execute(action, context);
      }
      result = ActionResult(false);
    }
    onExecuted();
    return result;
  }

  @protected
  Future<NodeSpec?> postExecute(NodeSpec action, ActionResult result, ActionContext context) async {
    if (result.returnData != null || action.props["returnName"] != null) {
      final key = action.props["returnName"] ?? "value";
      context.state[key] = result.returnData;
    }

    // if (result.emitStates != null) {
    //   for (var state in result.emitStates!) {
    //     GlobalBloc.emitState(ActionState(state));
    //   }
    // }

    if (!result.success) {
      return null;
    }

    var nextActionSpec = result.nextAction;
    if (nextActionSpec == null && action.actions["nextAction"] != null) {
      nextActionSpec = action.actions["nextAction"];
    }
    return nextActionSpec != null ? NodeSpec.fromMap(nextActionSpec) : null;
  }

  Map getEvaluatorContext(Object? value, Map state, Map? specContext) {
    final mediaQueryData = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.single);

    final map = {};
    if (specContext != null) map.addAll(specContext);
    map.addAll({
      "null": null,
      "languages": Solution.languages,
      "language": Solution.language,
      "env": Solution.environmentVariables,
      "global": Lowder.globalVariables,
      "state": state,
      "value": value,
      "media": {
        "isWeb": kIsWeb,
        "isMobile": !kIsWeb && mediaQueryData.size.shortestSide < 600,
        "isTablet": !kIsWeb && mediaQueryData.size.shortestSide >= 600,
        "isAndroid": kIsWeb ? false : Platform.isAndroid,
        "isIOS": kIsWeb ? false : Platform.isIOS,
        "isWindows": kIsWeb ? false : Platform.isWindows,
        "isMacOS": kIsWeb ? false : Platform.isMacOS,
        "isLinux": kIsWeb ? false : Platform.isLinux,
        "isFuchsia": kIsWeb ? false : Platform.isFuchsia,
        "portrait": mediaQueryData.orientation == Orientation.portrait,
        "landscape": mediaQueryData.orientation == Orientation.landscape,
        // "version": Platform.version,
      }
    });
    return map;
  }

  Future<RetryAction> handleException(NodeSpec action, ActionContext context, Object e) async {
    if (kDebugMode) print("Error executing action ${action.type}: $e");
    if (e is SolutionException) {
      showErrorMessage(e.message);
    } else if (e is http.ClientException || e is SocketException || e is WebSocketException) {
      final title = Lowder.editorMode ? e.toString() : "communication_error_message";
      if (await widgets.showConfirmation(title: title, message: "try_again_question")) {
        return RetryAction(true);
      }
    } else if (Lowder.editorMode) {
      showErrorMessage(e.toString());
    } else {
      showErrorMessage("unknown_error_message");
    }
    return RetryAction(false);
  }

  Future<http.Response> httpCall(Uri uri, String method,
      {Object? body, Map<String, String>? headers, Encoding? encoding}) async {
    switch (method) {
      case "post":
        return await http.post(uri, body: body, headers: headers, encoding: encoding);
      case "put":
        return await http.put(uri, body: body, headers: headers, encoding: encoding);
      case "patch":
        return await http.patch(uri, body: body, headers: headers, encoding: encoding);
      case "delete":
        return await http.delete(uri, body: body, headers: headers, encoding: encoding);
      default:
        return await http.get(uri, headers: headers);
    }
  }

  Future<RetryAction> onHttpError(http.Response response, NodeSpec action, ActionContext context) async {
    if (response.statusCode == 401) {
      showErrorMessage("invalid_session_message");
    } else {
      showErrorMessage("communication_error_message");
    }
    return RetryAction(false);
  }

  HttpActionResult onHttpSuccess(http.Response response, NodeSpec action, ActionContext context) {
    final data = (response.headers[HttpHeaders.contentTypeHeader] ?? "").contains("application/json")
        ? json.decodeWithReviver(response.body)
        : response.body;

    return HttpActionResult(true, returnData: data);
  }

  Map<String, String> getHttpDefaultHeaders({String? contentType, Map<String, String>? otherHeaders}) {
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

  void onExecuting() => widgets.showActivityIndicator();
  void onExecuted() => widgets.hideActivityIndicator();
  void showErrorMessage(String message) => widgets.showMessage(type: "error", message: message);

  logError(String message, {Object? error, StackTrace? stackTrace, Type? originClass}) {
    log("[${originClass ?? runtimeType}] Error: $message", error: error, stackTrace: stackTrace);
    if (kDebugMode || Lowder.editorMode) {
      showErrorMessage(message);
    }
  }
}
