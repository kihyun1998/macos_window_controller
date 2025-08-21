
import 'dart:typed_data';
import 'macos_window_controller_platform_interface.dart';

class WindowInfo {
  final int windowId;
  final String windowName;
  final int ownerPID;
  final double x, y, width, height;

  WindowInfo({
    required this.windowId,
    required this.windowName,
    required this.ownerPID,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory WindowInfo.fromMap(Map<String, dynamic> map) {
    final boundsRaw = map['bounds'];
    final bounds = Map<String, dynamic>.from(boundsRaw as Map);
    
    return WindowInfo(
      windowId: map['windowId'] as int,
      windowName: map['windowName'] as String,
      ownerPID: map['ownerPID'] as int,
      x: (bounds['x'] as num).toDouble(),
      y: (bounds['y'] as num).toDouble(),
      width: (bounds['width'] as num).toDouble(),
      height: (bounds['height'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'WindowInfo(id: $windowId, name: "$windowName", pid: $ownerPID, bounds: ${width}x$height)';
  }
}

class MacosWindowController {
  Future<String?> getPlatformVersion() {
    return MacosWindowControllerPlatform.instance.getPlatformVersion();
  }

  /// 모든 윈도우 정보를 가져옵니다
  Future<List<WindowInfo>> getAllWindows() {
    return MacosWindowControllerPlatform.instance.getAllWindows();
  }

  /// 특정 PID의 윈도우들을 가져옵니다
  Future<List<WindowInfo>> getWindowsByPid(int pid) {
    return MacosWindowControllerPlatform.instance.getWindowsByPid(pid);
  }

  /// 특정 윈도우 ID의 정보를 가져옵니다
  Future<WindowInfo?> getWindowInfo(int windowId) {
    return MacosWindowControllerPlatform.instance.getWindowInfo(windowId);
  }

  /// 윈도우가 유효한지 확인합니다
  Future<bool> isWindowValid(int windowId) {
    return MacosWindowControllerPlatform.instance.isWindowValid(windowId);
  }

  /// 윈도우를 닫습니다
  Future<bool> closeWindow(int windowId) {
    return MacosWindowControllerPlatform.instance.closeWindow(windowId);
  }

  /// 윈도우를 캡처합니다
  Future<Uint8List?> captureWindow(int windowId) {
    return MacosWindowControllerPlatform.instance.captureWindow(windowId);
  }
}
