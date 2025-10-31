import 'package:flutter/foundation.dart';

enum LogLevel { info, debug, error }

final class Logger {
  Logger._();

  static void log(
    Object tag,
    String message, {
    LogLevel level = LogLevel.info,
  }) {
    if (kReleaseMode) return;

    String tagStr = switch (tag) {
      String s => s,
      Type t => t.toString(),
      _ => tag.runtimeType.toString(),
    };
    debugPrint('${level.name.toUpperCase()} $tagStr: $message');
  }

  static void i(Object tag, String message) =>
      log(tag, message, level: LogLevel.info);

  static void d(Object tag, String message) =>
      log(tag, message, level: LogLevel.debug);

  static void e(Object tag, String message) =>
      log(tag, message, level: LogLevel.error);
}
