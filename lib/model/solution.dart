import 'package:flutter/foundation.dart';

import '../util/strings.dart';
import 'node_spec.dart';

/// Class representing a Model's Solution and its Nodes.
class Solution {
  final String name;
  final String type;
  final String landingScreen;
  @protected
  final Map<String, WidgetNodeSpec> screens;
  @protected
  final Map<String, WidgetNodeSpec> templates;
  @protected
  final Map<String, WidgetNodeSpec> components;
  @protected
  final Map<String, ActionNodeSpec> actions;
  @protected
  final Map<String, RootNodeSpec> requests;
  static String? _currentEnvironment;
  @protected
  static final EnvironmentData environmentData = EnvironmentData({});
  static Map<String, String> environmentVariables = {};
  @protected
  static final StringResources stringResources = StringResources({});
  static String _language = "en";

  Solution._(this.name, this.type, this.landingScreen, this.screens,
      this.templates, this.components, this.actions, this.requests);

  void upsertScreen(Map spec) {
    final node = WidgetNodeSpec.fromMap(spec);
    screens[node.id] = node;

    final routeName = node.props["routeName"] as String?;
    if (routeName != null && routeName.isNotEmpty) {
      screens[routeName] = node;
    }
  }

  void upsertTemplate(Map spec) {
    final node = WidgetNodeSpec.fromMap(spec);
    templates[node.id] = node;
    if (node.name != null && node.name!.isNotEmpty) {
      templates[node.name!] = node;
    }
  }

  void upsertComponent(Map spec) {
    final node = WidgetNodeSpec.fromMap(spec);
    components[node.id] = node;
    if (node.name != null && node.name!.isNotEmpty) {
      components[node.name!] = node;
    }
  }

  void upsertAction(Map spec) {
    final node = ActionNodeSpec.fromMap(spec);
    actions[node.id] = node;
    if (node.name != null && node.name!.isNotEmpty) {
      actions[node.name!] = node;
    }
  }

  void upsertRequest(Map spec) {
    final node = RootNodeSpec.fromMap(spec);
    requests[node.type] = node;
    if (node.name != null && node.name!.isNotEmpty) {
      requests[node.name!] = node;
    }
  }

  WidgetNodeSpec? getScreen(String id) {
    if (screens.containsKey(id)) {
      return screens[id]?.clone();
    }
    return null;
  }

  WidgetNodeSpec? getTemplate(String id) {
    if (templates.containsKey(id)) {
      return templates[id]?.clone();
    }
    return null;
  }

  WidgetNodeSpec? getComponent(String id) {
    if (components.containsKey(id)) {
      return components[id]?.clone();
    }
    return null;
  }

  ActionNodeSpec? getAction(String id) {
    if (actions.containsKey(id)) {
      return actions[id]?.clone();
    }
    return null;
  }

  RootNodeSpec? getRequest(String id) {
    if (requests.containsKey(id)) {
      return requests[id]?.clone();
    }
    return null;
  }

  void merge(Solution otherSolution) {
    for (var key in otherSolution.screens.keys) {
      screens[key] = otherSolution.screens[key]!;
    }
    for (var key in otherSolution.templates.keys) {
      templates[key] = otherSolution.templates[key]!;
    }
    for (var key in otherSolution.components.keys) {
      components[key] = otherSolution.components[key]!;
    }
    for (var key in otherSolution.requests.keys) {
      requests[key] = otherSolution.requests[key]!;
    }
  }

  static String? get environment => _currentEnvironment;
  static String get language => _language;
  static List<String> get languages => stringResources.languages;

