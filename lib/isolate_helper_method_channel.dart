import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'isolate_helper_platform_interface.dart';

/// An implementation of [IsolateHelperPlatform] that uses method channels.
class MethodChannelIsolateHelper extends IsolateHelperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('isolate_helper');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
