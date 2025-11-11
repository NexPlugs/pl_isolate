import 'dart:async';

import 'package:flutter/material.dart' show UniqueKey;

/// Isolate operation to run in isolate
abstract class IsolateOperation {
  /// Tag of the operation
  String get tag;

  /// Run the operation
  Future<dynamic> run(dynamic args);

  // Generate hash code for the operation. This value is used to identify the operation in the isolate manager.
  String get uniqueCode => UniqueKey().toString();
}
