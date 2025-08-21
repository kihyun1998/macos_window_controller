import Cocoa
import FlutterMacOS

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
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "PID is required", details: nil))
      }
    case "getWindowInfo":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        getWindowInfo(windowId: windowId, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Window ID is required", details: nil))
      }
    case "isWindowValid":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        isWindowValid(windowId: windowId, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Window ID is required", details: nil))
      }
    case "closeWindow":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        closeWindow(windowId: windowId, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Window ID is required", details: nil))
      }
    case "captureWindow":
      if let args = call.arguments as? [String: Any],
         let windowId = args["windowId"] as? Int {
        captureWindow(windowId: windowId, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Window ID is required", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getAllWindows(result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result([])
      return
    }
    
    let windows = windowList.compactMap { windowInfo -> [String: Any]? in
      return parseWindowInfo(windowInfo)
    }
    
    result(windows)
  }
  
  private func getWindowsByPid(pid: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result([])
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
  
  private func getWindowInfo(windowId: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(nil)
      return
    }
    
    for windowInfo in windowList {
      if let id = windowInfo[kCGWindowNumber as String] as? Int,
         id == windowId {
        result(parseWindowInfo(windowInfo))
        return
      }
    }
    
    result(nil)
  }
  
  private func isWindowValid(windowId: Int, result: @escaping FlutterResult) {
    guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
      result(false)
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
  
  private func closeWindow(windowId: Int, result: @escaping FlutterResult) {
    // 윈도우 닫기는 구현이 복잡하므로 일단 false 리턴
    result(false)
  }
  
  private func captureWindow(windowId: Int, result: @escaping FlutterResult) {
    // CGWindowListCreateImage를 사용하여 특정 윈도우 캡처
    
    guard let image = CGWindowListCreateImage(
      CGRect.null,
      .optionIncludingWindow,
      CGWindowID(windowId),
      [.boundsIgnoreFraming, .bestResolution]
    ) else {
      result(FlutterError(code: "CAPTURE_FAILED", message: "Failed to capture window", details: nil))
      return
    }
    
    // CGImage를 PNG 데이터로 변환
    guard let pngData = convertCGImageToPNGData(image) else {
      result(FlutterError(code: "CONVERSION_FAILED", message: "Failed to convert image to PNG", details: nil))
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
