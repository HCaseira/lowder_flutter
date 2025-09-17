import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_event.dart';
import '../model/node_spec.dart';
import '../util/extensions.dart';
import '../schema.dart';
import 'lowder.dart';
import 'bloc_handler.dart';

/// A Widget used render a `Screen` object from `model`.
class LowderScreen extends StatefulWidget {
  final log = Logger("Screen");
  final formKey = GlobalKey<FormState>();
  final WidgetNodeSpec spec;
  final Map state = {};
  final StreamController<void> _reloadController = StreamController<void>();
  late final Stream<void> reload;

  LowderScreen(this.spec, Map initialState, {super.key}) {
    // to avoid messing with the original object, copy it instead of using it as the screen state
    // eg: passing a selected element of a list as the state of a detail screen
    state.addAll(initialState);
    if (spec.props["state"] is Map) {
      state.addAll(spec.props["state"]);
    }
    reload = _reloadController.stream.asBroadcastStream();
    if (Lowder.editorMode && initialState.isNotEmpty) {
      EditorBloc.addEvent(ScreenInitEvent(spec.id, state));
    }
  }

  @override
  State<StatefulWidget> createState() => LowderScreenState();

  LocalBlocWidget getBlocWidget(String screenId, BlocBuilderFunction buildFunc,
      {BlocListenerFunction? listenFunc}) {
    return LocalBlocWidget(buildFunc, listener: listenFunc);
  }

  @protected
  Future<void> initState(BuildContext context) async {
    if (actions["onEnter"] != null) {
      var func =
          Lowder.actions.getFunction(context, actions["onEnter"], state, null);
      if (func != null) {
        func();
      }
    }
  }

  String get id => spec.id;
  String? get name => spec.name;
  Map get actions => spec.actions;
  Map get props => spec.props;
  Map get widgets => spec.widgets;
  Map get bodySpec => widgets["body"];

  static LowderScreen? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_KScreenScope>();
    return scope?.screen;
  }
}

class LowderScreenState extends State<LowderScreen> {
  static final String _uuidPattern =
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-8][0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}';
  String get id => widget.id;
  String? get name => widget.name;
  Map get state => widget.state;
  Map get bodySpec => widget.bodySpec;
  bool _initialized = false;

  EditorBlocConsumer getEditorHandler(
          String screenId, EditorBuildFunction buildFunc) =>
      EditorBlocConsumer(screenId, buildFunc);

  void updateSpec() {
    _initialized = false;
    widget.spec.widgets["body"] = Schema.getScreen(id)?.widgets["body"];
  }

  void listener(BuildContext context, BaseState currentState) {}

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (!Lowder.editorMode) {
      return internalBuild(context);
    }
    return getEditorHandler(widget.id, (context) {
      updateSpec();
      return internalBuild(context);
    });
  }

  @nonVirtual
  Widget internalBuild(BuildContext context) {
    return _KScreenScope(widget,
        child: widget.getBlocWidget(widget.id, builder, listenFunc: listener));
  }

  Widget builder(BuildContext context, BaseState currentState) {
    widget.log.infoWithContext(
      "Building '$name' from state ${currentState.runtimeType}.",
      Lowder.properties.getEvaluatorContext(null, state, null),
    );

    if (currentState is ReloadState || currentState is ReloadAll) {
      _initialized = false;
      _removePreviousValues();
      widget._reloadController.add(null);
    } else if (currentState is SetStateState) {
      _removePreviousValues();
      state.addAll(currentState.state);
      if (currentState.reloadLists) {
        widget._reloadController.add(null);
      }
    }

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.initState(context);
      });
    }

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: buildSpecBody(context, bodySpec),
    );
  }

  Widget buildSpecBody(BuildContext context, Map bodySpec) {
    try {
      final body = Lowder.widgets.buildWidget(context, bodySpec, state, null);
      return body;
    } catch (e, stack) {
      widget.log.severeWithContext(
        "Error building '$name' body from spec.",
        Lowder.properties.getEvaluatorContext(null, state, null),
        e,
        stack,
      );
      return Container();
    }
  }

  // Removes any value previously set to Widgets, so they can be re-evaluated.
  void _removePreviousValues() {
    var stateKeys = [...state.keys];
    for (var key in stateKeys) {
      if (key is String &&
          RegExp(_uuidPattern, caseSensitive: false).hasMatch(key)) {
        state.remove(key);
      }
    }
  }
}

class _KScreenScope extends InheritedWidget {
  final LowderScreen screen;
  const _KScreenScope(this.screen, {required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
