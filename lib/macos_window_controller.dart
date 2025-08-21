
import 'dart:typed_data';
import 'macos_window_controller_platform_interface.dart';

/// Error codes for macOS window controller operations
enum WindowControllerError {
  /// Invalid arguments passed to the method
  invalidArguments('INVALID_ARGUMENTS', 'Invalid arguments provided'),
  
  /// Failed to retrieve window list from system
  windowListFailed('WINDOW_LIST_FAILED', 'Failed to get window list from system'),
  
  /// Window with specified ID not found
  windowNotFound('WINDOW_NOT_FOUND', 'Window not found or no longer exists'),
  
  /// Permission denied for the operation
  permissionDenied('PERMISSION_DENIED', 'Required permissions not granted'),
  
  /// Screen recording permission required
  screenRecordingRequired('SCREEN_RECORDING_REQUIRED', 'Screen Recording permission required'),
  
  /// Failed to capture window
  captureFailed('CAPTURE_FAILED', 'Failed to capture window'),
  
  /// Failed to convert image format
  conversionFailed('CONVERSION_FAILED', 'Failed to convert image format'),
  
  /// Window close operation failed
  closeFailed('CLOSE_FAILED', 'Failed to close window'),
  
  /// Accessibility permission required
  accessibilityRequired('ACCESSIBILITY_REQUIRED', 'Accessibility permission required'),
  
  /// Unknown or unspecified error
  unknown('UNKNOWN', 'An unknown error occurred');

  const WindowControllerError(this.code, this.message);
  
  /// The error code string
  final String code;
  
  /// Human-readable error message
  final String message;
  
  /// Creates a WindowControllerError from an error code string
  static WindowControllerError fromCode(String code) {
    for (final error in WindowControllerError.values) {
      if (error.code == code) {
        return error;
      }
    }
    return WindowControllerError.unknown;
  }
}

/// Options for window capture behavior
enum WindowCaptureOptions {
  /// Capture the entire window including titlebar and frame
  includeFrame('INCLUDE_FRAME'),
  
  /// Capture only the content area, excluding titlebar and frame
  contentOnly('CONTENT_ONLY');

  const WindowCaptureOptions(this.value);
  
  /// The string value sent to the native platform
  final String value;
}

/// Exception thrown by window controller operations
class WindowControllerException implements Exception {
  /// The error type
  final WindowControllerError error;
  
  /// Additional details about the error
  final String? details;
  
  /// Optional underlying cause
  final dynamic cause;
  
  const WindowControllerException(this.error, {this.details, this.cause});
  
  @override
  String toString() {
    final buffer = StringBuffer('WindowControllerException: ${error.message}');
    if (details != null) {
      buffer.write(' - $details');
    }
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

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
  /// [options] Capture options - defaults to includeFrame
  /// Returns PNG image data as Uint8List if successful, null otherwise
  /// 
  /// Requires Screen Recording permission on macOS 10.15+.
  /// Enable in System Preferences > Security & Privacy > Screen Recording
  Future<Uint8List?> captureWindow(int windowId, {WindowCaptureOptions options = WindowCaptureOptions.includeFrame}) {
    return MacosWindowControllerPlatform.instance.captureWindow(windowId, options: options);
  }

  /// Checks the current permission status for Screen Recording and Accessibility
  /// 
  /// Returns a Map with boolean values:
  /// - 'screenRecording': true if Screen Recording permission is granted
  /// - 'accessibility': true if Accessibility permission is granted
  Future<Map<String, bool>> checkPermissions() {
    return MacosWindowControllerPlatform.instance.checkPermissions();
  }
}
