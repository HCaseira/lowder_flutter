import 'base_state.dart';

class InitialEditorState extends BaseState {
  InitialEditorState() : super();
}

class LoadScreenState extends BaseState {
  final String screenId;
  final Map? state;
  LoadScreenState(this.screenId, this.state) : super();
}

class LoadComponentState extends BaseState {
  final String componentId;
  LoadComponentState(this.componentId) : super();
}

class ScreenUpdatedState extends BaseState {
  final String screenId;
  ScreenUpdatedState(this.screenId) : super();
}

class TemplateUpdatedState extends BaseState {
  TemplateUpdatedState() : super();
}

class ComponentUpdatedState extends BaseState {
  final String componentId;
  ComponentUpdatedState(this.componentId) : super();
}

class RequestUpdatedState extends BaseState {
  final String componentId;
  RequestUpdatedState(this.componentId) : super();
}

class SelectWidgetState extends BaseState {
  final String id;
  SelectWidgetState(this.id) : super();
}
