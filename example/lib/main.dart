import 'package:flutter/material.dart';
import 'dart:async';

import 'package:pl_isolate/pl_isolate.dart';

// Example operation 1: Count operation
class CountableIsolateOperation implements IsolateOperation {
  @override
  String get tag => 'count';

  @override
  Future<dynamic> run(dynamic args) async {
    if (args is int) {
      int countable = 0;
      for (var i = 0; i < args; i++) {
        countable++;
      }
      return countable;
    }
    return 0;
  }
}

// Example operation 2: Calculate sum
class SumIsolateOperation implements IsolateOperation {
  @override
  String get tag => 'sum';

  @override
  Future<dynamic> run(dynamic args) async {
    if (args is List && args.isNotEmpty) {
      int sum = 0;
      for (var num in args) {
        if (num is int) {
          sum += num;
        }
      }
      return sum;
    }
    return 0;
  }
}

// Example operation 3: Simulate async work with delay
class DelayIsolateOperation implements IsolateOperation {
  @override
  String get tag => 'delay';

  @override
  Future<dynamic> run(dynamic args) async {
    if (args is Map && args.containsKey('duration')) {
      final duration = args['duration'] as int;
      await Future.delayed(Duration(milliseconds: duration));
      return 'Completed after ${duration}ms';
    }
    return 'Invalid arguments';
  }
}

// Example operation 4: Error handling
class ErrorIsolateOperation implements IsolateOperation {
  @override
  String get tag => 'error';

  @override
  Future<dynamic> run(dynamic args) async {
    throw Exception('This is a test error from isolate');
  }
}

// Isolate Helper implementations - mỗi helper cho một operation riêng

// Helper cho Count operation
class CountIsolateHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'CountIsolateHelper';

  @override
  bool get autoDispose => true;

  @override
  bool get isAutoDispose => true;
}

// Helper cho Sum operation
class SumIsolateHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'SumIsolateHelper';

  @override
  bool get autoDispose => true;

  @override
  bool get isAutoDispose => true;
}

// Helper cho Delay operation
class DelayIsolateHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'DelayIsolateHelper';

  @override
  bool get autoDispose => true;

  @override
  bool get isAutoDispose => true;
}

