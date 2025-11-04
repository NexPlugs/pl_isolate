import 'dart:async';
import 'dart:isolate';
import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:flutter/services.dart';
import 'package:pl_isolate/src/isolate_operation.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate_logger.dart';
import 'utils/logger.dart';
import 'package:nanoid/nanoid.dart';

const alphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

String generateThreadId(String task) {
  return "${task}_${customAlphabet(alphabet, 22)}";
}

/// Isolate helper to help with isolate communication
///
/// Format of the message from sub thread to main thread:
/// [threadId, action, args, SendPort] -> SendPort is the port to send the answer to the main isolate

/// Format of the message from main thread to sub thread
/// If data susccess:
/// [threadId, data, null]
///
/// If data error:
/// [threadId, null, exception]

@pragma("vm:entry-point")
abstract class IsolateHelper<T> {
  static const String tag = "IsolateHelper";

  /// Commands to send to isolate
  static const String actionLog = 'log';
  static const String actionError = 'error';
  static const String actionUnknown = 'unknown';

  late final dynamic _isolate;

  /// Timer to dispose the isolate if it is inactive for 10 seconds
  Timer? _inactiveTimer;

  late final ReceivePort _receivePort;

  late final SendPort _mainSendPort;

  final _initLock = Lock();
  final _runLock = Lock();

  int _activeThread = 0;

  bool get autoDispose => true;

  ///[dispose] If the isolate is auto disposed
  /// Is the isolate auto disposed
  bool get isAutoDispose;

  /// Interval to dispose the isolate if it is inactive for 10 seconds
  Duration get autoDisposeInterval => const Duration(seconds: 10);

  /// Is the isolate a Dart isolate
  bool get isDartIsolate;

  /// Name of the isolate
  String get name;

  /// Is the isolate spawned
  bool _isIsolateSpawn = false;

  /// Is the isolate spawned
  bool get isIsolateSpawn => _isIsolateSpawn;

  /// Initialize the isolate
  Future<void> _initIsolate(IsolateOperation operation) async {
    return _initLock.synchronized(() async {
      if (_isIsolateSpawn) return;

      _receivePort = ReceivePort();

      final rootToken = RootIsolateToken.instance;

      if (rootToken == null && !isDartIsolate) {
        Logger.e(tag, 'Root isolate token is not set');
        throw Exception('Root isolate token is not set');
      }

      try {
        if (isDartIsolate) {
          _isolate = await DartUiIsolate.spawn<List<dynamic>>(
            _isolateMainTopLevel,
            [_receivePort.sendPort, null, name, operation],
          );
        } else {
          _isolate = await Isolate.spawn(
              _isolateMainTopLevel,
              [
                _receivePort.sendPort,
                rootToken,
                name,
                operation,
              ],
              debugName: name);
        }

        _mainSendPort = await _receivePort.first as SendPort;

        _isIsolateSpawn = true;
      } catch (e) {
        Logger.e(tag, 'Error initializing isolate: $e');
        _isIsolateSpawn = false;
        throw Exception('Error initializing isolate: $e');
      }
    });
  }

  // Run the isolate and return the result
  Future<T> runIsolate(dynamic args, IsolateOperation operation) async {
    Logger.d(tag, 'Running isolate: $name');

    await _initIsolate(operation);

    return _runLock.synchronized(() async {
      Logger.d(tag, 'Running isolate: $name');
      if (autoDispose) _resetTimer();

      final completer = Completer<T>();

      final answerPort = ReceivePort();

      _activeThread++;
      final threadId = generateThreadId(name);

      _mainSendPort.send([threadId, operation.tag, args, answerPort.sendPort]);

      answerPort.listen((message) {
        IsolateLogger.instance.log(tag, 'Message received: $message');

        final receivedThreadId = message[0] as String;
        if (receivedThreadId != threadId) {
          Logger.e(
            tag,
            'Received thread id does not match the expected thread id: $receivedThreadId != $threadId',
          );
          return;
        }

        // Isolate logger to log the message
        IsolateLogger.instance.log(tag, 'Message received: $message');

        final result = message[1] as dynamic;
        final exception = message[2] as dynamic;

        if (exception != null) {
          completer.completeError(exception);
          return;
        }

        completer.complete(result);
      });

      _activeThread--;

      return completer.future;
    });
  }

  /// Isolate main top level function
  /// This function is used to handle the message from the isolate and send the message to the main isolate
  static void _isolateMainTopLevel(List<dynamic> message) {
    const tag = IsolateHelper.tag;
    final sendPort = message[0] as SendPort;
    final rootToken = message[1] as RootIsolateToken?;
    final isolateName = message[2] as String;
    final operation = message[3] as IsolateOperation;

    IsolateLogger.instance.log(tag, 'Isolate initialized: $isolateName');

    final recieverPort = ReceivePort();

    sendPort.send(recieverPort.sendPort);

    if (rootToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    }

    recieverPort.listen((message) async {
      IsolateLogger.instance.log(tag, 'Main message received: $message');

      final threadId = message[0] as String;
      final action = message[1] as String;
      final args = message[2] as dynamic;
      final answerPort = message[3] as SendPort;

      // First message might be handler setup

      // Check tag to handler operation
      if (action.startsWith(operation.tag)) {
        IsolateLogger.instance.log(tag, 'Operation: ${operation.tag}');
        try {
          final result = await operation.run(args);
          answerPort.send([threadId, result, null]);
          IsolateLogger.instance.log(tag, 'Result: $result');
        } catch (exception) {
          IsolateLogger.instance.error(
            tag,
            'Error in operation: $exception',
            exception,
          );
          answerPort.send([threadId, null, exception]);
        }
      } else {
        switch (action) {
          case IsolateHelper.actionLog:
            IsolateLogger.instance.log(tag, args);
            break;
          case IsolateHelper.actionError:
            IsolateLogger.instance.error(tag, args, args[1]);
            break;

          case IsolateHelper.actionUnknown:
            IsolateLogger.instance.error(tag, 'Unknown action: $action', null);
            break;

          default:
            IsolateLogger.instance.error(tag, 'Unknown action: $action', null);
            break;
        }
      }

      /// Handle the action if need
    });
  }

  /// Reset the timer to dispose the isolate if it is inactive for 10 seconds
  void _resetTimer() {
    _inactiveTimer?.cancel();
    _inactiveTimer = Timer.periodic(autoDisposeInterval, (timer) {
      if (_activeThread > 0) {
        _resetTimer();
      } else {
        dispose();
      }
    });
  }

  /// Dispose the isolate
  Future<void> dispose() async {
    if (!_isIsolateSpawn) return;
    _isIsolateSpawn = false;
    _isolate.kill();
    _receivePort.close();
  }

  Stream<dynamic> get messages;
}
