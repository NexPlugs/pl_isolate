# pl_isolate


https://github.com/user-attachments/assets/31985cfa-f3b4-440e-8459-fdc4f8dc7fe1


A powerful Flutter plugin that simplifies isolate communication and management. Run heavy computations in separate isolates without blocking the UI thread.

## Features

- 🚀 **Easy Isolate Management**: Simple API to create and manage isolates
- 🔄 **Automatic Disposal**: Auto-dispose isolates after inactivity
- 🎯 **Type-Safe Operations**: Define operations with clear interfaces
- 🔐 **Thread-Safe**: Built-in synchronization for concurrent operations
- 📊 **Multiple Isolates**: Each operation can have its own isolate helper
- 🎨 **UI Isolate Support**: Support for both Dart isolates and UI isolates
- ⚡ **Performance**: Run CPU-intensive tasks without blocking the main thread

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pl_isolate: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Define Your Operation

Create an operation class that implements `IsolateOperation`:

```dart
import 'package:pl_isolate/pl_isolate.dart';

class MyCalculationOperation implements IsolateOperation {
  @override
  String get tag => 'calculation';

  @override
  Future<dynamic> run(dynamic args) async {
    // Your heavy computation here
    if (args is int) {
      int result = 0;
      for (var i = 0; i < args; i++) {
        result += i;
      }
      return result;
    }
    throw Exception('Invalid arguments');
  }
}
```

### 2. Create Your Isolate Helper

Extend `IsolateHelper` to create your helper:

```dart
class MyIsolateHelper extends IsolateHelper<int> {
  @override
  bool get isDartIsolate => false; // Use false for regular isolates, true for UI isolates

  @override
  String get name => 'MyIsolateHelper'; // Unique name for this helper

  @override
  bool get isAutoDispose => true; // Auto-dispose after inactivity

  @override
  Stream get messages => throw UnimplementedError(); // Required but not used
}
```

### 3. Use the Helper

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final MyIsolateHelper _helper = MyIsolateHelper();

  Future<void> _runCalculation() async {
    try {
      final result = await _helper.runIsolate(
        1000000, // Arguments
        MyCalculationOperation(), // Your operation
      );
      print('Result: $result');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _helper.dispose(); // Don't forget to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _runCalculation,
      child: Text('Run Calculation'),
    );
  }
}
```

## Complete Example

Here's a complete example showing multiple operations:

```dart
import 'package:flutter/material.dart';
import 'package:pl_isolate/pl_isolate.dart';

// Define operations
class CountOperation implements IsolateOperation {
  @override
  String get tag => 'count';

  @override
  Future<dynamic> run(dynamic args) async {
    if (args is int) {
      int count = 0;
      for (var i = 0; i < args; i++) {
        count++;
      }
      return count;
    }
    return 0;
  }
}

class SumOperation implements IsolateOperation {
  @override
  String get tag => 'sum';

  @override
  Future<dynamic> run(dynamic args) async {
    if (args is List) {
      return args.fold<int>(0, (sum, item) => sum + (item as int));
    }
    return 0;
  }
}

// Create helpers
class CountHelper extends IsolateHelper<int> {
  @override
  bool get isDartIsolate => false;
  @override
  String get name => 'CountHelper';
  @override
  bool get isAutoDispose => true;
  @override
  Stream get messages => throw UnimplementedError();
}

class SumHelper extends IsolateHelper<int> {
  @override
  bool get isDartIsolate => false;
  @override
  String get name => 'SumHelper';
  @override
  bool get isAutoDispose => true;
  @override
  Stream get messages => throw UnimplementedError();
}