  static Solution fromMap(Map solutionData, String environment,
      {String language = "en"}) {
    environmentData
        .merge(EnvironmentData.fromMap(solutionData["environmentData"]));
    setEnvironment(environment);

    stringResources
        .merge(StringResources.fromMap(solutionData["stringResources"]));
    setLanguage(language);

    final screens = (solutionData["screens"] ?? <Map>[]) as List<Map>;
    final templates = solutionData["templates"] ?? [];
    final components = solutionData["components"] ?? [];
    final actions = solutionData["actions"] ?? [];
    final requests = solutionData["types"] ?? [];
    final screenMap = <String, WidgetNodeSpec>{};
    final templateMap = <String, WidgetNodeSpec>{};
    final componentMap = <String, WidgetNodeSpec>{};
    final actionMap = <String, ActionNodeSpec>{};
    final requestMap = <String, RootNodeSpec>{};

    for (var screen in screens) {
      final node = WidgetNodeSpec.fromMap(screen);
      screenMap[node.id] = node;
      final routeName = node.props["routeName"] as String?;
      if (routeName != null && routeName.isNotEmpty) {
        screenMap[routeName] = node;
      }
    }
    for (var template in templates) {
      final node = WidgetNodeSpec.fromMap(template);
      templateMap[node.id] = node;
      if (node.name != null && node.name!.isNotEmpty) {
        templateMap[node.name!] = node;
      }
    }
    for (var component in components) {
      final node = WidgetNodeSpec.fromMap(component);
      componentMap[node.id] = node;
      if (node.name != null && node.name!.isNotEmpty) {
        componentMap[node.name!] = node;
      }
    }
    for (var action in actions) {
      final node = ActionNodeSpec.fromMap(action);
      actionMap[node.type] = node;
      if (node.name != null && node.name!.isNotEmpty) {
        actionMap[node.name!] = node;
      }
    }
    for (var request in requests) {
      final node = RootNodeSpec.fromMap(request);
      requestMap[node.type] = node;
      if (node.name != null && node.name!.isNotEmpty) {
        requestMap[node.name!] = node;
      }
    }

    return Solution._(
      solutionData["name"] ?? "",
      solutionData["type"] ?? "",
      solutionData["landingScreen"] ??
          (screens.isNotEmpty ? screens[0]["_id"] : ""),
      screenMap,
      templateMap,
      componentMap,
      actionMap,
      requestMap,
    );
  }

  static Solution empty(String name, String environment,
      {String landingScreen = "", String language = "en"}) {
    return Solution._(name, "", landingScreen, {}, {}, {}, {}, {});
  }

  static void setEnvironment(String environment) {
    _currentEnvironment = environment;
    environmentVariables = environmentData.environments[environment] ?? {};
  }

  static bool setLanguage(String? language) {
    language ??= "en";
    var resources = stringResources.getLanguageResources(language);
    if (resources == null) {
      // A language code can be something like 'en', 'en-US' or 'en_US'
      language = language.split("-")[0].split("_")[0];
      resources = stringResources.getLanguageResources(language);
    }

    if (resources == null) {
      return false;
    }

    _language = language;
    Strings.load(resources, clear: true);
    return true;
  }
}

class EnvironmentData {
  final Map<String, Map<String, String>> environments;

  EnvironmentData(this.environments);

  void merge(EnvironmentData other) {
    for (var env in other.environments.keys) {
      var otherEnvData = other.environments[env]!;
      if (environments.containsKey(env)) {
        var envData = environments[env]!;
        for (var key in otherEnvData.keys) {
          envData[key] = otherEnvData[key]!;
        }
      } else {
        environments[env] = otherEnvData;
      }
    }
  }

  static EnvironmentData fromMap(Map? environmentData) {
    Map<String, Map<String, String>> map = {};
    if (environmentData != null) {
      final environments = environmentData["environments"] as List;
      final keys = environmentData["keys"] != null
          ? environmentData["keys"] as List
          : [];
      final values = environmentData["values"] != null
          ? environmentData["values"] as List<List>
          : [];

      for (var i = 0; i < environments.length; i++) {
        Map<String, String> environmentMap = {};
        for (var j = 0; j < keys.length; j++) {
          var key = keys[j];
          var value = values[j][i] ?? "";
          environmentMap[key] = value;
        }
        map[environments[i]] = environmentMap;
      }
    }
    return EnvironmentData(map);
  }
}

class StringResources {
  final Map<String, Map<String, String>> _resources;

  StringResources(this._resources);

  List<String> get languages => _resources.keys.toList(growable: false);

  Map<String, String>? getLanguageResources(String language) {
    if (!_resources.containsKey(language)) return null;
    return _resources[language];
  }

  void merge(StringResources other) {
    for (var lang in other.languages) {
      var otherResources = other.getLanguageResources(lang)!;
      if (_resources.containsKey(lang)) {
        var resources = _resources[lang]!;
        for (var key in otherResources.keys) {
          resources[key] = otherResources[key]!;
        }
      } else {
        _resources[lang] = otherResources;
      }
    }
  }

  static StringResources fromMap(Map? stringResourcesData) {
    Map<String, Map<String, String>> map = {};
    if (stringResourcesData != null) {
      final entries = stringResourcesData["languages"] as List;
      final keys = stringResourcesData["keys"] != null
          ? stringResourcesData["keys"] as List
          : [];
      final values = stringResourcesData["values"] != null
          ? stringResourcesData["values"] as List<List>
          : [];

      for (var i = 0; i < entries.length; i++) {
        Map<String, String> entriesMap = {};
        for (var j = 0; j < keys.length; j++) {
          var key = keys[j];
          var value = values[j][i] ?? "";
          entriesMap[key] = value;
        }
        map[entries[i]] = entriesMap;
      }
    }
    return StringResources(map);
  }
}
