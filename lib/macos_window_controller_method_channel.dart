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
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to get all windows', cause: e);
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
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to get windows for PID $pid', cause: e);
    }
  }

  @override
  Future<WindowInfo?> getWindowInfo(int windowId) async {
    try {
      final dynamic result = await methodChannel.invokeMethod('getWindowInfo', {'windowId': windowId});
      if (result == null) return null;
      
      final windowMap = Map<String, dynamic>.from(result as Map);
      return WindowInfo.fromMap(windowMap);
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to get window info for $windowId', cause: e);
    }
  }

  @override
  Future<bool> isWindowValid(int windowId) async {
    try {
      final bool result = await methodChannel.invokeMethod('isWindowValid', {'windowId': windowId});
      return result;
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to check window validity for $windowId', cause: e);
    }
  }

  @override
  Future<bool> closeWindow(int windowId) async {
    try {
      final bool result = await methodChannel.invokeMethod('closeWindow', {'windowId': windowId});
      return result;
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to close window $windowId', cause: e);
    }
  }

  @override
  Future<Uint8List?> captureWindow(int windowId) async {
    try {
      final Uint8List? result = await methodChannel.invokeMethod('captureWindow', {'windowId': windowId});
      return result;
    } on PlatformException catch (e) {
      final error = WindowControllerError.fromCode(e.code);
      throw WindowControllerException(error, details: e.message, cause: e);
    } catch (e) {
      throw WindowControllerException(WindowControllerError.unknown, 
          details: 'Failed to capture window $windowId', cause: e);
    }
  }
}
