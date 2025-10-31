import 'dart:isolate';
import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate_logger.dart';
import 'utils/logger.dart';

/// Isolate helper to help with isolate communication
/// [T] is the operation object to send to isolate
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

  final _initLock = Lock();

  bool _isIsolateSpawn = false;
  bool get isIsolateSpawn => _isIsolateSpawn;

  Future<void> initIsolate() async {
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

    recieverPort.listen((message) {
      IsolateLogger.instance.log(tag, 'Message received: $message');

      final command = message[0] as String;
      final data = message[1] as dynamic;

      switch (command) {
        case 'log':
          IsolateLogger.instance.log(tag, data);
          break;
      }
    });
  }

  bool get isRunning;

  Future<void> start();

  Future<void> dispose();

  void post(dynamic message);

  Stream<dynamic> get messages;

  Future<R> runOperation<R>(T operation);
}
