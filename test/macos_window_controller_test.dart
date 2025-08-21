import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_controller/macos_window_controller.dart';
import 'package:macos_window_controller/macos_window_controller_platform_interface.dart';
import 'package:macos_window_controller/macos_window_controller_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMacosWindowControllerPlatform
    with MockPlatformInterfaceMixin
    implements MacosWindowControllerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MacosWindowControllerPlatform initialPlatform = MacosWindowControllerPlatform.instance;

  test('$MethodChannelMacosWindowController is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMacosWindowController>());
  });

  test('getPlatformVersion', () async {
    MacosWindowController macosWindowControllerPlugin = MacosWindowController();
    MockMacosWindowControllerPlatform fakePlatform = MockMacosWindowControllerPlatform();
    MacosWindowControllerPlatform.instance = fakePlatform;

    expect(await macosWindowControllerPlugin.getPlatformVersion(), '42');
  });
}
