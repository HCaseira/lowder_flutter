import '../model/action_context.dart';
import '../model/node_spec.dart';
import 'base_state.dart';

/// A base for Lowder's Bloc events.
abstract class BaseEvent {
  BaseEvent();
}

/// A Bloc event to emit a given [state].
class EmitState extends BaseEvent {
  final BaseState state;
  EmitState(this.state);
}

/// A Bloc event to handle page loading.
class LoadPageActionEvent extends BaseEvent {
  final NodeSpec action;
  final int page;
  final int pageSize;
  final List<dynamic> fullData;
  final ActionContext context;
  LoadPageActionEvent(this.action, this.context, this.page, this.pageSize, this.fullData);
}