// Helper cho Error operation
class ErrorIsolateHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'ErrorIsolateHelper';

  @override
  bool get autoDispose => true;

  @override
  bool get isAutoDispose => true;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Mỗi helper riêng cho từng operation
  final CountIsolateHelper _countHelper = CountIsolateHelper();
  final SumIsolateHelper _sumHelper = SumIsolateHelper();
  final DelayIsolateHelper _delayHelper = DelayIsolateHelper();
  final ErrorIsolateHelper _errorHelper = ErrorIsolateHelper();

  // State cho từng operation
  String _countResult = 'No result yet';
  bool _countLoading = false;
  String? _countError;

  String _sumResult = 'No result yet';
  bool _sumLoading = false;
  String? _sumError;

  String _delayResult = 'No result yet';
  bool _delayLoading = false;
  String? _delayError;

  String _errorResult = 'No result yet';
  bool _errorLoading = false;
  String? _errorError;

  @override
  void dispose() {
    _countHelper.dispose();
    _sumHelper.dispose();
    _delayHelper.dispose();
    _errorHelper.dispose();
    super.dispose();
  }

  Future<void> _runCountOperation() async {
    setState(() {
      _countLoading = true;
      _countError = null;
      _countResult = 'Running...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final result = await _countHelper.runIsolate(
        10000000,
        CountableIsolateOperation(),
      );
      stopwatch.stop();

      setState(() {
        _countResult =
            'Result: $result\nTime: ${stopwatch.elapsedMilliseconds}ms\nIsolate spawned: ${_countHelper.isIsolateSpawn}';
        _countLoading = false;
      });
    } catch (e) {
      setState(() {
        _countError = 'Error: $e';
        _countResult = 'Operation failed';
        _countLoading = false;
      });
    }
  }

  Future<void> _runSumOperation() async {
    setState(() {
      _sumLoading = true;
      _sumError = null;
      _sumResult = 'Running...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final result = await _sumHelper.runIsolate(
        List.generate(1000000, (i) => i),
        SumIsolateOperation(),
      );
      stopwatch.stop();

      setState(() {
        _sumResult =
            'Result: $result\nTime: ${stopwatch.elapsedMilliseconds}ms\nIsolate spawned: ${_sumHelper.isIsolateSpawn}';
        _sumLoading = false;
      });
    } catch (e) {
      setState(() {
        _sumError = 'Error: $e';
        _sumResult = 'Operation failed';
        _sumLoading = false;
      });
    }
  }

  Future<void> _runDelayOperation() async {
    setState(() {
      _delayLoading = true;
      _delayError = null;
      _delayResult = 'Running...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final result = await _delayHelper.runIsolate({
        'duration': 2000,
      }, DelayIsolateOperation());
      stopwatch.stop();

      setState(() {
        _delayResult =
            'Result: $result\nTime: ${stopwatch.elapsedMilliseconds}ms\nIsolate spawned: ${_delayHelper.isIsolateSpawn}';
        _delayLoading = false;
      });
    } catch (e) {
      setState(() {
        _delayError = 'Error: $e';
        _delayResult = 'Operation failed';
        _delayLoading = false;
      });
    }
  }

  Future<void> _runErrorOperation() async {
    setState(() {
      _errorLoading = true;
      _errorError = null;
      _errorResult = 'Running...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final result = await _errorHelper.runIsolate(
        null,
        ErrorIsolateOperation(),
      );
      stopwatch.stop();

      setState(() {
        _errorResult =
            'Result: $result\nTime: ${stopwatch.elapsedMilliseconds}ms\nIsolate spawned: ${_errorHelper.isIsolateSpawn}';
        _errorLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorError = 'Error: $e';
        _errorResult = 'Operation failed';
        _errorLoading = false;
      });
    }
  }

  Widget _buildOperationCard(
    BuildContext context, {
    required String title,
    required IsolateHelper helper,
    required bool isLoading,
    required String result,
    required String? error,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback? onPressed,
    required Future<void> Function() onDispose,
    Color? buttonColor,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: helper.isIsolateSpawn
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    helper.isIsolateSpawn ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: helper.isIsolateSpawn
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Helper: ${helper.name}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Result section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Result:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing in isolate...'),
                      ],
                    )
                  else
                    SelectableText(
                      result,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(buttonIcon),
                    label: Text(buttonLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: buttonColor,
                      foregroundColor: buttonColor != null
                          ? Colors.white
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: isLoading ? null : onDispose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Icon(Icons.stop, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate Helper Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Isolate Helper Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Count Operation Card
              _buildOperationCard(
                context,
                title: 'Count Operation',
                helper: _countHelper,
                isLoading: _countLoading,
                result: _countResult,
                error: _countError,
                buttonLabel: 'Count to 10,000,000',
                buttonIcon: Icons.calculate,
                onPressed: _countLoading ? null : _runCountOperation,
                onDispose: () async {
                  await _countHelper.dispose();
                  setState(() {
                    _countResult = 'Isolate disposed';
                    _countError = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Sum Operation Card
              _buildOperationCard(
                context,
                title: 'Sum Operation',
                helper: _sumHelper,
                isLoading: _sumLoading,
                result: _sumResult,
                error: _sumError,
                buttonLabel: 'Sum 1,000,000 numbers',
                buttonIcon: Icons.add,
                onPressed: _sumLoading ? null : _runSumOperation,
                onDispose: () async {
                  await _sumHelper.dispose();
                  setState(() {
                    _sumResult = 'Isolate disposed';
                    _sumError = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Delay Operation Card
              _buildOperationCard(
                context,
                title: 'Delay Operation',
                helper: _delayHelper,
                isLoading: _delayLoading,
                result: _delayResult,
                error: _delayError,
                buttonLabel: 'Simulate 2s delay',
                buttonIcon: Icons.timer,
                onPressed: _delayLoading ? null : _runDelayOperation,
                onDispose: () async {
                  await _delayHelper.dispose();
                  setState(() {
                    _delayResult = 'Isolate disposed';
                    _delayError = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Error Operation Card
              _buildOperationCard(
                context,
                title: 'Error Operation',
                helper: _errorHelper,
                isLoading: _errorLoading,
                result: _errorResult,
                error: _errorError,
                buttonLabel: 'Test Error Handling',
                buttonIcon: Icons.error_outline,
                onPressed: _errorLoading ? null : _runErrorOperation,
                onDispose: () async {
                  await _errorHelper.dispose();
                  setState(() {
                    _errorResult = 'Isolate disposed';
                    _errorError = null;
                  });
                },
                buttonColor: Colors.orange,
              ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This example demonstrates how to use IsolateHelper to run heavy computations in a separate isolate without blocking the UI thread.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Each operation has its own IsolateHelper\n'
                        '• Each helper manages its own isolate\n'
                        '• Heavy computations run in background\n'
                        '• UI remains responsive\n'
                        '• Results are communicated back to main thread\n'
                        '• Isolate auto-disposes after inactivity',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
