import 'package:flutter/widgets.dart';
import 'package:lowder/factory/action_factory.dart';
import 'package:lowder/factory/property_factory.dart';
import 'package:lowder/factory/widget_factory.dart';
import 'package:lowder/widget/lowder.dart';
import 'factory/actions.dart';
import 'factory/properties.dart';
import 'factory/widgets.dart';

class MyApp extends Lowder {
  MyApp({super.environment, super.editorMode, super.editorServer, super.key}) : super("My App");

  @override
  AppState createState() => _MyAppState();
  @override
  WidgetFactory createWidgetFactory() => SolutionWidgets();
  @override
  ActionFactory createActionFactory() => SolutionActions();
  @override
  PropertyFactory createPropertyFactory() => SolutionProperties();

  @override
  List<SolutionSpec> get solutions => [
        SolutionSpec(
          "My Solution",
          filePath: "assets/solution.low",
          widgets: SolutionWidgets(),
          actions: SolutionActions(),
          properties: SolutionProperties(),
        ),
      ];
}

class _MyAppState extends AppState with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
