import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'model/node_spec.dart';
import 'model/solution.dart';
import 'util/extensions.dart';

class Schema {
  static final _log = Logger("Schema");
  static Solution? _solution;

  static void loadSolutionsFromMaps(List<Map> solutions, String environment,
      {String language = "en"}) {
    if (solutions.isEmpty) {
      return;
    }

    var name = "";
    var landingScreen = "";
    final createdSolutions = <Solution>[];

    for (var solution in solutions) {
      if (solution["landingScreen"] != null &&
          solution["landingScreen"].isNotEmpty) {
        landingScreen = solution["landingScreen"];
      }
      var newSolution =
          Solution.fromMap(solution, environment, language: language);
      createdSolutions.add(newSolution);
      if (newSolution.name.isNotEmpty) {
        name = newSolution.name;
      }
    }

    if (landingScreen.isEmpty && createdSolutions.isNotEmpty) {
      landingScreen = createdSolutions.last.landingScreen;
    }

    final solution = Solution.empty(name, environment,
        language: language, landingScreen: landingScreen);
    for (var createdSolution in createdSolutions) {
      solution.merge(createdSolution);
    }
    _solution = solution;
  }

  static Future loadSolutionsFromAssets(List<String> paths, String environment,
      {String language = "en"}) async {
    final maps = <Map>[];
    for (var path in paths) {
      try {
        _log.info("Getting asset '$path'");
        var data = await rootBundle.loadString(path);
        var solution = json.decodeWithReviver(data);
        maps.add(solution);
      } catch (e) {
        _log.severe("Error loading file '$path' from assets.", e);
      }
    }

    _log.info("Building Solution from ${maps.length} maps");
    loadSolutionsFromMaps(maps, environment, language: language);
  }

  static Future loadSolutionsFromUrls(List<String> urls, String environment,
      {String language = "en"}) async {
    final maps = <Map>[];
    for (var url in urls) {
      try {
        var response = await http.get(Uri.parse(url));
        if (response.isSuccess) {
          var solution = json.decodeWithReviver(response.body);
          maps.add(solution);
        }
      } catch (e) {
        _log.severe("Error downloading file '$url'.", e);
      }
    }
    loadSolutionsFromMaps(maps, environment, language: language);
  }

  static String getLandingScreen() => _solution?.landingScreen ?? "";

  static String? getEnvironment() => Solution.environment;

  static WidgetNodeSpec? getScreen(String id) => _solution?.getScreen(id);

  static WidgetNodeSpec? getTemplate(String id) => _solution?.getTemplate(id);

  static WidgetNodeSpec? getComponent(String id, {String? newId}) =>
      _solution?.getComponent(id)?.clone(newId: newId);

  static ActionNodeSpec? getAction(String id) => _solution?.getAction(id);

  static RootNodeSpec? getRequest(String id) => _solution?.getRequest(id);

  static void upsertScreen(Map spec) => _solution?.upsertScreen(spec);

  static void upsertTemplate(Map spec) => _solution?.upsertTemplate(spec);

  static void upsertComponent(Map spec) => _solution?.upsertComponent(spec);

  static void upsertRequest(Map spec) => _solution?.upsertRequest(spec);
}
