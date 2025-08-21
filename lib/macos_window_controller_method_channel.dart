import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_window_controller.dart';
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

  @override
  Future<List<WindowInfo>> getAllWindows() async {
    try {
      final List<dynamic> result = await methodChannel.invokeMethod('getAllWindows');
      
      final windows = result.map((window) {
        final windowMap = Map<String, dynamic>.from(window as Map);
        return WindowInfo.fromMap(windowMap);
      }).toList();
      
      return windows;
    } catch (e) {
      print('Error getting all windows: $e');
      return [];
    }
  }

  @override
  Future<List<WindowInfo>> getWindowsByPid(int pid) async {
    try {
      final List<dynamic> result = await methodChannel.invokeMethod('getWindowsByPid', {'pid': pid});
      
      final windows = result.map((window) {
        final windowMap = Map<String, dynamic>.from(window as Map);
        return WindowInfo.fromMap(windowMap);
      }).toList();
      
      return windows;
    } catch (e) {
      print('Error getting windows by PID $pid: $e');
      return [];
    }
  }

  @override
  Future<WindowInfo?> getWindowInfo(int windowId) async {
    try {
      final dynamic result = await methodChannel.invokeMethod('getWindowInfo', {'windowId': windowId});
      if (result == null) return null;
      
      final windowMap = Map<String, dynamic>.from(result as Map);
      return WindowInfo.fromMap(windowMap);
    } catch (e) {
      print('Error getting window info for $windowId: $e');
      return null;
    }
  }

  @override
  Future<bool> isWindowValid(int windowId) async {
    try {
      final bool result = await methodChannel.invokeMethod('isWindowValid', {'windowId': windowId});
      return result;
    } catch (e) {
      print('Error checking window validity for $windowId: $e');
      return false;
    }
  }

  @override
  Future<bool> closeWindow(int windowId) async {
    try {
      final bool result = await methodChannel.invokeMethod('closeWindow', {'windowId': windowId});
      return result;
    } catch (e) {
      print('Error closing window $windowId: $e');
      return false;
    }
  }

  @override
  Future<Uint8List?> captureWindow(int windowId) async {
    try {
      final Uint8List? result = await methodChannel.invokeMethod('captureWindow', {'windowId': windowId});
      return result;
    } catch (e) {
      print('Error capturing window $windowId: $e');
      return null;
    }
  }
}
