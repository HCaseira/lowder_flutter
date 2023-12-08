import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widget/lowder.dart';
import 'base_event.dart';
import 'base_state.dart';

abstract class BaseBloc extends Bloc<BaseEvent, BaseState> {
  BaseBloc(super.initialState) {
    on<EmitState>((evt, emit) => emit(evt.state));
    on<LoadPageActionEvent>(onLoadPageAction);
  }

  @protected
  void onLoadPageAction(LoadPageActionEvent event, Emitter<BaseState> emit) async {
    PageLoadedState state;
    final func = Lowder.actions.getPageLoadResolver(event.action.type);
    if (func == null) {
      Lowder.actions.logError("Unknown LoadPageAction type: ${event.action.type}", originClass: runtimeType);
      state = PageLoadedState(event.page, event.fullData, false);
    } else {
      state = await func(event);
    }
    emit(state);
  }
}

class GlobalBloc extends BaseBloc {
  /// This is a singleton class
  GlobalBloc._() : super(InitialState());
  static final _instance = GlobalBloc._();
  factory GlobalBloc() => _instance;

  static emitState(BaseState state) => GlobalBloc().add(EmitState(state));
}

class LocalBloc extends BaseBloc {
  LocalBloc(super.initialState);
}

class ListBloc extends BaseBloc {
  ListBloc(super.initialState);
}
