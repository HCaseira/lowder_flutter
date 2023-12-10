import 'dart:core';

/// Exception class with a message.
/// 'ActionFactory' will display this message as an error.
class SolutionException implements Exception {
  final String message;

  SolutionException(this.message);

  @override
  String toString() => message;
}
