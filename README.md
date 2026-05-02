


# pl_isolate

https://github.com/user-attachments/assets/31985cfa-f3b4-440e-8459-fdc4f8dc7fe1

A powerful Flutter plugin that simplifies isolate communication and management.  
Run heavy computations in separate isolates without blocking the UI thread.

---

## ✨ Features

- 🚀 Easy isolate lifecycle management
- 🔄 Auto-dispose isolates after inactivity
- 🎯 Strongly-typed operations (`IsolateOperation<T>`)
- 🧩 One helper per operation (clean architecture friendly)
- ⚡ Non-blocking UI for CPU-intensive work
- 📊 Built-in `IsolateManager` for batching & concurrency control
- 🔐 Safe error propagation from isolate → UI
- 📦 Optimized data transfer (supports large payloads)

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pl_isolate: ^1.0.0
````

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Define an Operation

Each task is represented by an `IsolateOperation<T>`.

```dart
import 'package:pl_isolate/pl_isolate.dart';

class CountableIsolateOperation extends IsolateOperation<int> {
  @override
  String get tag => 'count';

  @override
  Future<int> run(dynamic args) async {
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
```

---

### 2. Create a Helper

Each operation has its own `IsolateHelper`.

```dart
class CountIsolateHelper
    extends IsolateHelper<dynamic, CountableIsolateOperation> {

  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'CountIsolateHelper';

  @override
  bool get isAutoDispose => true;

  CountIsolateHelper(super.operation);
}
```

> ✅ Operation is injected via constructor — NOT passed at runtime

---

### 3. Execute in UI

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final CountIsolateHelper _helper;

  @override
  void initState() {
    super.initState();
    _helper = CountIsolateHelper(CountableIsolateOperation());
  }

  Future<void> runTask() async {
    try {
      final result = await _helper.runIsolate(1000000);
      print('Result: $result');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _helper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: runTask,
      child: const Text('Run Task'),
    );
  }
}
```

---

## 🧠 Core Concept

```
IsolateOperation  →  Business logic
IsolateHelper     →  Isolate lifecycle + execution
IsolateManager    →  Queue + concurrency control
```

---

## ⚙️ Using IsolateManager (Advanced)

### Initialize

```dart
final manager = IsolateManager.init(2, 12);
// 2 concurrent tasks, max 12 in queue
```

---

### Add Tasks

```dart
manager.addIsolateHelper(
  CountIsolateHelper(CountableIsolateOperation()),
  3000000,
);

manager.addIsolateHelper(
  SumIsolateHelper(SumIsolateOperation()),
  List.generate(500000, (i) => i),
);
```

---

### Listen for Results

```dart
manager.listenIsolateResult((result) {
  if (result.errorMessage != null) {
    print('❌ ${result.name}: ${result.errorMessage}');
  } else {
    print('✅ ${result.name}: ${result.result}');
  }
});
```

---

### Run Batch

```dart
await manager.runAllInBatches();
```

---

### Dispose

```dart
manager.disposeAll();
```

---

## 🧪 Example Operations

### Sum Operation

```dart
class SumIsolateOperation extends IsolateOperation<int> {
  @override
  String get tag => 'sum';

  @override
  Future<int> run(dynamic args) async {
    if (args is List) {
      int sum = 0;
      for (final item in args) {
        if (item is int) sum += item;
      }
      return sum;
    }
    return 0;
  }
}
```

---

### Delay Operation

```dart
class DelayIsolateOperation extends IsolateOperation<String> {
  @override
  String get tag => 'delay';

  @override
  Future<String> run(dynamic args) async {
    if (args is Map && args.containsKey('duration')) {
      final duration = args['duration'] as int;
      await Future.delayed(Duration(milliseconds: duration));
      return 'Completed after ${duration}ms';
    }
    return 'Invalid arguments';
  }
}
```

---

### Error Operation

```dart
class ErrorIsolateOperation extends IsolateOperation {
  @override
  String get tag => 'error';

  @override
  Future<dynamic> run(dynamic args) async {
    throw Exception('This is a test error from isolate');
  }
}
```

---

## 🧩 Best Practices

### 1. One Helper = One Operation

```dart
// ✅ Good
CountIsolateHelper
SumIsolateHelper

// ❌ Avoid
GenericHelper
```

---

### 2. Do NOT pass operation into runIsolate

```dart
// ✅ Correct
helper.runIsolate(args);

// ❌ Wrong (old API)
helper.runIsolate(args, operation);
```

---

### 3. Always Dispose

```dart
@override
void dispose() {
  helper.dispose();
  super.dispose();
}
```

---

### 4. Use Manager for Heavy Workloads

* Few tasks → use helper directly
* Many tasks → use IsolateManager

---

### 5. Pass Serializable Data Only

```dart
// ✅ OK
int, String, List, Map

// ❌ Avoid
BuildContext, Function, Stream
```

---

## ⚡ Dart Isolate vs UI Isolate

### Regular Isolate (`isDartIsolate = false`)

* Best performance
* No UI access
* Recommended for most cases

---

### UI Isolate (`isDartIsolate = true`)

* Needed for platform channels
* Slightly heavier

---

## 🧯 Troubleshooting

### Isolate not running?

* Check helper initialization
* Verify `isDartIsolate`

### Serialization error?

* Ensure data is transferable

### Memory leak?

* Forgot `dispose()`

---

## ❤️ Why pl_isolate?

| Feature         | compute() | pl_isolate |
| --------------- | --------- | ---------- |
| Reuse isolate   | ❌         | ✅          |
| Queue system    | ❌         | ✅          |
| Error handling  | Basic     | Advanced   |
| Typed API       | ❌         | ✅          |
| Batch execution | ❌         | ✅          |

---

## 🤝 Contributing

Pull requests are welcome!

---

## 📄 License

MIT License

---

## 💬 Support

[https://github.com/NexPlugs/pl_isolate/issues](https://github.com/NexPlugs/pl_isolate/issues)

---

Made with ❤️ by NexPlugs
