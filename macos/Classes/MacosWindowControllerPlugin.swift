import Cocoa
import FlutterMacOS

/// Error codes for window controller operations  
enum WindowControllerError: String, CaseIterable {
  case invalidArguments = "INVALID_ARGUMENTS"
  case windowListFailed = "WINDOW_LIST_FAILED"  
  case windowNotFound = "WINDOW_NOT_FOUND"
  case permissionDenied = "PERMISSION_DENIED"
  case screenRecordingRequired = "SCREEN_RECORDING_REQUIRED"
  case captureFailed = "CAPTURE_FAILED"
  case conversionFailed = "CONVERSION_FAILED"
  case closeFailed = "CLOSE_FAILED"
  case accessibilityRequired = "ACCESSIBILITY_REQUIRED"
  case unknown = "UNKNOWN"
  
  var message: String {
    switch self {
    case .invalidArguments:
      return "Invalid arguments provided"
    case .windowListFailed:
      return "Failed to get window list from system"
    case .windowNotFound:
      return "Window not found or no longer exists"
    case .permissionDenied:
      return "Required permissions not granted"
    case .screenRecordingRequired:
      return "Screen Recording permission required. Enable in System Preferences > Security & Privacy > Screen Recording"
    case .captureFailed:
      return "Failed to capture window"
    case .conversionFailed:
      return "Failed to convert image format"
    case .closeFailed:
      return "Failed to close window"
    case .accessibilityRequired:
      return "Accessibility permission required. Enable in System Preferences > Security & Privacy > Accessibility"
    case .unknown:
      return "An unknown error occurred"
    }
  }
  
  /// Creates a FlutterError with this error code and message
  func asFlutterError(details: String? = nil) -> FlutterError {
    return FlutterError(code: self.rawValue, message: self.message, details: details)
  }
}

public class MacosWindowControllerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "macos_window_controller", binaryMessenger: registrar.messenger)
    let instance = MacosWindowControllerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getAllWindows":
      getAllWindows(result: result)
    case "getWindowsByPid":
      if let args = call.arguments as? [String: Any],
         let pid = args["pid"] as? Int {
        getWindowsByPid(pid: pid, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "PID is required"))
      }
    case "getWindowInfo":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        getWindowInfo(windowId: windowId, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "isWindowValid":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        isWindowValid(windowId: windowId, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "closeWindow":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        closeWindow(windowId: windowId, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "captureWindow":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        captureWindow(windowId: windowId, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Gets all visible windows on the screen
  private func getAllWindows(result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(WindowControllerError.windowListFailed.asFlutterError(details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }
    
    let windows = windowList.compactMap { windowInfo -> [String: Any]? in
      return parseWindowInfo(windowInfo)
    }
    
    result(windows)
  }
  
  /// Gets all windows belonging to a specific process
  private func getWindowsByPid(pid: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(WindowControllerError.windowListFailed.asFlutterError(details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }
    
    let windows = windowList.compactMap { windowInfo -> [String: Any]? in
      if let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int,
         ownerPID == pid {
        return parseWindowInfo(windowInfo)
      }
      return nil
    }
    
    result(windows)
  }
  
  /// Gets detailed information about a specific window
  private func getWindowInfo(windowId: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(WindowControllerError.windowListFailed.asFlutterError(details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }
    
    for windowInfo in windowList {
      if let id = windowInfo[kCGWindowNumber as String] as? Int,
         id == windowId {
        result(parseWindowInfo(windowInfo))
        return
      }
    }
    
    result(WindowControllerError.windowNotFound.asFlutterError(details: "Window ID \(windowId) not found"))
  }
  
  /// Checks if a window with the given ID still exists
  private func isWindowValid(windowId: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(WindowControllerError.windowListFailed.asFlutterError(details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }
    
    for windowInfo in windowList {
      if let id = windowInfo[kCGWindowNumber as String] as? Int,
         id == windowId {
        result(true)
        return
      }
    }
    
    result(false)
  }
  
  /// Attempts to close a window with the given ID
  /// Note: This method is not yet fully implemented
  private func closeWindow(windowId: Int, result: @escaping FlutterResult) {
    // TODO: Implement window closing functionality
    // This would require Accessibility permissions and AXUIElement APIs
    result(WindowControllerError.closeFailed.asFlutterError(details: "Window closing not yet implemented"))
  }
  
  /// Captures a screenshot of the specified window
  /// Requires Screen Recording permission on macOS 10.15+
  private func captureWindow(windowId: Int, result: @escaping FlutterResult) {
    // First check if window exists
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(WindowControllerError.windowListFailed.asFlutterError(details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }
    
    let windowExists = windowList.contains { windowInfo in
      if let id = windowInfo[kCGWindowNumber as String] as? Int {
        return id == windowId
      }
      return false
    }
    
    if !windowExists {
      result(WindowControllerError.windowNotFound.asFlutterError(details: "Window ID \(windowId) not found"))
      return
    }
    
    // Capture the window using Core Graphics
    guard let image = CGWindowListCreateImage(
      CGRect.null,
      .optionIncludingWindow,
      CGWindowID(windowId),
      [.boundsIgnoreFraming, .bestResolution]
    ) else {
      result(WindowControllerError.captureFailed.asFlutterError(details: "CGWindowListCreateImage returned nil for window \(windowId)"))
      return
    }
    
    // Check if captured image is empty (indicates permission issue)
    if image.width == 0 || image.height == 0 {
      result(WindowControllerError.screenRecordingRequired.asFlutterError(details: "Captured image is empty, likely due to missing Screen Recording permission"))
      return
    }
    
    // Convert CGImage to PNG data
    guard let pngData = convertCGImageToPNGData(image) else {
      result(WindowControllerError.conversionFailed.asFlutterError(details: "NSBitmapImageRep PNG conversion failed"))
      return
    }
    
    result(FlutterStandardTypedData(bytes: pngData))
  }
  
  private func convertCGImageToPNGData(_ cgImage: CGImage) -> Data? {
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .png, properties: [:])
  }
  
  private func parseWindowInfo(_ windowInfo: [String: Any]) -> [String: Any]? {
    guard let windowId = windowInfo[kCGWindowNumber as String] as? Int,
          let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int else {
      return nil
    }
    
    let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
    
    // 윈도우 bounds 정보 추출
    var bounds: [String: Double] = ["x": 0, "y": 0, "width": 0, "height": 0]
    if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] {
      bounds["x"] = boundsDict["X"] as? Double ?? 0
      bounds["y"] = boundsDict["Y"] as? Double ?? 0
      bounds["width"] = boundsDict["Width"] as? Double ?? 0
      bounds["height"] = boundsDict["Height"] as? Double ?? 0
    }
    
    return [
      "windowId": windowId,
      "windowName": windowName,
      "ownerPID": ownerPID,
      "bounds": bounds
    ]
  }
}
