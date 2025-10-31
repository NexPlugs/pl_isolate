import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'isolate_helper_method_channel.dart';

abstract class IsolateHelperPlatform extends PlatformInterface {
  /// Constructs a IsolateHelperPlatform.
  IsolateHelperPlatform() : super(token: _token);

  static final Object _token = Object();

  static IsolateHelperPlatform _instance = MethodChannelIsolateHelper();

  /// The default instance of [IsolateHelperPlatform] to use.
  ///
  /// Defaults to [MethodChannelIsolateHelper].
  static IsolateHelperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IsolateHelperPlatform] when
  /// they register themselves.
  static set instance(IsolateHelperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
