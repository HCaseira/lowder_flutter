abstract class BaseState {
  BaseState();
}

class InitialState extends BaseState {
  final Map? arguments;
  InitialState({this.arguments}) : super();
}

class ActionState extends BaseState {
  final String state;
  final dynamic data;
  ActionState(this.state, this.data) : super();
}

class ReloadAll extends BaseState {}

class ReloadState extends BaseState {}

class SetStateState extends BaseState {
  final Map state;
  SetStateState(this.state) : super();
}

class PageLoadedState extends BaseState {
  final int page;
  final List<dynamic> fullData;
  final bool hasMore;
  PageLoadedState(this.page, this.fullData, this.hasMore) : super();
}

class ReloadListState extends BaseState {
  final String? listId;
  ReloadListState(this.listId) : super();
}
