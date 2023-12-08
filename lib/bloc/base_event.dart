import '../model/action_context.dart';
import '../model/k_node.dart';
import 'base_state.dart';

abstract class BaseEvent {
  BaseEvent();
}

class EmitState extends BaseEvent {
  final BaseState state;
  EmitState(this.state);
}

class LoadPageActionEvent extends BaseEvent {
  final NodeSpec action;
  final int page;
  final int pageSize;
  final List<dynamic> fullData;
  final ActionContext context;
  LoadPageActionEvent(this.action, this.context, this.page, this.pageSize, this.fullData);
}
