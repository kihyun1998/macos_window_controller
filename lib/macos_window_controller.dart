
import 'dart:typed_data';
import 'macos_window_controller_platform_interface.dart';

/// Represents information about a macOS window
class WindowInfo {
  /// The unique identifier for the window
  final int windowId;
  
  /// The title/name of the window
  final String windowName;
  
  /// The process ID that owns this window
  final int ownerPID;
  
  /// The x-coordinate of the window's position
  final double x;
  
  /// The y-coordinate of the window's position  
  final double y;
  
  /// The width of the window in pixels
  final double width;
  
  /// The height of the window in pixels
  final double height;

  WindowInfo({
    required this.windowId,
    required this.windowName,
    required this.ownerPID,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a WindowInfo from a map representation
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

/// Main controller class for managing macOS windows
class MacosWindowController {
  /// Returns the macOS platform version
  Future<String?> getPlatformVersion() {
    return MacosWindowControllerPlatform.instance.getPlatformVersion();
  }

  /// Gets information about all visible windows on the screen
  /// 
  /// Returns a list of [WindowInfo] objects containing details about each window.
  /// This method does not require special permissions.
  Future<List<WindowInfo>> getAllWindows() {
    return MacosWindowControllerPlatform.instance.getAllWindows();
  }

  /// Gets all windows belonging to a specific process
  /// 
  /// [pid] The process ID to filter windows by
  /// Returns a list of [WindowInfo] objects for windows owned by the specified process
  Future<List<WindowInfo>> getWindowsByPid(int pid) {
    return MacosWindowControllerPlatform.instance.getWindowsByPid(pid);
  }

  /// Gets detailed information about a specific window
  /// 
  /// [windowId] The unique identifier of the window
  /// Returns [WindowInfo] if the window exists, null otherwise
  Future<WindowInfo?> getWindowInfo(int windowId) {
    return MacosWindowControllerPlatform.instance.getWindowInfo(windowId);
  }

  /// Checks if a window with the given ID still exists
  /// 
  /// [windowId] The unique identifier of the window
  /// Returns true if the window exists and is visible, false otherwise
  Future<bool> isWindowValid(int windowId) {
    return MacosWindowControllerPlatform.instance.isWindowValid(windowId);
  }

  /// Attempts to close a window with the given ID
  /// 
  /// [windowId] The unique identifier of the window to close
  /// Returns true if the close command was successful, false otherwise
  /// Note: This method is not yet fully implemented
  Future<bool> closeWindow(int windowId) {
    return MacosWindowControllerPlatform.instance.closeWindow(windowId);
  }

  /// Captures a screenshot of the specified window
  /// 
  /// [windowId] The unique identifier of the window to capture
  /// Returns PNG image data as Uint8List if successful, null otherwise
  /// 
  /// Requires Screen Recording permission on macOS 10.15+.
  /// Enable in System Preferences > Security & Privacy > Screen Recording
  Future<Uint8List?> captureWindow(int windowId) {
    return MacosWindowControllerPlatform.instance.captureWindow(windowId);
  }
}
