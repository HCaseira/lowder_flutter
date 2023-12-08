import 'dart:core';

class SolutionException implements Exception {
  final String message;

  SolutionException(this.message);

  @override
  String toString() => message;
}