// Use in your app
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final CountHelper _countHelper = CountHelper();
  final SumHelper _sumHelper = SumHelper();

  String _countResult = 'No result';
  String _sumResult = 'No result';
  bool _isLoading = false;

  Future<void> _runCount() async {
    setState(() => _isLoading = true);
    try {
      final result = await _countHelper.runIsolate(
        10000000,
        CountOperation(),
      );
      setState(() {
        _countResult = 'Count: $result';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _countResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runSum() async {
    setState(() => _isLoading = true);
    try {
      final result = await _sumHelper.runIsolate(
        List.generate(1000000, (i) => i),
        SumOperation(),
      );
      setState(() {
        _sumResult = 'Sum: $result';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _sumResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _countHelper.dispose();
    _sumHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Isolate Helper Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) CircularProgressIndicator(),
              Text(_countResult),
              ElevatedButton(
                onPressed: _isLoading ? null : _runCount,
                child: Text('Run Count'),
              ),
              SizedBox(height: 20),
              Text(_sumResult),
              ElevatedButton(
                onPressed: _isLoading ? null : _runSum,
                child: Text('Run Sum'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## API Reference

### IsolateHelper<T>

Abstract class for managing isolates.

#### Properties

- `isDartIsolate` (bool): `true` for Dart UI isolates, `false` for regular isolates
- `name` (String): Unique name for the helper
- `isAutoDispose` (bool): Whether to auto-dispose after inactivity
- `isIsolateSpawn` (bool): Whether the isolate is currently spawned
- `autoDisposeInterval` (Duration): Time before auto-dispose (default: 10 seconds)

#### Methods

- `Future<T> runIsolate(dynamic args, IsolateOperation operation)`: Run an operation in the isolate
- `Future<void> dispose()`: Manually dispose the isolate

### IsolateOperation

Abstract class for defining operations.

#### Properties

- `tag` (String): Unique tag for the operation

#### Methods

- `Future<dynamic> run(dynamic args)`: Execute the operation

## Dart Isolate vs UI Isolate

### Regular Isolate (`isDartIsolate: false`)

- Requires `RootIsolateToken` for platform channel access
- Use for computations that don't need UI access
- Better performance for CPU-intensive tasks

```dart
class MyHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => false;
  // ... other properties
}
```

### UI Isolate (`isDartIsolate: true`)

- Can access UI-related APIs
- Use when you need platform channels or UI access
- Requires Flutter bindings to be initialized

```dart
class MyHelper extends IsolateHelper<dynamic> {
  @override
  bool get isDartIsolate => true;
  // ... other properties
}
```

## Best Practices

### 1. One Helper per Operation Type

Each helper should manage one type of operation:

```dart
// Good: Separate helpers for different operations
class ImageProcessingHelper extends IsolateHelper<Uint8List> { ... }
class DataAnalysisHelper extends IsolateHelper<AnalysisResult> { ... }

// Avoid: One helper for multiple unrelated operations
class AllOperationsHelper extends IsolateHelper<dynamic> { ... }
```

### 2. Always Dispose Helpers

Make sure to dispose helpers when they're no longer needed:

```dart
@override
void dispose() {
  _helper.dispose();
  super.dispose();
}
```

### 3. Handle Errors Properly

Always wrap isolate operations in try-catch:

```dart
try {
  final result = await _helper.runIsolate(args, operation);
  // Handle success
} catch (e) {
  // Handle error
}
```

### 4. Use Auto-Dispose for Temporary Operations

Enable auto-dispose for operations that are run infrequently:

```dart
@override
bool get isAutoDispose => true;
```

### 5. Pass Serializable Data

Only pass data that can be serialized between isolates:

```dart
// Good: Primitive types, lists, maps
final result = await helper.runIsolate(42, operation);
final result = await helper.runIsolate([1, 2, 3], operation);
final result = await helper.runIsolate({'key': 'value'}, operation);

// Avoid: Complex objects, closures, functions
// These cannot be serialized between isolates
```

## Advanced Usage

### Custom Auto-Dispose Interval

Override `autoDisposeInterval` to customize the disposal time:

```dart
class MyHelper extends IsolateHelper<dynamic> {
  @override
  Duration get autoDisposeInterval => const Duration(seconds: 30);
  // ... other properties
}
```

### Running Multiple Operations Concurrently

Each helper can run operations independently:

```dart
// Run multiple operations at the same time
final result1 = _helper1.runIsolate(args1, operation1);
final result2 = _helper2.runIsolate(args2, operation2);
final result3 = _helper3.runIsolate(args3, operation3);

// Wait for all to complete
final results = await Future.wait([result1, result2, result3]);
```

### Checking Isolate Status

Monitor isolate state:

```dart
if (_helper.isIsolateSpawn) {
  print('Isolate is active');
} else {
  print('Isolate is inactive');
}
```

## Troubleshooting

### Error: "Root isolate token is not set"

**Solution**: If using `isDartIsolate: false`, make sure you're running in a Flutter app context. For UI isolates, use `isDartIsolate: true`.

### Isolate Not Disposing

**Solution**: Check if `isAutoDispose` is set to `true` and ensure no active operations are running.

### Serialization Errors

**Solution**: Ensure all data passed to `runIsolate` is serializable. Avoid passing complex objects, closures, or functions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/NexPlugs/pl_isolate/issues) page.

---

Made with ❤️ by the NexPlugs team
