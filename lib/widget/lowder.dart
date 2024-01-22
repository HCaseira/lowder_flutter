import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_event.dart';
import '../bloc/editor_state.dart';
import '../factory/actions.dart';
import '../factory/action_factory.dart';
import '../factory/properties.dart';
import '../factory/property_factory.dart';
import '../factory/widget_factory.dart';
import '../factory/widgets.dart';
import '../util/extensions.dart';
import '../schema.dart';
import 'splash_screen.dart';

/// The main class for a Lowder project.
/// It's the starting and central point of the app
/// with singleton references to the [WidgetFactory], [ActionFactory], [PropertyFactory],
/// [globalVariables] and [navigatorKey].
abstract class Lowder extends StatefulWidget {
  static const String _envEnvironment =
      String.fromEnvironment("LOWDER_ENV", defaultValue: "Prod");
  static const bool _envEditor =
      bool.fromEnvironment("LOWDER_EDITOR", defaultValue: false);
  static const String _envServer = String.fromEnvironment("LOWDER_SERVER",
      defaultValue: "http://localhost:8787/");

  static late bool _editorMode;
  static late String _editorServer;
  static late String _environment;
  static late WidgetFactory _widgets;
  static late ActionFactory _actions;
  static late PropertyFactory _properties;
  static final Map globalVariables = {};
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<SolutionSpec> _solutions = <SolutionSpec>[];

  /// A bool indicating if interaction with the Editor is active.
  static bool get editorMode => _editorMode;

  /// The url of the Editor http server.
  static String get editorServer => _editorServer;

  /// The active environment name, matching an existing environment name in the model.
  static String get environment => _environment;

  /// The instance of the [WidgetFactory].
  static WidgetFactory get widgets => _widgets;

  /// The instance of the [ActionFactory].
  static ActionFactory get actions => _actions;

  /// The instance of the [PropertyFactory].
  static PropertyFactory get properties => _properties;

  /// Method that allows access ta a [Lowder] instance
  /// as long as [BuildContext] contains a [Lowder] instance.
  static Lowder? of(BuildContext context) =>
      context.findAncestorWidgetOfExactType<Lowder>();

  /// The name for the App.
  final String title;
  late final Logger log;

  Lowder(
    this.title, {
    super.key,
    String environment = _envEnvironment,
    bool editorMode = _envEditor,
    String editorServer = _envServer,
  }) {
    log = Logger(title);
    _editorMode = editorMode;
    _editorServer = editorServer;
    _environment = environment;
    _widgets = createWidgetFactory();
    _actions = createActionFactory();
    _properties = createPropertyFactory();
  }

  WidgetFactory createWidgetFactory() => WidgetFactory();
  ActionFactory createActionFactory() => ActionFactory();
  PropertyFactory createPropertyFactory() => PropertyFactory();

  /// Implement this method to register your solution.
  /// A solution has a name, a schema file (<my solution>.low),
  /// and optional [IWidgets], [IActions] and [IProperties].
  List<SolutionSpec> get solutions;

  static List<Map> getSchema() {
    final schema = <Map>[];
    for (var solution in _solutions) {
      schema.add({
        "name": solution.name,
        "filePath": solution.filePath,
        "widgets": (solution.widgets ?? NoWidgets()).getSchema(),
        "actions": (solution.actions ?? NoActions()).getSchema(),
        "properties": (solution.properties ?? NoProperties()).getSchema(),
      });
    }
    return schema;
  }

  /// Upon 'InitialScreen' completion,
  /// a series of async methods will run in order: init, loadSolution and postInit
  /// After those methods complete, the Solution's landing screen will be built.
  Future<void> init() async {
    _solutions.add(SolutionSpec("Lowder",
        widgets: BaseWidgets(),
        actions: BaseActions(),
        properties: BaseProperties()));
    _solutions.addAll(solutions);

    for (var sol in _solutions) {
      if (sol.widgets != null) {
        widgets.loadWidgets(sol.widgets!);
      }
      if (sol.actions != null) {
        actions.loadActions(sol.actions!);
      }
      if (sol.properties != null) {
        properties.loadProperties(sol.properties!);
      }
    }
  }

  @nonVirtual
  Future<void> loadSolution() async {
    final maps = <Map>[];
    for (var solution in _solutions) {
      if (solution.filePath != null && solution.filePath!.isNotEmpty) {
        var map = await fetchSolutionMap(solution.filePath!);
        if (map != null) {
          maps.add(map);
        }
      }
    }
    Schema.loadSolutionsFromMaps(maps, environment);
  }

  /// This method will fetch the schema file from Assets.
  /// Override it to fetch the schema file from an alternative location,
  /// like a remote location to allow over-the-air updates.
  @protected
  Future<Map?> fetchSolutionMap(String path) async {
    try {
      log.info("Getting asset '$path'");
      var data = await rootBundle.loadString(path);
      return json.decodeWithReviver(data);
    } catch (e) {
      log.severe("Error loading file '$path' from assets.", e);
    }
    return null;
  }

  Future<void> postInit() async {}

  /// A GlobalBloc is present to handle global events, like the
  /// activity indicator or messages (info, success, warning, error).
  @protected
  GlobalBloc createBloc() => GlobalBloc();

  @protected
  bool globalListenWhen(BaseState prevState, BaseState newState) => false;

  @protected
  void globalListener(BuildContext context, BaseState state) {}

