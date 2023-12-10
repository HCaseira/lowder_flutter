/// A base for Lowder's Bloc states.
abstract class BaseState {
  BaseState();
}

/// Generic state for initiating a Bloc.
class InitialState extends BaseState {
  final Map? arguments;
  InitialState({this.arguments}) : super();
}

/// A state based on a Model Node with a [state] and [data].
class ActionState extends BaseState {
  final String state;
  final dynamic data;
  ActionState(this.state, this.data) : super();
}

/// A Bloc state to signal a reload globally.
class ReloadAll extends BaseState {}

/// A Bloc state to signal a reload.
class ReloadState extends BaseState {}

/// A Bloc state to signal a new [state].
class SetStateState extends BaseState {
  final Map state;
  SetStateState(this.state) : super();
}

/// A Bloc state to signal that a new page data exists.
class PageLoadedState extends BaseState {
  final int page;
  final List<dynamic> fullData;
  final bool hasMore;
  PageLoadedState(this.page, this.fullData, this.hasMore) : super();
}

/// A Bloc state to signal that a List should be reloaded.
class ReloadListState extends BaseState {
  final String? listId;
  ReloadListState(this.listId) : super();
}
