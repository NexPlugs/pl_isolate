import 'isolate_helper.dart';

/// Isolate manager to manage isolate helpers
class IsolateManager {
  IsolateManager._();

  static IsolateManager get instance => _instance;
  static final _instance = IsolateManager._();

  final Map<String, IsolateHelper> _isolateHelpers = {};

  void addIsolateHelper(IsolateHelper isolateHelper) {
    _isolateHelpers[isolateHelper.name] = isolateHelper;
  }

  void removeIsolateHelper(String name) {
    _isolateHelpers.remove(name);
  }
}
