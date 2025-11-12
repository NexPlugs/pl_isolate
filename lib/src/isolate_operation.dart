import 'dart:async';

import 'package:flutter/material.dart' show UniqueKey;

/// Isolate operation to run in isolate
///
/// Usage:
/// class MyOperation implements IsolateOperation {
///   @override
///   String get tag => 'my_operation';
///   @override
///   Future<dynamic> run(dynamic args) async {
///     return 'Hello, world!';
///   }
/// }
///
/// In isolate communication, you can use this class to run the operation in the isolate.
/// This class is used to run the operation in the isolate.
abstract class IsolateOperation {
  /// Tag of the operation
  String get tag;

  /// Run the operation
  Future<dynamic> run(dynamic args);

  // Generate hash code for the operation. This value is used to identify the operation in the isolate manager.
  String uniqueCode = UniqueKey().toString();
}
