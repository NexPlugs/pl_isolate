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

String generateTaskId(String task) {
  return "${task}_${customAlphabet(alphabet, 22)}";
}

/// Isolate helper to help with isolate communication
/// [T] is the operation object to send to isolate
///
/// Format of the message:
///
/// [threadId, action, args, SendPort] -> SendPort is the port to send the answer to the main isolate
/// action:
/// - 'run' -> run the operation
/// - 'log' -> log the message
/// - 'error' -> log the error
/// - 'info' -> log the info
/// - 'warning' -> log the warning
/// - 'debug' -> log the debug
/// - 'trace' -> log the trace
/// - 'fatal' -> log the fatal
/// - 'critical' -> log the critical
/// - 'alert' -> log the alert
/// - 'emergency' -> log the emergency
@pragma("vm:entry-point")
abstract class IsolateHelper<T extends Object> {
  static const String tag = "IsolateHelper";

  late final dynamic _isolate;

  late final ReceivePort _receivePort;

  late final SendPort _sendPort;
  SendPort get sendPort => _sendPort;

  bool get isDartIsolate;
  bool get isAutoDispose;
  String get name;

  String get operationTag;

  final _initLock = Lock();
  final _runLock = Lock();

  int _activeThread = 0;

  bool _isIsolateSpawn = false;
  bool get isIsolateSpawn => _isIsolateSpawn;

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
          _isolate = await DartUiIsolate.spawn<List<SendPort?>>(isolateMain, [
            _receivePort.sendPort,
            null,
          ]);
        } else {
          _isolate = await Isolate.spawn(isolateMain, [
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
  void isolateMain(List<dynamic> message) {
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

      final command = message[0] as String;
      final data = message[1] as dynamic;

      if (command.startsWith(operationTag)) {
        final operation = data as T;
        final result = await runOperation<dynamic>(operation);
        sendPort.send([operationTag, result]);
        return;
      }

      switch (command) {
        case 'log':
          IsolateLogger.instance.log(tag, data);
          break;
        case 'error':
          IsolateLogger.instance.error(tag, data, data[1]);
          break;

        default:
          IsolateLogger.instance.error(tag, 'Unknown command: $command', null);
          break;
      }
    });
  }

  Future<dynamic> runIsolate(Map<String, dynamic> args) async {
    await _initIsolate();

    return _runLock.synchronized(() async {
      final completer = Completer<dynamic>();
      final answerPort = ReceivePort();

      _activeThread++;
      final threadId = generateTaskId(name);

      _sendPort.send([threadId, tag, args, answerPort.sendPort]);

      answerPort.listen((message) {
        if (message[0] == threadId) {
          completer.complete(message[1]);
        }
      });

      _activeThread--;

      return completer.future;
    });
  }

  bool get isRunning;

  Future<void> start();

  Future<void> dispose() async {
    _isIsolateSpawn = false;
    _isolate.kill();
    _receivePort.close();
  }

  void post(dynamic message);

  Stream<dynamic> get messages;

  Future<R> runOperation<R>(T operation);
}
