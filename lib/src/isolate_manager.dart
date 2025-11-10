import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pl_isolate/src/utils/logger.dart';

import 'isolate_helper.dart';
import 'isolate_operation.dart';

/// Isolate manager to manage isolate helpers
class IsolateManager {
  static const String tag = 'IsolateManager';

  IsolateManager._({
    required int maxConcurrentTasks,
    required int maxSizeOfQueue,
  })  : _maxConcurrentTasks = maxConcurrentTasks,
        _maxSizeOfQueue = maxSizeOfQueue;

  factory IsolateManager.init(
    int maxConcurrentTasks,
    int maxSizeOfQueue,
  ) {
    _instance = IsolateManager._(
      maxConcurrentTasks: maxConcurrentTasks,
      maxSizeOfQueue: maxSizeOfQueue,
    );
    return _instance;
  }

  static IsolateManager get instance => _instance;
  static late final IsolateManager _instance;

  final HeapPriorityQueue<IsolateHelper> _isolateQueue =
      HeapPriorityQueue<IsolateHelper>(
    (a, b) => a.priority.level.compareTo(b.priority.level),
  );

  late final int _maxConcurrentTasks;
  late final int _maxSizeOfQueue;

  //init

  final List<IsolateHelper> _runningIsolates = [];
  final Map<String, dynamic> arguments = {};
  final Map<String, IsolateOperation> operations = {};
  final Map<String, int> retries = {};

  Timer? _schedulerTimer = null;

  /// Add the isolate helper to the manager
  /// [isolateHelper] is the isolate helper to add
  void addIsolateHelper(IsolateHelper isolateHelper, IsolateOperation operation,
      dynamic arguments,
      {Duration? delay}) {
    if (_isolateQueue.length >= _maxSizeOfQueue) {
      throw Exception('Max size of queue reached');
    }

    _isolateQueue.add(isolateHelper);
    arguments[isolateHelper.name] = arguments;
    operations[isolateHelper.name] = operation;
  }

  /// Remove the isolate helper from the manager
  /// [name] is the name of the isolate helper to remove
  void removeIsolateHelper(String name) {}

  void startSchedulerLoop() async {
    _schedulerTimer ??=
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_isolateQueue.isEmpty) return;
      if (_runningIsolates.length >= _maxConcurrentTasks) return;

      final readyTask = _isolateQueue.firstWhereOrNull((t) => t.isReady);
      if (readyTask == null) return;

      _isolateQueue.remove(readyTask);
      _runTask(readyTask);
    });
  }

  Future<void> _runTask(IsolateHelper isolateHelper) async {
    _runningIsolates.add(isolateHelper);
    try {
      final result = await isolateHelper.runIsolate(
          arguments[isolateHelper.name], operations[isolateHelper.name]!);
    } catch (e) {
      Logger.e(tag, 'Error running task: $e');
      if (isolateHelper.retryCount > 0 &&
          retries[isolateHelper.name] != null &&
          retries[isolateHelper.name]! < isolateHelper.retryCount) {
        retries[isolateHelper.name] = (retries[isolateHelper.name] ?? 0) + 1;
        _isolateQueue.add(isolateHelper);
      }
    } finally {
      _runningIsolates.remove(isolateHelper);

      // Remove all map data
      retries.remove(isolateHelper.name);
      arguments.remove(isolateHelper.name);
      operations.remove(isolateHelper.name);
    }
  }

  /// Dispose all the isolate helpers
  void disposeAll() {
    while (_isolateQueue.isNotEmpty) {
      final isolateHelper = _isolateQueue.removeFirst();
      isolateHelper.dispose();
    }
    _runningIsolates.clear();
    arguments.clear();
    operations.clear();
    retries.clear();
  }
}
