import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widget/lowder.dart';
import 'base_event.dart';
import 'base_state.dart';

/// Lowder's implementation of [Bloc] to support Lowder's Widgets and Actions.
abstract class BaseBloc extends Bloc<BaseEvent, BaseState> {
  BaseBloc(super.initialState) {
    on<EmitState>((evt, emit) => emit(evt.state));
    on<LoadPageActionEvent>(onLoadPageAction);
  }

  @protected
  void onLoadPageAction(
      LoadPageActionEvent event, Emitter<BaseState> emit) async {
    PageLoadedState state;
    final func = Lowder.actions.getPageLoadResolver(event.action.type);
    if (func == null) {
      Lowder.logError(
          "[$runtimeType.onLoadPageAction] Unknown LoadPageAction type: '${event.action.type}'");
      state = PageLoadedState(event.page, event.fullData, false);
    } else {
      state = await func(event);
      Lowder.logInfo(
          "[$runtimeType.onLoadPageAction] LoadPageAction '${event.action.type}' executed successfully",
          context: {
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

  static emitState(BaseState state) => GlobalBloc().add(EmitState(state));
}

/// A [BaseBloc] used by Widgets wanting to handle private events.
class LocalBloc extends BaseBloc {
  LocalBloc(super.initialState);
}

/// A [BaseBloc] used by Widgets displaying paged data.
class ListBloc extends BaseBloc {
  ListBloc(super.initialState);
}
