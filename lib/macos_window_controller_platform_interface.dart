import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_window_controller.dart';
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

  Future<List<WindowInfo>> getAllWindows() {
    throw UnimplementedError('getAllWindows() has not been implemented.');
  }

  Future<List<WindowInfo>> getWindowsByPid(int pid) {
    throw UnimplementedError('getWindowsByPid() has not been implemented.');
  }

  Future<WindowInfo?> getWindowInfo(int windowId) {
    throw UnimplementedError('getWindowInfo() has not been implemented.');
  }

  Future<bool> isWindowValid(int windowId) {
    throw UnimplementedError('isWindowValid() has not been implemented.');
  }

  Future<bool> closeWindow(int windowId) {
    throw UnimplementedError('closeWindow() has not been implemented.');
  }

  Future<Uint8List?> captureWindow(int windowId, {WindowCaptureOptions options = WindowCaptureOptions.includeFrame}) {
    throw UnimplementedError('captureWindow() has not been implemented.');
  }

  Future<Map<String, bool>> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }
}
