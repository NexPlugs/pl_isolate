import 'dart:async';
import 'package:collection/collection.dart';
import 'package:pl_isolate/src/utils/logger.dart';

import 'isolate_helper.dart';

class IsolateResult {
  final dynamic result;
  final String name;
  final String? errorMessage;

  IsolateResult({
    required this.result,
    required this.name,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'IsolateResult(result: $result, name: $name, errorMessage: $errorMessage)';
  }
}

// Isolate manager to manage the isolates
class IsolateManager {
  static const String tag = 'IsolateManager';

  IsolateManager._({
    required int maxConcurrentTasks,
    required int maxSizeOfQueue,
  })  : _maxConcurrentTasks = maxConcurrentTasks,
        _maxSizeOfQueue = maxSizeOfQueue;

  // Initialize the isolate manager
  factory IsolateManager.init(
    int maxConcurrentTasks,
    int maxSizeOfQueue,
  ) {
    final instance = IsolateManager._(
      maxConcurrentTasks: maxConcurrentTasks,
      maxSizeOfQueue: maxSizeOfQueue,
    );
    _instance = instance;
    return instance;
  }

  // Get the isolate manager instance
  static IsolateManager get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'IsolateManager has not been initialized. Call IsolateManager.init() first.',
      );
    }
    return instance;
  }

  static IsolateManager? _instance;
  static bool get isInitialized => _instance != null;

  void logInformation() {
    Logger.i(tag, 'Queue size: ${_isolateQueue.length}');
    Logger.i(tag, 'Running isolates: ${_runningIsolates.length}');
    Logger.i(tag, 'Arguments: $arguments');
    Logger.i(tag, 'Retries: $retries');
  }

  // Queue to store the isolate helpers and operations
  final HeapPriorityQueue<IsolateHelper> _isolateQueue =
      HeapPriorityQueue<IsolateHelper>(
    (a, b) => a.priority.level.compareTo(b.priority.level),
  );

  late final int _maxConcurrentTasks;
  late final int _maxSizeOfQueue;

  final List<IsolateHelper> _runningIsolates = [];
  final Map<String, dynamic> arguments = {};
  final Map<String, int> retries = {};

  /// Stream to listen to the isolate result
  final StreamController<IsolateResult> _isolateResultStream =
      StreamController<IsolateResult>.broadcast();

  /// Listen to the isolate result stream
  /// [listener] is the function to listen to the isolate result
  void listenIsolateResult(Function(IsolateResult) listener) {
    _isolateResultStream.stream.listen(listener);
  }

  /// Add a new isolate helper to the queue
  void addIsolateHelper(
    IsolateHelper isolateHelper,
    dynamic args,
  ) {
    if (_isolateQueue.length >= _maxSizeOfQueue) {
      throw Exception('Max size of queue reached');
    }
    final uniqCode = isolateHelper.uniqCode;
    _isolateQueue.add((isolateHelper));

    arguments[uniqCode] = args;
    retries[uniqCode] = 0;
  }

  /// Run isolates in batches, each batch limited by [_maxConcurrentTasks]
  Future<void> runAllInBatches() async {
    Logger.i(
        tag, 'Starting batch execution with max $_maxConcurrentTasks tasks.');

    while (_isolateQueue.isNotEmpty) {
      final batch = <IsolateHelper>[];
      for (int i = 0;
          i < _maxConcurrentTasks && _isolateQueue.isNotEmpty;
          i++) {
        final item = _isolateQueue.removeFirst();
        batch.add(item);
      }

      await Future.wait(batch.map((item) async {
        final result = await runIsolate(item, arguments[item.uniqCode]);

        _isolateResultStream.add(result);
      }));

      Logger.i(tag, 'Batch done ✅');
    }

    Logger.i(tag, 'All isolates completed 🎉');
  }

  /// Run a single isolate and return the result
  Future<IsolateResult> runIsolate(
      IsolateHelper isolateHelper, dynamic args) async {
    final uniqueCode = isolateHelper.uniqCode;

    _runningIsolates.add(isolateHelper);

    try {
      final result = await isolateHelper.runIsolate(args);

      isolateHelper.dispose();
      arguments.remove(uniqueCode);
      retries.remove(uniqueCode);

      return IsolateResult(result: result, name: uniqueCode);
    } catch (e, st) {
      Logger.e(tag, 'Error running isolate ${isolateHelper.name}: $e\n$st');
      if (isolateHelper.retryCount > 0 &&
          (retries[uniqueCode] ?? 0) < isolateHelper.retryCount) {
        retries[uniqueCode] = (retries[uniqueCode] ?? 0) + 1;
        _isolateQueue.add((isolateHelper));
      } else {
        retries.remove(uniqueCode);
        arguments.remove(uniqueCode);

        isolateHelper.dispose();
      }

      return IsolateResult(
          result: null, name: isolateHelper.name, errorMessage: e.toString());
    } finally {
      _runningIsolates.remove(isolateHelper);
    }
  }

  /// Dispose all the isolate helpers
  void disposeAll() {
    while (_isolateQueue.isNotEmpty) {
      final (isolateHelper) = _isolateQueue.removeFirst();
      isolateHelper.dispose();
    }
    for (var isolateHelper in _runningIsolates) {
      isolateHelper.dispose();
    }
    _runningIsolates.clear();
    arguments.clear();
    retries.clear();

    _isolateResultStream.close();
  }
}
