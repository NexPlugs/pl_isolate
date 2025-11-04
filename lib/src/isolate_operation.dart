import 'dart:async';

/// Isolate operation to run in isolate
abstract class IsolateOperation {
  /// Tag of the operation
  String get tag;

  /// Run the operation
  Future<dynamic> run(dynamic args);
}
