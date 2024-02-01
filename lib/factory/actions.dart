import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../bloc/base_bloc.dart';
import '../bloc/base_event.dart';
import '../bloc/base_state.dart';
import '../model/action_context.dart';
import '../model/editor_node.dart';
import '../model/node_spec.dart';
import '../model/solution.dart';
import '../schema.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../widget/lowder.dart';

typedef ExecutorFunction<R extends ActionResult> = FutureOr<R> Function(
    NodeSpec action, ActionContext context);
typedef PageLoadFunction<E extends LoadPageActionEvent,
        R extends PageLoadedState>
    = FutureOr<R> Function(E event);

/// An interface for registering a Solution's Actions.
mixin IActions {
  final Map<String, dynamic> _actionExecutors = {};
  final Map<String, PageLoadFunction> _pageLoadExecutors = {};
  final Map<String, EditorAction> _schema = {};

  Map<String, dynamic> get executors => _actionExecutors;
  Map<String, PageLoadFunction> get pageLoadExecutors => _pageLoadExecutors;
  Map<String, EditorAction> get schema => _schema;

  @nonVirtual
  Map<String, Map<String, dynamic>> getSchema() {
    var schema = <String, Map<String, dynamic>>{};
    for (var key in _schema.keys) {
      schema[key] = _schema[key]!.toJson();
    }
    return schema;
  }

  void registerActions();

  @nonVirtual
  void _registerAction(String name, dynamic executor, EditorAction schema) {
    _actionExecutors[name] = executor;
    _schema[name] = schema;
  }

  @nonVirtual
  void registerAction(
    String name,
    ExecutorFunction<ActionResult> executor, {
    bool abstract = false,
    String? baseType = EditorAction.action,
    Map<String, EditorPropertyType>? properties,
    Map<String, EditorActionType>? actions,
  }) {
    _registerAction(
      name,
      executor,
      EditorAction(
        abstract: abstract,
        baseType: baseType,
        properties: properties,
        actions: actions,
      ),
    );
  }

  @nonVirtual
  void registerSilentAction(
    String name,
    ExecutorFunction<SilentActionResult> executor, {
    bool abstract = false,
    String? baseType = EditorAction.action,
    Map<String, EditorPropertyType>? properties,
    Map<String, EditorActionType>? actions,
  }) {
    _registerAction(
      name,
      executor,
      EditorAction(
        abstract: abstract,
        baseType: baseType,
        properties: properties,
        actions: actions,
      ),
    );
  }

  @nonVirtual
  void registerHttpAction(
    String name,
    ExecutorFunction<HttpActionResult> executor, {
    bool abstract = false,
    String? baseType = EditorAction.action,
    Map<String, EditorPropertyType>? properties,
    Map<String, EditorActionType>? actions,
  }) {
    _registerAction(
      name,
      executor,
      EditorAction(
        abstract: abstract,
        baseType: baseType,
        properties: properties,
        actions: actions,
      ),
    );
  }

  @nonVirtual
  void registerLoadPageAction(
    String name,
    PageLoadFunction<LoadPageActionEvent, PageLoadedState> executor, {
    bool abstract = false,
    String? baseType = EditorAction.listAction,
    Map<String, EditorPropertyType>? properties,
    Map<String, EditorActionType>? actions,
  }) {
    _pageLoadExecutors[name] = executor;
    _schema[name] = EditorAction(
      abstract: abstract,
      baseType: baseType,
      properties: properties,
      actions: actions,
    );
  }
}

/// An empty implementation of [IActions] to be used when there are no Actions to declare.
class NoActions with IActions {
  @override
  void registerActions() {
    // No actions to register
  }
}

/// The Lowder's Action preset.
class BaseActions with IActions {
  final log = Logger("LowderActions");

