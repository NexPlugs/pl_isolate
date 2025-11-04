import 'dart:collection';

import 'utils/logger.dart';

/// Isolate log to log messages from isolate
class IsolateLog {
  final String tag;
  final String message;
  final Object? error;

  IsolateLog({required this.tag, required this.message, this.error});

  @override
  String toString() {
    return 'IsolateLog(tag: $tag, message: $message, error: $error)';
  }
}

/// Isolate logger to log messages from isolate
/// Use to log messages from isolate to main isolate
class IsolateLogger {
  IsolateLogger._();

  static IsolateLogger get instance => _instance;
  static final _instance = IsolateLogger._();

  final Queue<IsolateLog> _logs = Queue<IsolateLog>();

  void log(String tag, String message) {
    _logs.add(IsolateLog(tag: tag, message: message));
    Logger.d(tag, 'Isolate log: $message');
  }

  void error(String tag, String message, Object? error) {
    _logs.add(IsolateLog(tag: tag, message: message, error: error));
    Logger.e(tag, 'Isolate error: $message');
  }

  void info(String tag, String message) {
    _logs.add(IsolateLog(tag: tag, message: message));
    Logger.i(tag, 'Isolate info: $message');
  }

  void logRecordIsolate() {
    final logs = _logs.toList();
    _logs.clear();
    for (var log in logs) {
      Logger.log(log.tag, log.toString());
    }
  }
}
