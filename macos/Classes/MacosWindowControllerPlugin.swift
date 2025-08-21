import ApplicationServices
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
      return
        "Screen Recording permission required. Enable in System Preferences > Security & Privacy > Screen Recording"
    case .captureFailed:
      return "Failed to capture window"
    case .conversionFailed:
      return "Failed to convert image format"
    case .closeFailed:
      return "Failed to close window"
    case .accessibilityRequired:
      return
        "Accessibility permission required. Enable in System Preferences > Security & Privacy > Accessibility"
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
    let channel = FlutterMethodChannel(
      name: "macos_window_controller", binaryMessenger: registrar.messenger)
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
        let pid = args["pid"] as? Int
      {
        getWindowsByPid(pid: pid, result: result)
      } else {
        result(WindowControllerError.invalidArguments.asFlutterError(details: "PID is required"))
      }
    case "getWindowInfo":
      if let args = call.arguments as? [String: Any],
        let windowId = args["windowId"] as? Int
      {
        getWindowInfo(windowId: windowId, result: result)
      } else {
        result(
          WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "isWindowValid":
      if let args = call.arguments as? [String: Any],
        let windowId = args["windowId"] as? Int
      {
        isWindowValid(windowId: windowId, result: result)
      } else {
        result(
          WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "closeWindow":
      if let args = call.arguments as? [String: Any],
        let windowId = args["windowId"] as? Int
      {
        closeWindow(windowId: windowId, result: result)
      } else {
        result(
          WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "captureWindow":
      if let args = call.arguments as? [String: Any],
        let windowId = args["windowId"] as? Int
      {
        let options = args["options"] as? String ?? "INCLUDE_FRAME"
        captureWindow(windowId: windowId, options: options, result: result)
      } else {
        result(
          WindowControllerError.invalidArguments.asFlutterError(details: "Window ID is required"))
      }
    case "checkPermissions":
      checkPermissions(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Gets all visible windows on the screen
  private func getAllWindows(result: @escaping FlutterResult) {
    // Check Screen Recording permission first
    if !checkScreenRecordingPermission() {
      openScreenRecordingSettings()
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details:
            "Screen Recording permission required. System Preferences opened - please enable and try again."
        ))
      return
    }

    guard
      let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        as? [[String: Any]]
    else {
      result(
        WindowControllerError.windowListFailed.asFlutterError(
          details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }

    let windows = windowList.compactMap { windowInfo -> [String: Any]? in
      return parseWindowInfo(windowInfo)
    }

    result(windows)
  }

  /// Gets all windows belonging to a specific process
  private func getWindowsByPid(pid: Int, result: @escaping FlutterResult) {
    // Check Screen Recording permission first
    if !checkScreenRecordingPermission() {
      openScreenRecordingSettings()
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details:
            "Screen Recording permission required. System Preferences opened - please enable and try again."
        ))
      return
    }

    guard
      let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        as? [[String: Any]]
    else {
      result(
        WindowControllerError.windowListFailed.asFlutterError(
          details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }

    let windows = windowList.compactMap { windowInfo -> [String: Any]? in
      if let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int,
        ownerPID == pid
      {
        return parseWindowInfo(windowInfo)
      }
      return nil
    }

    result(windows)
  }

  /// Gets detailed information about a specific window
  private func getWindowInfo(windowId: Int, result: @escaping FlutterResult) {
    // Check Screen Recording permission first
    if !checkScreenRecordingPermission() {
      openScreenRecordingSettings()
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details:
            "Screen Recording permission required. System Preferences opened - please enable and try again."
        ))
      return
    }

    guard
      let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        as? [[String: Any]]
    else {
      result(
        WindowControllerError.windowListFailed.asFlutterError(
          details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }

    for windowInfo in windowList {
      if let id = windowInfo[kCGWindowNumber as String] as? Int,
        id == windowId
      {
        result(parseWindowInfo(windowInfo))
        return
      }
    }

    result(
      WindowControllerError.windowNotFound.asFlutterError(
        details: "Window ID \(windowId) not found"))
  }

  /// Checks if a window with the given ID still exists
  private func isWindowValid(windowId: Int, result: @escaping FlutterResult) {
    // Check Screen Recording permission first
    if !checkScreenRecordingPermission() {
      openScreenRecordingSettings()
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details:
            "Screen Recording permission required. System Preferences opened - please enable and try again."
        ))
      return
    }

    guard
      let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        as? [[String: Any]]
    else {
      result(
        WindowControllerError.windowListFailed.asFlutterError(
          details: "CGWindowListCopyWindowInfo returned nil"))
      return
    }

    for windowInfo in windowList {
      if let id = windowInfo[kCGWindowNumber as String] as? Int,
        id == windowId
      {
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
    result(
      WindowControllerError.closeFailed.asFlutterError(
        details: "Window closing not yet implemented"))
  }

  /// Check all relevant permissions status
  private func checkPermissions(result: @escaping FlutterResult) {
    let permissions = [
      "screenRecording": checkScreenRecordingPermission(),
      "accessibility": checkAccessibilityPermission()
    ]
    
    result(permissions)
  }

  /// Captures a screenshot of the specified window
  /// Requires Screen Recording permission on macOS 10.15+
  /// - Parameters:
  ///   - windowId: The window ID to capture
  ///   - options: Capture options ("INCLUDE_FRAME" or "CONTENT_ONLY")
  ///   - result: Flutter result callback
  private func captureWindow(windowId: Int, options: String, result: @escaping FlutterResult) {
    // Check Screen Recording permission first - REQUIRED for all captures
    if !checkScreenRecordingPermission() {
      openScreenRecordingSettings()
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details:
            "Screen Recording permission required. System Preferences opened - please enable and try again."
        ))
      return
    }

    let windowID = CGWindowID(windowId)

    // Get window information for the specific window
    guard
      let windowList = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID)
        as? [[String: Any]],
      let windowInfo = windowList.first,
      let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
      let x = bounds["X"] as? Double,
      let y = bounds["Y"] as? Double,
      let width = bounds["Width"] as? Double,
      let height = bounds["Height"] as? Double
    else {
      result(
        WindowControllerError.windowNotFound.asFlutterError(
          details: "Failed to get window bounds for window \(windowId)"))
      return
    }

    // Analyze window properties for titlebar detection
    let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
    let windowLayer = windowInfo[kCGWindowLayer as String] as? Int ?? 0
    let ownerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""

    // Calculate capture rectangle based on options
    let captureRect: CGRect
    if options == "CONTENT_ONLY" {
      let originalWindowBounds = CGRect(x: x, y: y, width: width, height: height)

      // For Content Only mode, try to use AXUIElement for accurate content bounds
      if checkAccessibilityPermission() {

        if let contentBounds = getWindowContentBounds(
          windowId: windowId, windowBounds: originalWindowBounds)
        {
          captureRect = contentBounds
        } else {
          captureRect = fallbackToManualCalculation(
            windowBounds: originalWindowBounds,
            windowName: windowName,
            windowLayer: windowLayer,
            ownerName: ownerName)
        }
      } else {
        openAccessibilitySettings()

        // Fall back to manual calculation
        captureRect = fallbackToManualCalculation(
          windowBounds: originalWindowBounds,
          windowName: windowName,
          windowLayer: windowLayer,
          ownerName: ownerName)
      }
    } else {
      // Include frame - capture entire window
      captureRect = CGRect(x: x, y: y, width: width, height: height)
    }

    // Capture the window
    guard
      let image = CGWindowListCreateImage(
        captureRect,
        .optionIncludingWindow,
        windowID,
        .bestResolution
      )
    else {
      result(
        WindowControllerError.captureFailed.asFlutterError(
          details: "CGWindowListCreateImage returned nil for window \(windowId)"))
      return
    }

    // Check if captured image is empty (indicates permission issue)
    if image.width == 0 || image.height == 0 {
      result(
        WindowControllerError.screenRecordingRequired.asFlutterError(
          details: "Captured image is empty, likely due to missing Screen Recording permission"))
      return
    }

    // Convert to PNG using Core Graphics
    guard let pngData = CFDataCreateMutable(nil, 0),
      let destination = CGImageDestinationCreateWithData(pngData, kUTTypePNG, 1, nil)
    else {
      result(
        WindowControllerError.conversionFailed.asFlutterError(details: "Failed to create PNG data"))
      return
    }

    CGImageDestinationAddImage(destination, image, nil)

    if CGImageDestinationFinalize(destination) {
      let data = Data(referencing: pngData)
      result(FlutterStandardTypedData(bytes: data))
    } else {
      result(
        WindowControllerError.conversionFailed.asFlutterError(details: "Failed to finalize PNG"))
    }
  }

  private func convertCGImageToPNGData(_ cgImage: CGImage) -> Data? {
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .png, properties: [:])
  }

  /// Check if Screen Recording permissions are granted
  /// Tests by attempting a small screen capture
  private func checkScreenRecordingPermission() -> Bool {
    // Try to capture a tiny 1x1 pixel area
    let testImage = CGWindowListCreateImage(
      CGRect(x: 0, y: 0, width: 1, height: 1),
      .optionOnScreenOnly,
      kCGNullWindowID,
      .nominalResolution
    )
    
    // If capture returns nil, no permission
    return testImage != nil
  }

  /// Check if Accessibility permissions are granted
  private func checkAccessibilityPermission() -> Bool {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [checkOptPrompt: false]  // Don't show prompt, just check
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  /// Request Accessibility permissions (shows system dialog)
  private func requestAccessibilityPermission() {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [checkOptPrompt: true]  // Show prompt
    _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  /// Open System Preferences directly to Screen Recording permissions
  private func openScreenRecordingSettings() {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
    NSWorkspace.shared.open(url)
  }

  /// Open System Preferences directly to Accessibility permissions
  private func openAccessibilitySettings() {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
  }

  /// Get window content bounds using AXUIElement (more accurate than manual calculation)
  private func getWindowContentBounds(windowId: Int, windowBounds: CGRect) -> CGRect? {
    // Get all running applications
    let runningApps = NSWorkspace.shared.runningApplications

    for app in runningApps {
      guard let pid = app.processIdentifier as pid_t?,
        pid > 0
      else { continue }

      // Create AXUIElement for the application
      let appElement = AXUIElementCreateApplication(pid)

      // Get windows for this application
      var windowsRef: CFTypeRef?
      let result = AXUIElementCopyAttributeValue(
        appElement, kAXWindowsAttribute as CFString, &windowsRef)

      guard result == .success,
        let windowsArray = windowsRef as? NSArray
      else { continue }

      let windows = windowsArray as! [AXUIElement]

      // Check each window to find the one with matching bounds
      for windowElement in windows {
        if let contentBounds = getWindowContentBoundsFromElement(
          windowElement, targetBounds: windowBounds)
        {
          return contentBounds
        }
      }
    }

    return nil
  }

  /// Extract content bounds from a specific AXUIElement window
  private func getWindowContentBoundsFromElement(_ windowElement: AXUIElement, targetBounds: CGRect)
    -> CGRect?
  {
    // Get window position
    var positionRef: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
        == .success,
      let positionValue = positionRef
    else { return nil }

    var windowPosition = CGPoint.zero
    guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &windowPosition) else { return nil }

    // Get window size
    var sizeRef: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)
        == .success,
      let sizeValue = sizeRef
    else { return nil }

    var windowSize = CGSize.zero
    guard AXValueGetValue(sizeValue as! AXValue, .cgSize, &windowSize) else { return nil }

    let axWindowBounds = CGRect(origin: windowPosition, size: windowSize)

    // Check if this matches our target window (with some tolerance)
    let tolerance: CGFloat = 5
    if abs(axWindowBounds.minX - targetBounds.minX) < tolerance
      && abs(axWindowBounds.minY - targetBounds.minY) < tolerance
      && abs(axWindowBounds.width - targetBounds.width) < tolerance
      && abs(axWindowBounds.height - targetBounds.height) < tolerance
    {

      // Try to get content area (this is the magic part!)
      // Some apps expose kAXMainAttribute or content areas
      var contentRef: CFTypeRef?
      if AXUIElementCopyAttributeValue(windowElement, kAXMainAttribute as CFString, &contentRef)
        == .success,
        let contentElement = contentRef
      {
        let axContentElement = contentElement as! AXUIElement

        // Get content position and size
        var contentPosRef: CFTypeRef?
        var contentSizeRef: CFTypeRef?

        if AXUIElementCopyAttributeValue(
          axContentElement, kAXPositionAttribute as CFString, &contentPosRef) == .success,
          AXUIElementCopyAttributeValue(
            axContentElement, kAXSizeAttribute as CFString, &contentSizeRef) == .success,
          let contentPosValue = contentPosRef,
          let contentSizeValue = contentSizeRef
        {

          var contentPosition = CGPoint.zero
          var contentSize = CGSize.zero

          if AXValueGetValue(contentPosValue as! AXValue, .cgPoint, &contentPosition)
            && AXValueGetValue(contentSizeValue as! AXValue, .cgSize, &contentSize)
          {

            let contentBounds = CGRect(origin: contentPosition, size: contentSize)
            return contentBounds
          }
        }
      }

      // Fallback: Try to find the largest child element (often the content area)
      var childrenRef: CFTypeRef?
      if AXUIElementCopyAttributeValue(
        windowElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
        let childrenArray = childrenRef as? NSArray
      {

        let children = childrenArray as! [AXUIElement]

        var largestChild: (element: AXUIElement, bounds: CGRect)?

        for child in children {
          var childPosRef: CFTypeRef?
          var childSizeRef: CFTypeRef?

          if AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &childPosRef)
            == .success,
            AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &childSizeRef)
              == .success,
            let childPosValue = childPosRef,
            let childSizeValue = childSizeRef
          {

            var childPosition = CGPoint.zero
            var childSize = CGSize.zero

            if AXValueGetValue(childPosValue as! AXValue, .cgPoint, &childPosition)
              && AXValueGetValue(childSizeValue as! AXValue, .cgSize, &childSize)
            {

              let childBounds = CGRect(origin: childPosition, size: childSize)
              let childArea = childBounds.width * childBounds.height

              if largestChild == nil
                || childArea > (largestChild!.bounds.width * largestChild!.bounds.height)
              {
                largestChild = (child, childBounds)
              }
            }
          }
        }

        if let largest = largestChild {
          return largest.bounds
        }
      }

      // If we can't find content area, return the window bounds (AX might be more accurate than CGWindowList)
      return axWindowBounds
    }

    return nil
  }

  /// Fallback manual titlebar calculation when AXUIElement fails
  private func fallbackToManualCalculation(
    windowBounds: CGRect, windowName: String, windowLayer: Int, ownerName: String
  ) -> CGRect {
    let x = windowBounds.minX
    let y = windowBounds.minY
    let width = windowBounds.width
    let height = windowBounds.height

    // Calculate titlebar height dynamically (same logic as before)
    var titlebarHeight: Double = 0

    // 1. Find the correct screen for this window
    let windowCenter = CGPoint(x: x + width / 2, y: y + height / 2)
    let currentScreen =
      NSScreen.screens.first { screen in
        NSPointInRect(windowCenter, screen.frame)
      } ?? NSScreen.main
    let screenFrame = currentScreen?.frame ?? NSRect.zero

    // 2. Detect fullscreen windows (more accurate)
    let isFullscreen = (width >= screenFrame.width - 5 && height >= screenFrame.height - 5)

    // 3. Check window layer (0 = normal window, others are usually system windows)
    let isNormalWindow = (windowLayer == 0)

    // 4. Enhanced special window detection
    let isSpecialWindow =
      windowName.isEmpty || windowName.contains("Dock") || windowName.contains("Desktop")
      || windowName.contains("Wallpaper") || windowName.contains("MenuBar")
      || windowName.contains("StatusBar") || ownerName.contains("Window Server")
      || ownerName.contains("SystemUIServer")

    // 5. Detect borderless/frameless windows (common in games, video players)
    let isBorderlessWindow =
      (windowLayer != 0) || ownerName.contains("VLC") || ownerName.contains("QuickTime")
      || windowName.contains("Picture in Picture")

    if isFullscreen {
      titlebarHeight = 0
    } else if !isNormalWindow || isSpecialWindow || isBorderlessWindow {
      titlebarHeight = 0
    } else {
      // Normal window - enhanced titlebar height calculation
      if #available(macOS 13.0, *) {
        // macOS Ventura+: Slightly different heights
        titlebarHeight = 28
      } else if #available(macOS 11.0, *) {
        // macOS Big Sur/Monterey: Standard height
        titlebarHeight = 28
      } else {
        // macOS Catalina and earlier
        titlebarHeight = 22
      }

      // App-specific adjustments (optional - can be expanded)
      if ownerName.contains("Safari") || ownerName.contains("Chrome") {
        // Browsers might have slightly different titlebar heights
        titlebarHeight = 28
      } else if ownerName.contains("Terminal") || ownerName.contains("iTerm") {
        // Terminal apps often have consistent heights
        titlebarHeight = 28
      }
    }

    return CGRect(
      x: x,
      y: y + titlebarHeight,
      width: width,
      height: max(0, height - titlebarHeight)
    )
  }

  private func parseWindowInfo(_ windowInfo: [String: Any]) -> [String: Any]? {
    guard let windowId = windowInfo[kCGWindowNumber as String] as? Int,
      let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int
    else {
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
      "bounds": bounds,
    ]
  }
}
