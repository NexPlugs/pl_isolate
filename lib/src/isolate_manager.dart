import 'isolate_helper.dart';

/// Isolate manager to manage isolate helpers
class IsolateManager {
  IsolateManager._();

  static IsolateManager get instance => _instance;
  static final _instance = IsolateManager._();

  final Map<String, IsolateHelper> _isolateHelpers = {};

  /// Add the isolate helper to the manager
  /// [isolateHelper] is the isolate helper to add
  void addIsolateHelper(IsolateHelper isolateHelper) {
    _isolateHelpers[isolateHelper.name] = isolateHelper;
  }

  /// Remove the isolate helper from the manager
  /// [name] is the name of the isolate helper to remove
  void removeIsolateHelper(String name) {
    _isolateHelpers.remove(name);
  }

  /// Dispose all the isolate helpers
  void disposeAllIsolateHelpers() {
    for (var isolateHelper in _isolateHelpers.values) {
      isolateHelper.dispose();
    }
    _isolateHelpers.clear();
  }
}
