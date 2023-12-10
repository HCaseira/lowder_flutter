import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_state.dart';
import '../model/node_spec.dart';
import 'lowder.dart';

typedef BlocListenerFunction = void Function(BuildContext context, BaseState state);
typedef BlocBuilderFunction = Widget Function(BuildContext context, BaseState state);
typedef EditorBuildFunction = Widget Function(BuildContext context);

/// Base Bloc consumer class for handling states
class LowderBlocConsumer<B extends BaseBloc> extends StatefulWidget {
  final Map<String, BlocListenerFunction> _listeners = <String, BlocListenerFunction>{};
  final Map<String, BlocBuilderFunction> _builders = <String, BlocBuilderFunction>{};
  final BlocBuilderFunction defaultBuilder;
  final BlocListenerFunction? defaultListener;

  LowderBlocConsumer(this.defaultBuilder, {super.key, this.defaultListener});

  void listenOn<S extends BaseState>({BlocListenerFunction? func}) {
    func ??= defaultListener;
    if (func != null) {
      _listeners[S.toString()] = func;
    }
  }

  void buildOn<S extends BaseState>({BlocBuilderFunction? func}) {
    func ??= defaultBuilder;
    _builders[S.toString()] = func;
  }

  bool _listenWhen(BaseState previousState, BaseState currentState) {
    return previousState != currentState && _listeners.containsKey(currentState.runtimeType.toString());
  }

  void _listener(BuildContext context, BaseState state) {
    final key = state.runtimeType.toString();
    if (_listeners.containsKey(key)) {
      _listeners[key]!(context, state);
    }
  }

  bool _buildWhen(BaseState previousState, BaseState currentState) {
    return previousState != currentState && _builders.containsKey(currentState.runtimeType.toString());
  }

  Widget _builder(BuildContext context, BaseState state) {
    final key = state.runtimeType.toString();
    if (_builders.containsKey(key)) {
      return _builders[key]!(context, state);
    }
    return defaultBuilder(context, state);
  }

  @override
  State<StatefulWidget> createState() => _LowderBlocConsumerState<B>();

  void dispose() {}
}

class _LowderBlocConsumerState<B extends BaseBloc> extends State<LowderBlocConsumer> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, BaseState>(
      listenWhen: widget._listenWhen,
      listener: widget._listener,
      buildWhen: widget._buildWhen,
      builder: widget._builder,
    );
  }

  @override
  void dispose() {
    widget.dispose();
    super.dispose();
  }
}

class LocalBlocConsumer<B extends LocalBloc> extends LowderBlocConsumer<B> {
  LocalBlocConsumer(super.defaultBuilder, {super.key, super.defaultListener}) {
    buildOn<SetStateState>();
    buildOn<ReloadState>();
  }
}

/// Global Bloc consumer for handling global states
class GlobalBlocConsumer<B extends GlobalBloc> extends LowderBlocConsumer<B> {
  final WidgetNodeSpec? node;

  GlobalBlocConsumer(super.defaultBuilder, {super.key, super.defaultListener, this.node}) {
    buildOn<ReloadAll>();
  }
}

/// Local Bloc consumer for handling local states
class LocalBlocWidget extends StatelessWidget {
  final String screenId;
  final BlocBuilderFunction builder;
  final BlocListenerFunction? listener;

  const LocalBlocWidget(this.screenId, this.builder, {super.key, this.listener});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocalBloc>(
      lazy: false,
      create: (c) => Lowder.actions.createLocalBloc(),
      child: Lowder.widgets.getGlobalBlocConsumer((context, state) {
        return Lowder.widgets.getLocalBlocConsumer(builder, listener: listener);
      }, listener: listener),
    );
  }
}

/// Editor Bloc consumer for handling Editor messages
class EditorBlocConsumer extends StatelessWidget {
  final String screenId;
  final EditorBuildFunction buildFunc;

  const EditorBlocConsumer(this.screenId, this.buildFunc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, BaseState>(
      buildWhen: (prevState, currState) {
        return prevState != currState &&
            (currState is ComponentUpdatedState ||
                currState is TemplateUpdatedState ||
                currState is RequestUpdatedState ||
                (currState is ScreenUpdatedState && currState.screenId == screenId));
      },
      builder: (context, state) {
        return buildFunc(context);
      },
    );
  }
}