  @override
  void registerActions() {
    registerAction(
        EditorAction.terminationAction, (_, __) => ActionResult(false),
        abstract: true,
        baseType: null,
        properties: {
          "validateForm": Types.bool,
          "silent": Types.bool,
          "confirmation": const EditorPropertyType("KConfirmMessage"),
          "executeCondition": Types.kCondition
        });
    registerAction(EditorAction.action, (_, __) => ActionResult(false),
        abstract: true,
        baseType: EditorAction.terminationAction,
        properties: {
          "returnName": Types.string,
        },
        actions: {
          "nextAction": EditorActionType.action(),
        });

    registerSilentAction("KActionMessage", onMessage,
        baseType: EditorAction.terminationAction,
        properties: {
          "type": const EditorPropertyListType(
              ["success", "warning", "error", "info"]),
          "message": Types.string,
        });

    registerSilentAction("KActionNavigate", onNavigate,
        baseType: EditorAction.terminationAction,
        properties: {
          "jumpToScreen": Types.screen,
          "replacePrevious": Types.bool,
          "replaceAll": Types.bool,
          "state": Types.json,
          "transition": Types.routeTransitionBuilder,
          "transitionDuration": Types.int
        },
        actions: {
          "onPop": EditorActionType.action()
        });
    registerSilentAction("KActionPop", onPop,
        baseType: EditorAction.terminationAction,
        properties: {
          "returnValue": Types.string,
          "returnMessage": Types.string,
          "returnMessageType": const EditorPropertyListType(
              ["success", "warning", "error", "info"])
        });
    registerSilentAction("KActionShowDialog", onShowDialog,
        baseType: EditorAction.terminationAction,
        properties: {
          "jumpToScreen": Types.screen,
          "state": Types.json,
          "barrierDismissible": Types.bool,
          "barrierColor": Types.color,
          "backgroundColor": Types.color,
          "padding": Types.intArray,
          "alignment": Types.alignment,
          "elevation": Types.int,
          "transition": Types.routeTransitionBuilder,
          "transitionDuration": Types.int
        },
        actions: {
          "onPop": EditorActionType.action()
        });

    registerSilentAction("BlocState", onBlocState, properties: {
      "name": Types.string,
      "type": const EditorPropertyListType(["local", "global"]),
      "data": Types.json,
    });
    registerSilentAction("KActionSetState", onSetState, properties: {
      "newState": Types.json,
    });
    registerSilentAction("KActionSetGlobalVar", onSetGlobalVar, properties: {
      "key": Types.string,
      "value": Types.string,
    });
    registerSilentAction("KActionIf", onIf,
        baseType: EditorAction.terminationAction,
        properties: {
          "condition": Types.kCondition
        },
        actions: {
          "onTrue": EditorActionType.action(),
          "onFalse": EditorActionType.action()
        });

    registerHttpAction("KActionRequest", onRequest, properties: {
      "request": Types.request,
    });
    registerHttpAction("KActionRest", onRest, properties: {
      "url": Types.string,
      "path": Types.string,
      "method": const EditorPropertyListType(
          ["get", "post", "put", "delete", "patch"]),
      "queryArgs": Types.json,
      "body": Types.json,
    });

    registerAction("KActionReload", onReload);
    registerAction("KActionReloadAll", onReloadAll);
    registerAction("SetLanguage", onSetLanguage,
        properties: {"language": Types.string});

    // registerAction("KActionLinkToAction", onLinkToAction, EditorAction(
    //   baseType: EditorAction.terminationAction,
    //   properties: {
    //     "action": const EditorPropertyType(EditorAction.action),
    //   },
    // ));

    registerAction(EditorAction.listAction, (_, __) => ActionResult(false),
        abstract: true, baseType: null);
    registerLoadPageAction("KListActionRequest", onLoadPageRequest,
        properties: {
          "request": Types.request,
          "arrayKey": Types.string,
          "isPaged": Types.bool,
        });
    registerLoadPageAction("KListActionRest", onLoadPageRest, properties: {
      "url": Types.string,
      "path": Types.string,
      "method": const EditorPropertyListType(
          ["get", "post", "put", "delete", "patch"]),
      "queryArgs": Types.json,
      "body": Types.json,
      "arrayKey": Types.string,
      "isPaged": Types.bool,
    });
    registerLoadPageAction("KListActionData", handleStaticData, properties: {
      "data": Types.json,
      "shuffle": Types.bool,
    });
    registerAction("ReloadList", onReloadList,
        baseType: EditorAction.action,
        properties: {
          "listId": Types.string,
        });
  }

