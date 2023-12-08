import 'package:flutter/material.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DemoApp(environment: "Dev", editorMode: true));
}
