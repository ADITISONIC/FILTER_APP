import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCamera = 0;
  int _selectedFilter = 0;
  bool _isCameraReady = false;
  bool _isLoading = true;
  String? _error;
  double _cameraAspectRatio = 1.0;
  double _zoomLevel = 1.0;
  bool _isFlashOn = false;

  // Enhanced Filter configurations with gradient effects
  final List<Map<String, dynamic>> _filters = [
    {
      'name': 'Original',
      'colorFilter': null,
      'gradient': null,
    },
    {
      'name': 'Aurora',
      'colorFilter': ColorFilter.mode(Colors.purpleAccent.withOpacity(0.15), BlendMode.overlay),
      'gradient': LinearGradient(
        colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
      ),
    },
    {
      'name': 'Warm',
      'colorFilter': ColorFilter.mode(Colors.orange.withOpacity(0.25), BlendMode.overlay),
      'gradient': LinearGradient(
        colors: [Colors.orange.withOpacity(0.15), Colors.red.withOpacity(0.1)],
      ),
    },
    {
      'name': 'Crystal',
      'colorFilter': ColorFilter.mode(Colors.blueAccent.withOpacity(0.2), BlendMode.overlay),
      'gradient': LinearGradient(
        colors: [Colors.blue.withOpacity(0.15), Colors.teal.withOpacity(0.1)],
      ),
    },
    {
      'name': 'Vintage',
      'colorFilter': ColorFilter.mode(Colors.brown.withOpacity(0.3), BlendMode.overlay),
      'gradient': LinearGradient(
        colors: [Colors.brown.withOpacity(0.2), Colors.orange.withOpacity(0.15)],
      ),
    },
    {
      'name': 'Neon',
      'colorFilter': ColorFilter.mode(Colors.pink.withOpacity(0.25), BlendMode.overlay),
      'gradient': LinearGradient(
        colors: [Colors.pink.withOpacity(0.15), Colors.purple.withOpacity(0.1)],
      ),
    },
    {
      'name': 'Cyber',
      'colorFilter': ColorFilter.matrix(<double>[
        0.5, 0.3, 0.2, 0, 0,
        0.3, 0.8, 0.2, 0, 0,
        0.2, 0.3, 0.5, 0, 0,
        0,   0,   0,   1, 0,
      ]),
      'gradient': LinearGradient(
        colors: [Colors.cyan.withOpacity(0.1), Colors.purple.withOpacity(0.15)],
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras found on your device';
          _isLoading = false;
        });
        return;
      }

      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= _cameras!.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      // after initialize + small delay
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

