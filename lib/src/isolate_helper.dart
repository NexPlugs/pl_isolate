import 'dart:async';
import 'dart:isolate';
import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:flutter/services.dart';
import 'package:pl_isolate/src/isolate_cache.dart';
import 'package:pl_isolate/src/isolate_operation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:nanoid/nanoid.dart';

import 'isolate_logger.dart';
import 'utils/logger.dart';

const _alphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

String generateThreadId(String task) =>
    "${task}_${customAlphabet(_alphabet, 22)}";

/// Isolate helper to simplify isolate creation, caching and communication.
///
/// Message formats:
/// - From sub isolate to main: `[threadId, action, args, SendPort]`
/// - From main isolate to sub isolate:
///   - Success: `[threadId, data, null]`
///   - Error: `[threadId, null, exception]`
@pragma("vm:entry-point")
abstract class IsolateHelper<T> {
  static const String tag = "IsolateHelper";

  // Common actions
  static const String actionLog = 'log';
  static const String actionError = 'error';
  static const String actionUnknown = 'unknown';

  late final dynamic _isolate;
  late final ReceivePort _receivePort;
  late final SendPort _mainSendPort;

  final _initLock = Lock();
  final _runLock = Lock();

  Timer? _inactiveTimer;
  IsolateCache<String, dynamic>? _cache;

  bool _isIsolateSpawn = false;
  int _activeThread = 0;

  /// Configurations
  bool get autoDispose => true;
  bool get isAutoDispose;
  bool get isDartIsolate;
  String get name;

  Duration get autoDisposeInterval => const Duration(seconds: 10);
  int? get maxCacheEntries => null;
  Duration? get defaultCacheTtl => null;

  bool get isIsolateSpawn => _isIsolateSpawn;

  /// Lazy cache initialization
  IsolateCache<String, dynamic>? get cache {
    if (_cache == null &&
        (maxCacheEntries != null || defaultCacheTtl != null)) {
      _cache = IsolateCache<String, dynamic>(
        maxEntries: maxCacheEntries,
        defaultTtl: defaultCacheTtl,
      );
    }
    return _cache;
  }

  /// Initialize isolate
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
            [_receivePort.sendPort, rootToken, name, operation],
            debugName: name,
          );
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

  /// Run an isolate task and return result
  Future<T> runIsolate(dynamic args, IsolateOperation operation) async {
    Logger.d(tag, 'Running isolate: $name');
    await _initIsolate(operation);

    return _runLock.synchronized(() async {
      if (autoDispose) _resetTimer();

      final completer = Completer<T>();
      final answerPort = ReceivePort();

      // Return cached data if available
      final cached = _cache?.get(name);
      if (cached != null) {
        completer.complete(cached);
        return completer.future;
      }

      _activeThread++;
      final threadId = generateThreadId(name);

      _mainSendPort.send([threadId, operation.tag, args, answerPort.sendPort]);

      answerPort.listen((message) {
        IsolateLogger.instance.log(tag, 'Message received: $message');

        final receivedThreadId = message[0] as String;
        if (receivedThreadId != threadId) {
          Logger.e(tag,
              'Received thread id does not match expected: $receivedThreadId != $threadId');
          return;
        }

        final result = message[1];
        final exception = message[2];

        if (exception != null) {
          completer.completeError(exception);
        } else {
          _cache?.set(name, result, ttl: defaultCacheTtl);
          completer.complete(result);
        }
      });

      _activeThread--;
      return completer.future;
    });
  }

  /// Main isolate entry point
  static void _isolateMainTopLevel(List<dynamic> message) {
    const tag = IsolateHelper.tag;
    final sendPort = message[0] as SendPort;
    final rootToken = message[1] as RootIsolateToken?;
    final isolateName = message[2] as String;
    final operation = message[3] as IsolateOperation;

    IsolateLogger.instance.log(tag, 'Isolate initialized: $isolateName');

    final receiverPort = ReceivePort();
    sendPort.send(receiverPort.sendPort);

    if (rootToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    }

    receiverPort.listen((message) async {
      IsolateLogger.instance.log(tag, 'Main message received: $message');

      final threadId = message[0] as String;
      final action = message[1] as String;
      final args = message[2];
      final answerPort = message[3] as SendPort;

      if (action.startsWith(operation.tag)) {
        try {
          final result = await operation.run(args);
          answerPort.send([threadId, result, null]);
        } catch (exception) {
          IsolateLogger.instance
              .error(tag, 'Error in operation: $exception', exception);
          answerPort.send([threadId, null, exception]);
        }
      } else {
        IsolateLogger.instance.error(tag, 'Unknown action: $action', null);
      }
    });
  }

  /// Reset auto-dispose timer
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

  /// Dispose isolate resources
  Future<void> dispose() async {
    if (!_isIsolateSpawn) return;
    _isIsolateSpawn = false;
    _isolate.kill();
    _receivePort.close();
    _cache?.clear();
    _cache = null;
  }
}
