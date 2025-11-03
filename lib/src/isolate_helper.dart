import 'dart:async';
import 'dart:isolate';
import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:flutter/services.dart';
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

  /// ....

  late final dynamic _isolate;

  /// Timer to dispose the isolate if it is inactive for 10 seconds
  Timer? _inactiveTimer;

  late final ReceivePort _receivePort;

  late final SendPort _sendPort;

  final _initLock = Lock();
  final _runLock = Lock();

  int _activeThread = 0;

  bool get autoDispose => true;

  /// Operation handler to handle the operation
  Future<T> Function(dynamic args) get operationHandler;

  /// Interval to dispose the isolate if it is inactive for 10 seconds
  Duration get autoDisposeInterval => const Duration(seconds: 10);

  /// Send port to send message to isolate
  SendPort get sendPort => _sendPort;

  /// Is the isolate a Dart isolate
  bool get isDartIsolate;

  /// Is the isolate auto disposed
  bool get isAutoDispose;

  /// Name of the isolate
  String get name;

  /// Operation tag to identify the operation
  String get operationTag;

  /// Is the isolate spawned
  bool _isIsolateSpawn = false;

  /// Is the isolate spawned
  bool get isIsolateSpawn => _isIsolateSpawn;

  /// Initialize the isolate
  Future<void> _initIsolate() async {
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
          _isolate = await DartUiIsolate.spawn<List<SendPort?>>(_isolateMain, [
            _receivePort.sendPort,
            null,
          ]);
        } else {
          _isolate = await Isolate.spawn(_isolateMain, [
            _receivePort.sendPort,
            rootToken,
          ], debugName: name);
        }

        _sendPort = await _receivePort.first as SendPort;

        _isIsolateSpawn = true;
      } catch (e) {
        Logger.e(tag, 'Error initializing isolate: $e');
        _isIsolateSpawn = false;
        throw Exception('Error initializing isolate: $e');
      }
    });
  }

  /// Main isolate entry point
  ///
  /// [message] is the message from the main isolate
  /// [message[0]] is the send port to send message to main isolate
  /// [message[1]] is the root token to send message to main isolate
  void _isolateMain(List<dynamic> message) {
    final sendPort = message[0] as SendPort;
    final rootToken = message[1] as RootIsolateToken?;

    IsolateLogger.instance.log(tag, 'Isolate initialized');

    final recieverPort = ReceivePort();

    sendPort.send(recieverPort.sendPort);

    if (rootToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    }

    recieverPort.listen((message) async {
      IsolateLogger.instance.log(tag, 'Message received: $message');

      final threadId = message[0] as String;
      final action = message[1] as String;
      final args = message[2] as dynamic;

      // Check tag to handler operation
      if (action.startsWith(operationTag)) {
        try {
          final result = await operationHandler(args);
          sendPort.send([threadId, result, null]);
        } catch (exception) {
          IsolateLogger.instance.error(
            tag,
            'Error in operation: $exception',
            exception,
          );
          sendPort.send([threadId, null, exception]);
          return;
        }
      }

      /// Handle the action if need
      switch (action) {
        case actionLog:
          IsolateLogger.instance.log(tag, args);
          break;
        case actionError:
          IsolateLogger.instance.error(tag, args, args[1]);
          break;

        case actionUnknown:
          IsolateLogger.instance.error(tag, 'Unknown action: $action', null);
          break;

        default:
          IsolateLogger.instance.error(tag, 'Unknown action: $action', null);
          break;
      }
    });
  }

  // Run the isolate and return the result
  Future<T> runIsolate(dynamic args) async {
    await _initIsolate();

    return _runLock.synchronized(() async {
      if (autoDispose) _resetTimer();

      final completer = Completer<T>();

      final answerPort = ReceivePort();

      _activeThread++;
      final threadId = generateThreadId(name);

      _sendPort.send([threadId, tag, args, answerPort.sendPort]);

      answerPort.listen((message) {
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
