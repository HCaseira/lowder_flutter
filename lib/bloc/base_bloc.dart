import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../util/extensions.dart';
import '../widget/lowder.dart';
import 'base_event.dart';
import 'base_state.dart';

/// Lowder's implementation of [Bloc] to support Lowder's Widgets and Actions.
abstract class BaseBloc extends Bloc<BaseEvent, BaseState> {
  late Logger log;

  BaseBloc(super.initialState) {
    on<EmitState>((evt, emit) => emit(evt.state));
    on<LoadPageActionEvent>(onLoadPageAction);
    log = Logger(className);
  }

  String get className;

  @protected
  void onLoadPageAction(
      LoadPageActionEvent event, Emitter<BaseState> emit) async {
    PageLoadedState state;
    final func = Lowder.actions.getPageLoadResolver(event.action.type);
    if (func == null) {
      log.severe("Unknown LoadPageAction type: '${event.action.type}'");
      state = PageLoadedState(event.page, event.fullData, false);
    } else {
      state = await func(event);
      log.infoWithContext(
          "LoadPageAction '${event.action.type}' executed successfully", {
        "page": event.page,
        "pageSize": event.pageSize,
        "hasMore": state.hasMore,
        "length": state.fullData.length,
        "last": state.fullData.lastOrNull,
      });
    }
    emit(state);
  }
}

/// A singleton [BaseBloc] to emit states to the whole app
class GlobalBloc extends BaseBloc {
  /// This is a singleton class
  GlobalBloc._() : super(InitialState());
  static final _instance = GlobalBloc._();
  factory GlobalBloc() => _instance;

  @override
  String get className => "GlobalBloc";

  static void emitState(BaseState state) => GlobalBloc().add(EmitState(state));
}

/// A [BaseBloc] used by Widgets wanting to handle private events.
class LocalBloc extends BaseBloc {
  LocalBloc(super.initialState);

  @override
  String get className => "LocalBloc";
}

/// A [BaseBloc] used by Widgets displaying paged data.
class ListBloc extends BaseBloc {
  ListBloc(super.initialState);

  @override
  String get className => "ListBloc";
}
