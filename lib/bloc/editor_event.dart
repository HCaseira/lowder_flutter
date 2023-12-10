/// Bloc event used by EditorBloc
abstract class BaseEditorEvent {}

class AppStartedEvent extends BaseEditorEvent {
  AppStartedEvent() : super();
}

class ScreenUpdatedEvent extends BaseEditorEvent {
  final String screenId;
  ScreenUpdatedEvent(this.screenId) : super();
}

class TemplateUpdatedEvent extends BaseEditorEvent {
  TemplateUpdatedEvent() : super();
}

class ComponentUpdatedEvent extends BaseEditorEvent {
  final String componentId;
  ComponentUpdatedEvent(this.componentId) : super();
}

class RequestUpdatedEvent extends BaseEditorEvent {
  final String requestId;
  RequestUpdatedEvent(this.requestId) : super();
}

class LoadScreenEvent extends BaseEditorEvent {
  final String screenId;
  final Map? state;
  LoadScreenEvent(this.screenId, this.state) : super();
}

class LoadComponentEvent extends BaseEditorEvent {
  final String componentId;
  LoadComponentEvent(this.componentId) : super();
}

class SelectEvent extends BaseEditorEvent {
  final String id;
  SelectEvent(this.id) : super();
}

class ClientSelectWidgetEvent extends BaseEditorEvent {
  final String id;
  ClientSelectWidgetEvent(this.id) : super();
}
