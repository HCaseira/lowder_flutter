import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../model/editor_message.dart';
import '../model/solution.dart';
import '../schema.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../widget/lowder.dart';
import 'base_state.dart';
import 'editor_event.dart';
import 'editor_state.dart';

/// Class to handle communications between the Lowder App and the Lowder Editor.
/// Available when in [Lowder.editorMode].
class EditorBloc extends Bloc<BaseEditorEvent, BaseState> {
  static bool editMode = false;
  static String clientId = const Uuid().v1();
  static EditorBloc? instance;

  final _log = Logger("EditorBloc");
  bool active = true;

  EditorBloc() : super(InitialEditorState()) {
    if (instance != null) {
      instance!.close();
    }
    instance = this;
    on<AppStartedEvent>((event, emit) => onAppStartedEvent());
    on<LoadScreenEvent>(
        (event, emit) => emit(LoadScreenState(event.screenId, event.state)));
    on<LoadComponentEvent>(
        (event, emit) => emit(LoadComponentState(event.componentId)));
    on<ScreenUpdatedEvent>(
        (event, emit) => emit(ScreenUpdatedState(event.screenId)));
    on<ComponentUpdatedEvent>(
        (event, emit) => emit(ComponentUpdatedState(event.componentId)));
    on<TemplateUpdatedEvent>((event, emit) => emit(TemplateUpdatedState()));
    on<RequestUpdatedEvent>(
        (event, emit) => emit(RequestUpdatedState(event.requestId)));
    on<SelectEvent>((event, emit) => _selectEvent(event));
    on<ClientSelectWidgetEvent>(
        (event, emit) => emit(SelectWidgetState(event.id)));
    on<LogEvent>(onLogEvent);
  }

  String getServerUrl() {
    var serverUrl = Lowder.editorServer;
    if (!serverUrl.endsWith("/")) {
      serverUrl += "/";
    }
    serverUrl += "client?id=$clientId";
    return serverUrl;
  }

  Future<void> _selectEvent(SelectEvent event) async {
    try {
      final serverUrl = getServerUrl();
      await http.post(Uri.parse(serverUrl),
          body: jsonEncode(EditorMessage("clientSelectWidget", event.id)));
    } on Exception catch (e) {
      log("Error calling Lowder Server: $e");
    }
  }

  Future<void> onAppStartedEvent() async {
    await sendSchema();
    await _hotReloadThread();
  }

  Future<void> onLogEvent(LogEvent event, Emitter emit) async {
    try {
      final serverUrl = getServerUrl();
      final body = json.safeEncode(EditorMessage("log", {
        "origin": "client",
        "type": event.type,
        "message": event.message,
        "context": event.context,
        "error": event.error?.toString(),
        "stackTrace": event.stackTrace?.toString(),
      }));
      await http.post(Uri.parse(serverUrl), body: body);
    } catch (e, stack) {
      _log.severe("Error sending log to Editor: $e", e, stack);
    }
  }

  Future<void> sendSchema() async {
    try {
      final serverUrl = getServerUrl();
      final body =
          jsonEncode(EditorMessage("clientSchema", Lowder.getSchema()));
      await http.post(Uri.parse(serverUrl), body: body);
    } catch (e, stack) {
      _log.severe("Error sending schema to Lowder Server: $e", e, stack);
    }
  }

  Future<void> _hotReloadThread() async {
    final serverUrl = getServerUrl();
    while (instance == this) {
      try {
        var response = await http.get(Uri.parse(serverUrl));
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          log("New data from Lowder Server: ${response.body}");
          Map<String, dynamic> spec = json.decodeWithReviver(response.body);

          var message = EditorMessage.fromJson(spec);
          switch (message.dataType) {
            case "getSchema":
              await sendSchema();
              break;
            case "solution":
              Schema.loadSolutionsFromMaps(message.data["solutions"],
                  message.data["environment"] ?? "Dev",
                  language: message.data["language"] ?? "en");
              editMode = parseBool(message.data["editMode"]);
              var selectedNode = message.data["selectedNode"];
              if (selectedNode != null) {
                var node = Schema.getScreen(selectedNode);
                if (node != null) {
                  final screenState = message.data["state"] != null
                      ? json.decodeWithReviver(message.data["state"])
                      : null;
                  add(LoadScreenEvent(selectedNode, screenState));
                } else {
                  node = Schema.getComponent(selectedNode);
                  if (node != null) {
                    add(LoadComponentEvent(selectedNode));
                  }
                }
              } else {
                add(LoadScreenEvent("", null));
              }
              break;
            case "screen":
              Schema.upsertScreen(message.data);
              add(ScreenUpdatedEvent(message.data["_id"]));
              break;
            case "template":
              Schema.upsertTemplate(message.data);
              add(TemplateUpdatedEvent());
              break;
            case "component":
              Schema.upsertComponent(message.data);
              add(ComponentUpdatedEvent(message.data["_id"]));
              break;
            case "request":
              Schema.upsertRequest(message.data);
              add(RequestUpdatedEvent(message.data["_id"]));
              break;
            case "loadScreen":
              final screenState = message.data["state"] != null
                  ? json.decodeWithReviver(message.data["state"])
                  : null;
              add(LoadScreenEvent(message.data["id"], screenState));
              break;
            case "loadComponent":
              add(LoadComponentEvent(message.data));
              break;
            case "editMode":
              editMode = message.data;
              add(TemplateUpdatedEvent()); // To force Screen rebuild
              break;
            case "editorSelectWidget":
              add(ClientSelectWidgetEvent(message.data));
              break;
            case "setEnvironment":
              Solution.setEnvironment(message.data);
              add(TemplateUpdatedEvent()); // To force Screen rebuild
              break;
            case "setLanguage":
              Solution.setLanguage(message.data);
              add(TemplateUpdatedEvent()); // To force Screen rebuild
              break;
          }
        }
      } on Exception catch (e) {
        log("Error calling Lowder Server: $e");
        await Future.delayed(const Duration(seconds: 1));
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Future<void> close() async {
    instance = null;
    return super.close();
  }
}
