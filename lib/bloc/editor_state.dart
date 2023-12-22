import 'base_state.dart';

/// Bloc state used by [EditorBloc] as the initial state.
class InitialEditorState extends BaseState {
  InitialEditorState() : super();
}

/// Bloc state used by [EditorBloc] to signal a Screen selection.
class LoadScreenState extends BaseState {
  final String screenId;
  final Map? state;
  LoadScreenState(this.screenId, this.state) : super();
}

/// Bloc state used by [EditorBloc] to signal a Component selection.
class LoadComponentState extends BaseState {
  final String componentId;
  LoadComponentState(this.componentId) : super();
}

/// Bloc state used by [EditorBloc] to signal a Screen update.
class ScreenUpdatedState extends BaseState {
  final String screenId;
  ScreenUpdatedState(this.screenId) : super();
}

/// Bloc state used by [EditorBloc] to signal a Template update.
class TemplateUpdatedState extends BaseState {
  TemplateUpdatedState() : super();
}

/// Bloc state used by [EditorBloc] to signal a Component update.
class ComponentUpdatedState extends BaseState {
  final String componentId;
  ComponentUpdatedState(this.componentId) : super();
}

/// Bloc state used by [EditorBloc] to signal a Request update.
class RequestUpdatedState extends BaseState {
  final String componentId;
  RequestUpdatedState(this.componentId) : super();
}

/// Bloc state used by [EditorBloc] to signal a Widget selection.
class SelectWidgetState extends BaseState {
  final String id;
  SelectWidgetState(this.id) : super();
}
