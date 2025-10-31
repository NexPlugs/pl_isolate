import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_helper/isolate_helper_platform_interface.dart';
import 'package:isolate_helper/isolate_helper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIsolateHelperPlatform
    with MockPlatformInterfaceMixin
    implements IsolateHelperPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IsolateHelperPlatform initialPlatform = IsolateHelperPlatform.instance;

  test('$MethodChannelIsolateHelper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIsolateHelper>());
  });

  test('getPlatformVersion', () async {});
}
