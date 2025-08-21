import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:macos_window_controller/macos_window_controller.dart';

class WindowTestPage extends StatefulWidget {
  const WindowTestPage({super.key});

  @override
  State<WindowTestPage> createState() => _WindowTestPageState();
}

class _WindowTestPageState extends State<WindowTestPage> {
  final _windowController = MacosWindowController();
  final _pidController = TextEditingController();

  List<WindowInfo> _allWindows = [];
  List<WindowInfo> _pidWindows = [];
  bool _isLoading = false;
  String _status = '';
  Uint8List? _capturedImage;
  int? _capturedWindowId;
  WindowCaptureOptions _captureOptions = WindowCaptureOptions.includeFrame;
  Map<String, bool>? _permissions;

  @override
  void dispose() {
    _pidController.dispose();
    super.dispose();
  }

  Future<void> _getAllWindows() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading all windows...';
    });

    try {
      final windows = await _windowController.getAllWindows();
      setState(() {
        _allWindows = windows;
        _status = 'Found ${windows.length} windows';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getWindowsByPid() async {
    final pidText = _pidController.text.trim();
    if (pidText.isEmpty) {
      setState(() {
        _status = 'Please enter a PID';
      });
      return;
    }

    final pid = int.tryParse(pidText);
    if (pid == null) {
      setState(() {
        _status = 'Invalid PID format';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Loading windows for PID $pid...';
    });

    try {
      final windows = await _windowController.getWindowsByPid(pid);
      setState(() {
        _pidWindows = windows;
        _status = 'Found ${windows.length} windows for PID $pid';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking permissions...';
    });

    try {
      final permissions = await _windowController.checkPermissions();
      setState(() {
        _permissions = permissions;
        _status = 'Permissions checked - Screen Recording: ${permissions['screenRecording']}, Accessibility: ${permissions['accessibility']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildWindowTile(WindowInfo window) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          window.windowName.isEmpty ? 'Unnamed Window' : window.windowName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Window ID: ${window.windowId}'),
            Text('PID: ${window.ownerPID}'),
            Text('Size: ${window.width.toInt()}x${window.height.toInt()}'),
            Text('Position: (${window.x.toInt()}, ${window.y.toInt()})'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _showWindowDetails(window),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _checkWindowValid(window.windowId),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _captureWindow(window.windowId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkWindowValid(int windowId) async {
    try {
      final isValid = await _windowController.isWindowValid(windowId);
      setState(() {
        _status = 'Window $windowId is ${isValid ? 'valid' : 'invalid'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking window $windowId: $e';
      });
    }
  }

  Future<void> _captureWindow(int windowId) async {
    setState(() {
      _isLoading = true;
      _status = 'Capturing window $windowId...';
    });

    try {
      final imageData = await _windowController.captureWindow(
        windowId,
        options: _captureOptions,
      );

      print("windowId:$windowId,_captureOptions: $_captureOptions");

      if (imageData != null && imageData.isNotEmpty) {
        setState(() {
          _capturedImage = imageData;
          _capturedWindowId = windowId;
          _status =
              'Window $windowId captured successfully (${imageData.length} bytes) - ${_captureOptions == WindowCaptureOptions.contentOnly ? 'Content Only' : 'Include Frame'}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = 'Failed to capture window $windowId - no data returned';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error capturing window $windowId: $e';
        _isLoading = false;
      });
    }
  }

  void _showWindowDetails(WindowInfo window) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Window ${window.windowId} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${window.windowName}'),
            Text('Window ID: ${window.windowId}'),
            Text('Owner PID: ${window.ownerPID}'),
            Text('Position: (${window.x.toInt()}, ${window.y.toInt()})'),
            Text('Size: ${window.width.toInt()} x ${window.height.toInt()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Controller Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Permissions Section
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _checkPermissions,
                            icon: Icon(
                              _permissions != null ? Icons.security : Icons.security_outlined,
                              color: _permissions != null 
                                ? (_permissions!['screenRecording']! && _permissions!['accessibility']! 
                                  ? Colors.green : Colors.orange) 
                                : null,
                            ),
                            label: const Text('Check Permissions'),
                          ),
                        ),
                        if (_permissions != null) ...[
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _permissions!['screenRecording']! ? Icons.check_circle : Icons.cancel,
                                    color: _permissions!['screenRecording']! ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Screen Recording', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    _permissions!['accessibility']! ? Icons.check_circle : Icons.cancel,
                                    color: _permissions!['accessibility']! ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Accessibility', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _getAllWindows,
                      child: const Text('Get All Windows'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pidController,
                            decoration: const InputDecoration(
                              labelText: 'PID',
                              hintText: 'Enter process ID',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _getWindowsByPid,
                          child: const Text('Get Windows'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Capture Options:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<WindowCaptureOptions>(
                            title: const Text('Include Frame'),
                            subtitle: const Text('Capture entire window'),
                            value: WindowCaptureOptions.includeFrame,
                            groupValue: _captureOptions,
                            onChanged: (WindowCaptureOptions? value) {
                              setState(() {
                                _captureOptions =
                                    value ?? WindowCaptureOptions.includeFrame;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<WindowCaptureOptions>(
                            title: const Text('Content Only'),
                            subtitle: const Text('Exclude titlebar & frame'),
                            value: WindowCaptureOptions.contentOnly,
                            groupValue: _captureOptions,
                            onChanged: (WindowCaptureOptions? value) {
                              setState(() {
                                _captureOptions =
                                    value ?? WindowCaptureOptions.includeFrame;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Status
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Captured Image Preview
            if (_capturedImage != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Captured Window $_capturedWindowId',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _capturedImage = null;
                                _capturedWindowId = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _capturedImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Results
            const SizedBox(height: 16),
            SizedBox(
              height: 400, // 고정 높이 설정
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'All Windows'),
                        Tab(text: 'PID Windows'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // All Windows Tab
                          _allWindows.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No windows loaded. Click "Get All Windows" to start.',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _allWindows.length,
                                  itemBuilder: (context, index) {
                                    return _buildWindowTile(_allWindows[index]);
                                  },
                                ),

                          // PID Windows Tab
                          _pidWindows.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No windows for the specified PID.',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _pidWindows.length,
                                  itemBuilder: (context, index) {
                                    return _buildWindowTile(_pidWindows[index]);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