  /// This will be the first Widget the user will see, tipically a splash screen.
  /// Use it to do some background work like refreshing an access token or remotely fetch the schema file.
  /// When all animations and backgroung work is done, just pop it and Lowder will load the solution
  /// and render the landing screen.
  Widget getInitialScreen(BuildContext context) => const LowderSplashScreen();

  @protected
  Widget buildApp(GlobalKey<NavigatorState> navigatorKey, Widget rootWidget) {
    return MaterialApp(
      title: title,
      theme: getTheme(),
      home: rootWidget,
      navigatorKey: navigatorKey,
    );
  }

  getTheme() => ThemeData.light(useMaterial3: true);

  @override
  AppState createState() => AppState();

  /// Method called upon [Logger]'s 'onRecord'.
  /// When in editor mode, logs will be sent to the Editor.
  Future<void> onNewLog(LogRecord logRecord) async {
    if (editorMode) {
      if (logRecord.object is LogRecord) {
        // Created via extension methods 'infoWithContext', 'warningWithContext', etc.
        logRecord = logRecord.object as LogRecord;
      }

      Map? context = {};
      if (logRecord.object is Map) {
        for (var key in (logRecord.object as Map).keys) {
          var val = (logRecord.object as Map)[key];
          if (val is! Function && key != "null") {
            context[key] = val;
          }
        }
      }

      try {
        EditorBloc.instance?.add(LogEvent(
          logRecord.level.name,
          "${logRecord.time} [${logRecord.loggerName}] ${logRecord.message}",
          context: context,
          error: logRecord.error,
          stackTrace: logRecord.stackTrace,
        ));
      } catch (e) {
        // Do nothing.
      }
    }
  }
}

class AppState extends State<Lowder> {
  @override
  void initState() {
    super.initState();
    Logger.root.onRecord.listen(widget.onNewLog);
  }

  @nonVirtual
  Future<bool> load() async {
    widget.log.info("Running init");
    await widget.init();
    widget.log.info("Loading Solution");
    await widget.loadSolution();
    widget.log.info("Running postInit");
    await widget.postInit();
    widget.log.info("Loading complete");
    return true;
  }

  /// The build methods should not be overridden, otherwise
  /// Lowder may not work properly.
  @nonVirtual
  @override
  Widget build(BuildContext context) {
    final providers = <BlocProvider>[
      BlocProvider<GlobalBloc>(create: (c) => widget.createBloc(), lazy: false)
    ];
    if (Lowder.editorMode) {
      providers.add(
          BlocProvider<EditorBloc>(create: (c) => EditorBloc(), lazy: false));
    }

    var goHome = false;
    final rootWidget = StatefulBuilder(
      builder: (context, setState) {
        if (!goHome) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              await load();
              setState(() => goHome = true);
            },
            child: widget.getInitialScreen(context),
          );
        }
        return buildBody(context);
      },
    );

    return MultiBlocProvider(
      providers: providers,
      child: Builder(
          builder: (context) =>
              widget.buildApp(Lowder.navigatorKey, rootWidget)),
    );
  }

  @nonVirtual
  Widget buildBody(BuildContext context) {
    final bodyChild = Lowder.editorMode
        ? buildEditorHandler(context)
        : buildScreen(context, Schema.getLandingScreen());

    return BlocListener<GlobalBloc, BaseState>(
      listenWhen: widget.globalListenWhen,
      listener: widget.globalListener,
      child: bodyChild,
    );
  }

  Widget buildScreen(BuildContext context, String screenId, {Map? state}) {
    var spec = Schema.getScreen(screenId);
    if (spec == null) {
      return Container();
    }
    return Lowder.widgets.buildScreen(context, spec, state: state);
  }

  @nonVirtual
  Widget buildEditorHandler(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => BlocProvider.of<EditorBloc>(context).add(AppStartedEvent()));

    return BlocBuilder<EditorBloc, BaseState>(
      buildWhen: (prevState, currState) {
        return currState is LoadScreenState ||
            currState is LoadComponentState ||
            currState is ComponentUpdatedState;
      },
      builder: (context, state) {
        if (state is LoadScreenState) {
          log("Loading screen ${state.screenId}");
          Navigator.of(context).popUntil((route) => route.isFirst);
          return buildScreen(context, state.screenId, state: state.state);
        } else if (state is LoadComponentState) {
          log("Loading component ${state.componentId}");
          Navigator.of(context).popUntil((route) => route.isFirst);
          return _buildComponent(context, state.componentId);
        } else if (state is ComponentUpdatedState) {
          log("Updating component ${state.componentId}");
          return _buildComponent(context, state.componentId);
        }
        return Container();
      },
    );
  }

  @nonVirtual
  Widget _buildComponent(BuildContext context, String componentId) {
    var spec = Schema.getComponent(componentId);
    if (spec == null) {
      return Container();
    }
    var component = Lowder.widgets.buildWidgetFromSpec(context, spec, {}, {});
    return Scaffold(
      body: component,
    );
  }
}

class SolutionSpec {
  final String name;
  final String? filePath;
  final IWidgets? widgets;
  final IActions? actions;
  final IProperties? properties;

  SolutionSpec(this.name,
      {this.filePath, this.widgets, this.actions, this.properties}) {
    widgets?.registerWidgets();
    actions?.registerActions();
    properties?.registerProperties();
  }
}