// set autofocus & exposure to automatic
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('FocusMode not supported: $e');
      }
      try {
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        debugPrint('ExposureMode not supported: $e');
      }

      if (!mounted) return;

      final size = _controller!.value.previewSize!;
      _cameraAspectRatio = size.width / size.height;

      setState(() {
        _isCameraReady = true;
        _isLoading = false;
      });
    } on CameraException catch (e) {
      _showCameraError(e);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isLoading = false;
      });
    }
  }

  void _showCameraError(CameraException e) {
    String errorText;
    switch (e.code) {
      case 'CameraAccessDenied':
        errorText = 'Camera access was denied';
        break;
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        errorText = 'Camera access is restricted';
        break;
      default:
        errorText = 'Camera error: ${e.description}';
        break;
    }

    setState(() {
      _error = errorText;
      _isLoading = false;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isCameraReady = false;
      _isLoading = true;
    });

    await _controller?.dispose();

    _selectedCamera = (_selectedCamera + 1) % _cameras!.length;
    final selectedDescription = _cameras![_selectedCamera];

    // Try multiple resolution presets from lowest to highest
    final resolutions = [
      ResolutionPreset.low,
      ResolutionPreset.medium,
      ResolutionPreset.high,
    ];

    for (final resolution in resolutions) {
      try {
        _controller = CameraController(
          selectedDescription,
          resolution,
          enableAudio: false,
        );

        await _controller!.initialize();

        if (!mounted) return;

        setState(() {
          _isCameraReady = true;
          _isLoading = false;
        });
        return; // Success - exit the loop
      } catch (e) {
        debugPrint('Failed with $resolution: $e');
        await _controller?.dispose();
        continue; // Try next resolution
      }
    }

    // If all resolutions failed
    if (mounted) {
      setState(() {
        _error = 'Camera not supported';
        _isLoading = false;
      });
    }
  }


  Future<void> _takePicture() async {
    if (!(_controller?.value.isInitialized ?? false)) {
      debugPrint('Camera not initialized.');
      return;
    }

    if (_controller!.value.isTakingPicture) {
      debugPrint('Already taking a picture.');
      return;
    }
    try {
      setState(() => _isLoading = true);

      final isFrontCamera = _cameras![_selectedCamera].lensDirection == CameraLensDirection.front;

      // Device-specific workarounds
      if (isFrontCamera) {
        // For front camera, use a different approach
        await _takePictureFrontCamera();
      } else {
        // For back camera, use normal approach
        final picture = await _controller!.takePicture();
        _handleCapturedPicture(picture);
      }

    } catch (e) {
      debugPrint('Capture failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _takePictureFrontCamera() async {
    try {
      // Method 1: Try normal capture first
      try {
        final picture = await _controller!.takePicture();
        _handleCapturedPicture(picture);
        return;
      } catch (e) {
        debugPrint('Front camera normal capture failed: $e');
      }

      // Method 2: Try with orientation lock
      try {
        await _controller!.lockCaptureOrientation();
        final picture = await _controller!.takePicture();
        await _controller!.unlockCaptureOrientation();
        _handleCapturedPicture(picture);
        return;
      } catch (e) {
        debugPrint('Front camera capture with orientation lock failed: $e');
      }

      // Method 3: Last resort - recreate camera controller
      await _recreateCameraController();
      final picture = await _controller!.takePicture();
      _handleCapturedPicture(picture);

    } catch (e) {
      rethrow;
    }
  }

  void _handleCapturedPicture(XFile picture) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showPreview(picture);
  }

  Future<void> _recreateCameraController() async {
    final currentCamera = _cameras![_selectedCamera];
    await _controller?.dispose();

    _controller = CameraController(
      currentCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;
    setState(() {
      _isCameraReady = true;
    });
  }

  void _showPreview(XFile picture) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PREVIEW',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _filters[_selectedFilter]['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Preview Image
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand, // 👈 ensures all layers fill the container
                            children: [
                              // 🖼️ Base image fills entire area
                              Image.file(
                                File(picture.path),
                                fit: BoxFit.cover, // 👈 scales + crops to fill box perfectly
                              ),

                              // 🎨 Optional color filter overlay
                              if (_filters[_selectedFilter]['colorFilter'] != null)
                                ColorFiltered(
                                  colorFilter: _filters[_selectedFilter]['colorFilter']!,
                                  child: Container(color: Colors.transparent),
                                ),

                              // 🌈 Optional gradient overlay
                              if (_filters[_selectedFilter]['gradient'] != null)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: _filters[_selectedFilter]['gradient'],
                                  ),
                                ),

                              // (Optional) subtle dim overlay for better contrast
                              Container(
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Retake Button
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.8),
                                    Colors.redAccent.withOpacity(0.6),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  File(picture.path).delete();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Retake',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Save Button
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFFE040FB),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _saveImage(picture);
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Photo saved to gallery!'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to save photo: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveImage(XFile picture) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'filter_cam_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${directory.path}/$fileName';
      await File(picture.path).copy(savedPath);
      print('Image saved to: $savedPath');
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  Widget _buildFilterPreview(int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
          )
              : LinearGradient(
            colors: [
              Colors.grey.shade800.withOpacity(0.8),
              Colors.grey.shade900.withOpacity(0.8),
            ],
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.6),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ]
              : null,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter Preview Circle
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.blue, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    if (_filters[index]['colorFilter'] != null)
                      ColorFiltered(
                        colorFilter: _filters[index]['colorFilter']!,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.blue, Colors.green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    if (_filters[index]['gradient'] != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: _filters[index]['gradient'],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Filter Name
            Text(
              _filters[index]['name'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox.expand( // 👈 fills entire available box
        child: FittedBox(
          fit: BoxFit.cover, // 👈 makes camera feed fill completely
          child: SizedBox(
            width: _controller!.value.previewSize!.width,
            height: _controller!.value.previewSize!.height,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'INITIALIZING CAMERA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'CAMERA ERROR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _initializeCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview with Glass Morphism Effect
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                children: [
                  _buildCameraPreview(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  // Filter Application
                  if (_filters[_selectedFilter]['colorFilter'] != null)
                    ColorFiltered(
                      colorFilter: _filters[_selectedFilter]['colorFilter']!,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  if (_filters[_selectedFilter]['gradient'] != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: _filters[_selectedFilter]['gradient'],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Frame Overlay with Neon Effect
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
        ),

        // Grid Overlay
        Container(
          margin: const EdgeInsets.all(20),
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),

        // Top Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // App Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text(
                  'FILTER CAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Camera Switch Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.flip_camera_ios_rounded,
                    color: _cameras != null && _cameras!.length > 1 ? Colors.white : Colors.grey,
                    size: 24,
                  ),
                  onPressed: _cameras != null && _cameras!.length > 1 ? _switchCamera : null,
                ),
              ),
            ],
          ),
        ),

        // Capture Animation
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Camera Preview - Takes most space
            Expanded(
              flex: 4,
              child: _buildCameraView(),
            ),

            // Filters Strip
            if (_isCameraReady && _error == null)
              Container(
                height: 125,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FILTERS',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${_selectedFilter + 1}/${_filters.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          return _buildFilterPreview(index, index == _selectedFilter);
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Capture Button Section
            if (_isCameraReady && _error == null)
              Container(
                padding: const EdgeInsets.all(25),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Colors.purple,
                            Colors.purpleAccent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Capture Button
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt_rounded, size: 30),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Grid Painter for overlay
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}