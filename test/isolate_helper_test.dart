import 'package:flutter_test/flutter_test.dart';
import 'package:pl_isolate/pl_isolate.dart';

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

class CountableIsolateHelper extends IsolateHelper<int> {
  @override
  bool get isAutoDispose => true;

  @override
  bool get isDartIsolate => false;

  @override
  String get name => 'count';

  @override
  IsolateCache<String, dynamic>? get cache => IsolateCache<String, dynamic>(
        maxEntries: 1000,
        defaultTtl: const Duration(seconds: 10),
      );
}

void main() {
  test('IsolateHelper test', () async {
    final isolateHelper = CountableIsolateHelper();
    final result =
        await isolateHelper.runIsolate(10000000, CountableIsolateOperation());
    expect(result, 10000000);
  });

  test('IsolateHelper test with cache', () async {
    final isolateHelper = CountableIsolateHelper();
    final result =
        await isolateHelper.runIsolate(10000000, CountableIsolateOperation());
    expect(result, 10000000);
    final result2 =
        await isolateHelper.runIsolate(2000, CountableIsolateOperation());
    expect(result2, 2000);
  });

  test("IsolateHelper test with error response", () async {
    final isolateHelper = CountableIsolateHelper();
    try {
      await isolateHelper.runIsolate(10000000, CountableIsolateOperation());
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });
}