  Future<PageLoadedState> onLoadPageRequest(LoadPageActionEvent event) async {
    final restSpec = transformRequestToRest(event.action, event.context);
    if (restSpec == null) {
      return PageLoadedState(event.page, event.fullData, false);
    }

    final restNode =
        NodeSpec(event.action.type, restSpec, actions: event.action.actions);
    final restEvent = LoadPageActionEvent(
        restNode, event.context, event.page, event.pageSize, event.fullData);
    return await onLoadPageRest(restEvent);
  }

  Future<PageLoadedState> onLoadPageRest(LoadPageActionEvent event) async {
    final props = event.action.props;
    final isPaged = parseBool(props["isPaged"], defaultValue: true);
    if (isPaged) {
      final queryArgs = props["queryArgs"] ?? {};
      queryArgs["page"] = event.page;
      queryArgs["pageSize"] = event.pageSize;
      props["queryArgs"] = queryArgs;
    }

    final result = await onRest(event.action, event.context);
    if (result.success) {
      var responseData = result.returnData;
      if (responseData is Map) {
        if (props["arrayKey"] != null) {
          responseData = responseData[props["arrayKey"]];
        } else {
          for (var key in responseData.keys) {
            if (responseData[key] is List) {
              responseData = responseData[key];
              break;
            }
          }
        }
      }

      if (responseData is List) {
        event.fullData.addAll(responseData);
        return PageLoadedState(event.page, event.fullData,
            isPaged && responseData.length == event.pageSize);
      }
    }

    return PageLoadedState(event.page, event.fullData, false);
  }

  PageLoadedState handleStaticData(LoadPageActionEvent event) {
    if (event.page > 1) {
      return PageLoadedState(event.page, event.fullData, false);
    }

    final List data = event.action.props["data"] ?? [];
    if (parseBool(event.action.props["shuffle"])) {
      data.shuffle();
    }
    return PageLoadedState(event.page, data, false);
  }

  Future<HttpActionResult> onRequest(
      NodeSpec action, ActionContext context) async {
    final restSpec = transformRequestToRest(action, context);
    if (restSpec == null) {
      return HttpActionResult(false);
    }
    return await onRest(
        NodeSpec(
          action.type,
          restSpec,
          actions: action.actions,
        ),
        context);
  }

  Future<HttpActionResult> onRest(
      NodeSpec action, ActionContext context) async {
    final spec = action.props;
    final uri = UriExtensions.buildUri(spec["url"],
        path: spec["path"], queryArgs: spec["queryArgs"]);

    final body = spec["body"] != null ? json.safeEncode(spec["body"]!) : null;
    final headers = Lowder.actions.getHttpDefaultHeaders(
      contentType: spec["body"] != null ? "application/json" : null,
      otherHeaders: spec["headers"],
    );

    var response = await Lowder.actions
        .httpCall(uri, spec["method"], body: body, headers: headers);
    if (!response.isSuccess) {
      if ((await Lowder.actions.onHttpError(response, action, context)).retry) {
        response = await Lowder.actions
            .httpCall(uri, spec["method"], body: body, headers: headers);
      }
    }

    if (response.isSuccess) {
      log.infoWithContext(
          "Success calling [${spec["method"]}] $uri", {"body": response.body});
      return Lowder.actions.onHttpSuccess(response, action, context);
    }
    log.info(
        "Failure calling [${spec["method"]}] $uri: ${response.statusCode}");
    return HttpActionResult(false);
  }

  Future<SilentActionResult> onBlocState(
      NodeSpec action, ActionContext context) async {
    final stateName = action.props["name"] as String?;
    if (stateName == null || stateName.isEmpty) {
      return SilentActionResult(true);
    }

    final state = ActionState(action.props["name"], action.props["data"]);
    if (action.props["type"] == "global") {
      GlobalBloc.emitState(state);
    } else {
      try {
        BlocProvider.of<LocalBloc>(context.buildContext).add(EmitState(state));
      } catch (e, stack) {
        log.severe("LocalBloc not found while emitting BlocState.", e, stack);
      }
    }
    return SilentActionResult(true);
  }

