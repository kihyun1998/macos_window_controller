import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_window_controller_method_channel.dart';

abstract class MacosWindowControllerPlatform extends PlatformInterface {
  /// Constructs a MacosWindowControllerPlatform.
  MacosWindowControllerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MacosWindowControllerPlatform _instance = MethodChannelMacosWindowController();

  /// The default instance of [MacosWindowControllerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMacosWindowController].
  static MacosWindowControllerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MacosWindowControllerPlatform] when
  /// they register themselves.
  static set instance(MacosWindowControllerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
