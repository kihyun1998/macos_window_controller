
import 'macos_window_controller_platform_interface.dart';

class MacosWindowController {
  Future<String?> getPlatformVersion() {
    return MacosWindowControllerPlatform.instance.getPlatformVersion();
  }
}
