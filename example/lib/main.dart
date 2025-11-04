import 'package:flutter/material.dart';
import 'dart:async';

import 'package:isolate_helper/isolate_helper.dart';

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
  bool get isDartIsolate => false;

  @override
  String get name => 'CountableIsolateHelper';

  @override
  bool get autoDispose => true;

  @override
  Stream get messages => throw UnimplementedError();

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
  final CountableIsolateHelper _countableIsolateHelper =
      CountableIsolateHelper();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              TextButton(
                onPressed: () async {
                  print("Counting...");

                  final result = await _countableIsolateHelper.runIsolate(
                    1000000000,
                    CountableIsolateOperation(),
                  );
                  print("Result: $result");
                },
                child: const Text('Count'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
