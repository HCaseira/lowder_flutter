import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'editor.dart';

Future main(List<String> args) async {
  int port = 8787;
  final idx = args.indexOf("-p");
  if (idx >= 0 && args.length > idx) {
    port = num.tryParse(args[idx + 1])?.toInt() ?? port;
  }
  HttpServer().start(port: port);
}

class HttpServer {
  final List<String> _toEditor = [];
  final Map<String, List<String>> _toClients = {};

  void start({int port = 8787, String? flutterPath}) async {
    if (flutterPath == null || flutterPath.isEmpty) {
      flutterPath = Directory.current.path;
      var file = File("$flutterPath/pubspec.yaml");
      if (!await file.exists()) {
        logError("No Flutter project found in path $flutterPath");
        return;
      }
    }

    final flutterWebPath = "$flutterPath/build/web";
    final buildResult = await _buildFlutterWeb(flutterPath, port);
    if (!buildResult) {
      return;
    }
    if (!(await Directory(flutterWebPath).exists())) {
      logError("Path to Flutter Web build not found!");
      logError("Probably there are error in your code. Fix them and try again.");
      return;
    }

    final editorHtml = editorFiles["editor.html"];
    final editorCss = editorFiles["editor.css"];
    final editorJs = editorFiles["editor.js"];

    final cascade = Cascade()
        .add(shelf_static.createStaticHandler(flutterWebPath, serveFilesOutsidePath: true, defaultDocument: 'index.html'))
        .add((shelf_router.Router()
              ..get(
                  '/editor.html',
                  (r) => Response.ok(editorHtml,
                      headers: _getDefaultHeaders()..addAll({'content-type': 'text/html; charset=utf-8'})))
              ..get(
                  '/editor.css',
                  (r) => Response.ok(editorCss,
                      headers: _getDefaultHeaders()..addAll({'content-type': 'text/css; charset=utf-8'})))
              ..get(
                  '/editor.js',
                  (r) => Response.ok(editorJs,
                      headers: _getDefaultHeaders()..addAll({'content-type': 'text/javascript; charset=utf-8'})))
              // ..get('/schema', _getSchema)
              ..get('/editor', _editorPoll)
              ..post('/editor', _editorPost)
              ..get('/client', _clientPoll)
              ..post('/client', _clientPost)
              ..get(
                  '/environment',
                  (req) => Response.ok(jsonEncode(Platform.environment), headers: {
                        'content-type': 'application/json; charset=utf-8',
                      }))
              ..post('/loadSolutions', (req) => _loadSolutions(req))
              ..post('/saveSolutions', (req) => _saveSolutions(req))
              ..get('/rebuild', (req) => _rebuild(req, flutterPath, port)))
            .call);

    final server = await shelf_io.serve(
      cascade.handler,
      InternetAddress.anyIPv4,
      port,
    );

    log('Serving at http://${server.address.host}:${server.port}');
    log('Open Editor at http://localhost:${server.port}/editor.html');
  }

  Future<Response> _loadSolutions(Request request) async {
    final data = await request.readAsString();
    final files = <Map>[];
    if (data.isNotEmpty) {
      final paths = json.decode(data);
      for (var path in paths) {
        log("Loading solution file: $path");
        var file = File(path);
        if (!await file.exists()) {
          log("Solution file not found: $path");
          files.add({
            "path": path,
            "data": {},
          });
        } else {
          var fileData = await file.readAsString();
          files.add({
            "path": path,
            "data": json.decode(fileData),
          });
        }
      }
    }
    return Response.ok(json.encode(files), headers: _getDefaultHeaders());
  }

  Future<Response> _saveSolutions(Request request) async {
    const encoder = JsonEncoder.withIndent('  ');

    final data = await request.readAsString();
    final solutions = json.decode(data);
    for (var solution in solutions) {
      var path = solution["path"];
      var data = solution["data"];
      log("Saving solution file: $path");
      var file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await file.create();
      await file.writeAsString(encoder.convert(data));
    }
    return Response.ok(null, headers: _getDefaultHeaders());
  }

  Future<Response> _rebuild(Request request, flutterPath, int port) async {
    await _buildFlutterWeb(flutterPath, port);
    return Response.ok(null, headers: _getDefaultHeaders());
  }

  Future<bool> _buildFlutterWeb(String flutterPath, int port) async {
    log("Building Flutter Web client from '$flutterPath'.");
    final result = await Process.run(
      "flutter",
      [
        "build",
        "web",
        "--dart-define=LOWDER_ENV=Dev",
        "--dart-define=LOWDER_EDITOR=true",
        "--dart-define=LOWDER_SERVER=http://localhost:$port/",
        "--release",
        "--no-tree-shake-icons"
      ],
      workingDirectory: flutterPath,
      runInShell: true,
    );

    log("Flutter client build completed with result: ${result.exitCode}.");
    log("${result.stderr}");
    log("${result.stdout}");
    return result.exitCode == 0;
  }

  Future<Response> _editorPoll(Request request) async {
    var pollCount = 0;
    final headers = _getDefaultHeaders();
    while (_toEditor.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (pollCount > 100) {
        return Response.ok(null, headers: headers);
      }
      pollCount++;
    }

    final data = _toEditor.removeAt(0);
    headers['content-type'] = 'application/json; charset=utf-8';
    //log("Sending data to Editor: $data");
    return Response.ok(data, headers: headers);
  }

  Future<Response> _editorPost(Request request) async {
    final data = await request.readAsString();
    if (data.isNotEmpty) {
      //log("New data from Editor: $data");
      for (var key in _toClients.keys) {
        _toClients[key]!.add(data);
      }
    }
    return Response.ok(null, headers: _getDefaultHeaders());
  }

  Future<Response> _clientPoll(Request request) async {
    final clientId = request.url.queryParameters["id"];
    if (clientId == null || clientId.isEmpty) return Response.forbidden(null);
    if (!_toClients.containsKey(clientId)) _toClients[clientId] = [];

    var pollCount = 0;
    final clientArray = _toClients[clientId];
    final headers = _getDefaultHeaders();

    while (clientArray!.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (pollCount > 100) {
        return Response.ok(null, headers: headers);
      }
      pollCount++;
    }

    final data = clientArray.removeAt(0);
    headers['content-type'] = 'application/json; charset=utf-8';
    if (data.length > 200) {
      log("Sending large data to Client $clientId");
    } else {
      log("Sending data to Client $clientId: $data");
    }
    return Response.ok(data, headers: headers);
  }

  Future<Response> _clientPost(Request request) async {
    final data = await request.readAsString();
    if (data.isNotEmpty) {
      //log("New data from Client: $data");
      _toEditor.add(data);
    }
    return Response.ok(null, headers: _getDefaultHeaders());
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Header": "*",
      "Access-Control-Allow-Method": "*",
      "Cache-Control": "no-cache"
    };
  }

  log(String message) {
    stdout.writeln(message);
  }

  logError(String message) {
    stderr.writeln(message);
  }
}