  Future<SilentActionResult> onMessage(
      NodeSpec action, ActionContext context) async {
    Lowder.widgets.showMessage(
      type: action.props["type"] ?? "info",
      message: action.props["message"],
    );
    return SilentActionResult(true);
  }

  Future<SilentActionResult> onNavigate(
      NodeSpec action, ActionContext context) async {
    final props = action.props;
    final screen = Schema.getScreen(props["jumpToScreen"]);
    final screenState = props["state"];

    if (screen != null) {
      Route route;
      final transition =
          Types.routeTransitionBuilder.build(props["transition"]);
      if (transition == null) {
        route = Lowder.widgets.buildRoute(screen, state: screenState);
      } else {
        route = PageRouteBuilder(
          settings: RouteSettings(name: screen.name, arguments: screen),
          pageBuilder: (context, animation, secondaryAnimation) =>
              Lowder.widgets.buildScreen(context, screen, state: screenState),
          transitionsBuilder: transition,
          transitionDuration: Duration(
              milliseconds:
                  parseInt(props["transitionDuration"], defaultValue: 200)),
        );
      }

      tailFunc(value) {
        final onPopAction = action.actions["onPop"];
        if (onPopAction != null && context.buildContext.mounted) {
          Lowder.actions.run(
            context.buildContext,
            NodeSpec.fromMap(onPopAction),
            context.state,
            value,
            context.actionContext,
          );
        }
      }

      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        final navigator = Lowder.actions.appNavigator;
        if (parseBool(props["replacePrevious"])) {
          if (navigator.canPop()) {
            navigator.pushReplacement(route).then(tailFunc);
          } else {
            navigator.push(route).then(tailFunc);
          }
        } else if (parseBool(props["replaceAll"])) {
          navigator.popUntil((route) => route.isFirst);
          if (!Lowder.editorMode) {
            navigator.pushReplacement(route).then(tailFunc);
          } else {
            navigator.push(route).then(tailFunc);
          }
        } else {
          navigator.push(route).then(tailFunc);
        }
      });
    }
    return SilentActionResult(true);
  }

  Future<SilentActionResult> onPop(
      NodeSpec action, ActionContext context) async {
    final props = action.props;
    final navigator = Lowder.actions.appNavigator;
    if (!navigator.canPop()) {
      return SilentActionResult(false);
    }

    final value = props["returnValue"];
    navigator.pop(value);

    if (props["returnMessage"] != null && context.buildContext.mounted) {
      Lowder.widgets.showMessage(
        type: props["returnMessageType"] ?? "info",
        message: props["returnMessage"],
      );
    }

    return SilentActionResult(true, returnData: value);
  }

  Future<SilentActionResult> onShowDialog(
      NodeSpec action, ActionContext context) async {
    final props = action.props;
    final screen = Schema.getScreen(props["jumpToScreen"]);
    final screenState = props["state"];
    if (screen == null) {
      return SilentActionResult(false);
    }

    tailFunc(value) {
      final onPopAction = action.actions["onPop"];
      if (onPopAction != null && context.buildContext.mounted) {
        Lowder.actions.run(
          context.buildContext,
          NodeSpec.fromMap(onPopAction),
          context.state,
          value,
          context.actionContext,
        );
      }
    }

    getDialog(context) => Dialog(
          shape: Lowder.properties.build("ShapeBorder", props["shape"]),
          backgroundColor: tryParseColor(props["backgroundColor"]),
          insetPadding: Lowder.properties.getInsets(props["padding"]),
          alignment: Lowder.properties.build("Alignment", props["alignment"]),
          elevation: tryParseDouble(props["elevation"]),
          child:
              Lowder.widgets.buildScreen(context, screen, state: screenState),
        );

    showGeneralDialog(
      context: context.buildContext,
      barrierLabel: "",
      barrierDismissible: parseBool(props["barrierDismissible"]),
      barrierColor: parseColor(props["barrierColor"],
          defaultColor: const Color(0x80000000)),
      pageBuilder: (context, anim1, anim2) => getDialog(context),
      transitionBuilder:
          Types.routeTransitionBuilder.build(props["transition"]),
      transitionDuration: Duration(
          milliseconds:
              parseInt(props["transitionDuration"], defaultValue: 200)),
    ).then((value) => tailFunc(value));
    return SilentActionResult(true);
  }

  Future<SilentActionResult> onSetState(
      NodeSpec action, ActionContext context) async {
    final newState = Map<String, dynamic>.from(action.props["newState"] ?? {});
    try {
      BlocProvider.of<LocalBloc>(context.buildContext)
          .add(EmitState(SetStateState(newState)));
    } catch (e, stack) {
      log.severe("LocalBloc not found while emitting SetState.", e, stack);
    }
    return SilentActionResult(true, returnData: newState);
  }

  Future<SilentActionResult> onSetGlobalVar(
      NodeSpec action, ActionContext context) async {
    final key = action.props["key"];
    final value = action.props["value"];
    if (key != null && key is String) {
      if (value != null) {
        Lowder.globalVariables[key] = value;
      } else {
        Lowder.globalVariables.remove(key);
      }
    }
    return SilentActionResult(true);
  }

  Future<SilentActionResult> onIf(
      NodeSpec action, ActionContext context) async {
    final condition = action.props["condition"];
    if (condition == null) {
      return SilentActionResult(true);
    }

    final actions = action.actions;
    final result = Lowder.properties.evaluateCondition(condition);
    Map? nextAction = result ? actions["onTrue"] : actions["onFalse"];

    // final props = action.props;
    // final result = Lowder.properties
    //     .evaluateOperator(props["left"], props["operator"], props["right"]);

    return SilentActionResult(true, nextAction: nextAction);
  }

  Future<ActionResult> onReloadAll(
      NodeSpec action, ActionContext context) async {
    GlobalBloc.emitState(ReloadAll());
    return ActionResult(true);
  }

  Future<ActionResult> onReload(NodeSpec action, ActionContext context) async {
    try {
      BlocProvider.of<LocalBloc>(context.buildContext)
          .add(EmitState(ReloadState()));
    } catch (e, stack) {
      log.severe("LocalBloc not found while emitting Reload.", e, stack);
    }
    return ActionResult(true);
  }

  Future<ActionResult> onReloadList(
      NodeSpec action, ActionContext context) async {
    GlobalBloc.emitState(ReloadListState(action.props["listId"]));
    return ActionResult(true);
  }

  Future<ActionResult> onSetLanguage(
      NodeSpec action, ActionContext context) async {
    final result = Solution.setLanguage(action.props["language"]);
    if (result) GlobalBloc.emitState(ReloadAll());
    return ActionResult(result);
  }

  Future<ActionResult> onLinkToAction(
      NodeSpec action, ActionContext context) async {
    final actionId = action.props["action"];
    if (actionId == null || actionId is! String || actionId.isEmpty) {
      return ActionResult(false);
    }

    return ActionResult(true, nextAction: Schema.getAction(actionId)?.toMap());
  }

  static Map? transformRequestToRest(NodeSpec action, ActionContext context) {
    NodeSpec? requestSpec;
    final restSpec = {}..addAll(action.props);
    final requestValue = restSpec["request"];
    if (requestValue is String) {
      requestSpec = Schema.getRequest(requestValue);
    } else if (requestValue is Map) {
      requestSpec = Schema.getRequest(requestValue["_type"] ?? "");
    }
    if (requestSpec == null) {
      return null;
    }

    restSpec.remove("request");
    Lowder.widgets.mergeMaps(restSpec, requestSpec.props);

    if (requestValue is Map) {
      var path = requestSpec.props["path"] as String?;
      if (path != null) {
        final pathParameters = requestValue["pathParameters"];
        if (pathParameters != null && pathParameters is Map) {
          for (var propKey in pathParameters.keys) {
            path = path!
                .replaceAll("{$propKey}", "${pathParameters[propKey] ?? ""}");
          }
        }
      }
      restSpec["path"] = path;
      Lowder.widgets.mergeMaps(restSpec, requestValue);
    }

    final evaluatorContext = Lowder.actions.getEvaluatorContext(
        context.actionValue, context.state, context.actionContext);
    Lowder.properties.evaluateMap(restSpec, evaluatorContext);
    return restSpec;
  }
}
