import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_window_controller_platform_interface.dart';

/// An implementation of [MacosWindowControllerPlatform] that uses method channels.
class MethodChannelMacosWindowController extends MacosWindowControllerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('macos_window_controller');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
