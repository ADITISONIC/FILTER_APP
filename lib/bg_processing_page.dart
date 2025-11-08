import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:filter_app/payment_page.dart';
import 'package:filter_app/printing_options_page.dart';
import 'package:filter_app/whatsapp_sharer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class CameraToBgFlowPage extends StatefulWidget {
  const CameraToBgFlowPage({super.key});

  @override
  State<CameraToBgFlowPage> createState() => _CameraToBgFlowPageState();
}

class _CameraToBgFlowPageState extends State<CameraToBgFlowPage>
    with WidgetsBindingObserver {

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCamera = 0;
  bool _isCameraReady = false;
  bool _isLoading = true;
  String? _error;
  final ImagePicker _picker = ImagePicker();


  int _selectedFilter = 0;


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
  AppFlow _currentFlow = AppFlow.camera;
  File? _capturedImage;
  File? _processedImage;
  bool _isProcessing = false;
  bool _isRemovingBg = false;

  // Background options
  final List<Map<String, dynamic>> _backgroundOptions = [
    {
      'name': 'Beach',
      'image_url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400',
      'preview_color': Color(0xFF4FC3F7),
    },
    {
      'name': 'Mountain',
      'image_url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
      'preview_color': Color(0xFF388E3C),
    },
    {
      'name': 'City',
      'image_url': 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400',
      'preview_color': Color(0xFF283593),
    },
    {
      'name': 'Sunset',
      'image_url': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
      'preview_color': Color(0xFFFF9800),
    },
    {
      'name': 'Office',
      'image_url': 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=400',
      'preview_color': Color(0xFF795548),
    },
    {
      'name': 'Space',
      'image_url': 'https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=400',
      'preview_color': Color(0xFF1A237E),
    },
  ];

  Map<String, dynamic>? _selectedBackground;

  // API Configuration
  static const String _removeBgApiKey = 'AConojVSq2jeYYW2vZmJwXGz';
  static const String _picsartApiKey = 'paat-DIbr2CC1k1MKjyFFg6kgcOjyv6J';

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
      if (_currentFlow == AppFlow.camera) {
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

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras found on your device';
          _isLoading = false;
        });
        return;
      }

      // Select back camera first, or first available
      CameraDescription selectedCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Initialize controller with medium resolution for better compatibility
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      // Set focus mode - simplified approach
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus mode not supported: $e');
      }

      // Set exposure mode
      try {
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        debugPrint('Exposure mode not supported: $e');
      }

      if (!mounted) return;

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
      debugPrint('Camera initialization error: $e');
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

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      debugPrint('Camera not ready for capture');
      return;
    }

    try {
      setState(() => _isLoading = true);


      final XFile picture = await _controller!.takePicture();

      if (!mounted) return;

      final imageFile = File(picture.path);

      setState(() {
        _capturedImage = imageFile;
        _currentFlow = AppFlow.editingOptions;
        _isLoading = false;
      });

      debugPrint('Photo captured successfully: ${picture.path}');

    } on CameraException catch (e) {
      debugPrint('CameraException during capture: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to take picture: ${e.description}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error during capture: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to take picture: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeBackground() async {
    if (_capturedImage == null) return;

    setState(() {
      _isProcessing = true;
      _isRemovingBg = true;
      _error = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );

      request.headers['X-Api-Key'] = _removeBgApiKey;
      request.files.add(await http.MultipartFile.fromPath('image_file', _capturedImage!.path));
      request.fields['size'] = 'auto';

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final directory = await getTemporaryDirectory();
        final outputPath = '${directory.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(bytes);

        setState(() {
          _processedImage = outputFile;
          _isProcessing = false;
          _isRemovingBg = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Background removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to remove background: $e';
        _isProcessing = false;
        _isRemovingBg = false;
      });
    }
  }

  Future<void> _applyBackground(Map<String, dynamic> background) async {
    if (_processedImage == null && _capturedImage == null) return;

    setState(() {
      _isProcessing = true;
      _selectedBackground = background;
      _error = null;
    });

    try {
      // If we don't have a processed image (background removed), use the original
      final imageToProcess = _processedImage ?? _capturedImage;

      // Create multipart request - Using the CORRECT endpoint from your sample
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.picsart.io/tools/1.0/removebg'),
      );

      // Headers as per sample
      request.headers['x-picsart-api-key'] = _picsartApiKey;

      // Add the image file - NOT as image_url but as file upload
      request.files.add(
        await http.MultipartFile.fromPath(
            'image', // This should be the file field name
            imageToProcess!.path
        ),
      );

      // Add parameters as per sample code
      request.fields['output_type'] = 'cutout';
      request.fields['format'] = 'PNG';
      request.fields['bg_image_url'] = background['image_url'];

      debugPrint('Sending background replacement request...');
      debugPrint('Background URL: ${background['image_url']}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['data'] != null && jsonResponse['data']['url'] != null) {
          final imageUrl = jsonResponse['data']['url'];
          debugPrint('Downloading processed image from: $imageUrl');

          final imageResponse = await http.get(Uri.parse(imageUrl));

          if (imageResponse.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final outputPath = '${directory.path}/final_with_bg_${DateTime.now().millisecondsSinceEpoch}.png';
            final outputFile = File(outputPath);
            await outputFile.writeAsBytes(imageResponse.bodyBytes);

            setState(() {
              _processedImage = outputFile;
              _isProcessing = false;
              _currentFlow = AppFlow.finalOutput; // Move to final output
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Applied ${background['name']} background successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Failed to download processed image: ${imageResponse.statusCode}');
          }
        } else {
          throw Exception('Invalid API response format: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('API request failed with status ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      debugPrint('Background application error: $e');
      setState(() {
        _error = 'Failed to apply background: $e';
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply background: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveFinalImage() async {
    if (_processedImage == null && _capturedImage == null) return;

    final imageToSave = _processedImage ?? _capturedImage;

    setState(() {
      _isProcessing = true;
    });

    try {
      PermissionStatus status;
      if (await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      final appDir = Directory('${directory.path}/Pictures/AIPhotoMagic');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${appDir.path}/ai_photo_$timestamp.png';

      await imageToSave!.copy(outputPath);

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Image saved to Gallery!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      await _saveToAppDirectory();
    }
  }

  Future<void> _saveToAppDirectory() async {
    try {
      final imageToSave = _processedImage ?? _capturedImage;
      final directory = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${directory.path}/Saved_Images');

      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${savedDir.path}/ai_photo_$timestamp.png';

      await imageToSave!.copy(outputPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Image saved to app storage!'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetFlow() {
    setState(() {
      _currentFlow = AppFlow.camera;
      _capturedImage = null;
      _processedImage = null;
      _selectedBackground = null;
      _selectedFilter = 0;
      _error = null;
    });
  }

  void _goBack() {
    setState(() {
      if (_currentFlow == AppFlow.editingOptions) {
        _currentFlow = AppFlow.camera;
        _capturedImage = null;
        _processedImage = null;
      } else if (_currentFlow == AppFlow.backgroundChange) {
        _currentFlow = AppFlow.editingOptions;
      } else if (_currentFlow == AppFlow.finalOutput) {
        _currentFlow = AppFlow.editingOptions;
      }
    });
  }

  Widget _buildCameraView() {
    if (_isLoading) {
      return _buildLoadingIndicator('INITIALIZING CAMERA');
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildLoadingIndicator('PREPARING CAMERA');
    }

    return Stack(
      children: [
        // Camera Preview with current filter
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: _filters[_selectedFilter]['colorFilter'] ?? ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
            child: CameraPreview(_controller!),
          ),
        ),

        // Gradient overlay for filter
        if (_filters[_selectedFilter]['gradient'] != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: _filters[_selectedFilter]['gradient'],
              ),
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.purple.withOpacity(0.4), Colors.transparent],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  _filters[_selectedFilter]['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

              if (_cameras != null && _cameras!.length > 1)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 24),
                    onPressed: _switchCamera,
                  ),
                ),
            ],
          ),
        ),

        // Filters Strip
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
        ),

        // Capture Button
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
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
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 30,
                  color: Colors.purple,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
        padding: const EdgeInsets.all(8),
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
            Container(
              width: 19,
              height: 19,
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

  Widget _buildEditingOptionsView() {
    return Column(
      children: [
        _buildFlowHeader('EDIT YOUR PHOTO'),

        // Photo Preview
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Show background if selected, otherwise show checkboard
                  if (_selectedBackground != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _selectedBackground!['preview_color'],
                            _selectedBackground!['preview_color'].withOpacity(0.7),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade900,
                      child: CustomPaint(
                        painter: _CheckboardPainter(),
                      ),
                    ),

                  // Show processed image (background removed) or original captured image
                  if (_processedImage != null)
                    Image.file(_processedImage!, fit: BoxFit.cover)
                  else if (_capturedImage != null)
                    Image.file(_capturedImage!, fit: BoxFit.cover),

                  // Apply selected filter
                  if (_filters[_selectedFilter]['colorFilter'] != null)
                    ColorFiltered(
                      colorFilter: _filters[_selectedFilter]['colorFilter']!,
                      child: Container(color: Colors.transparent),
                    ),
                  if (_filters[_selectedFilter]['gradient'] != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: _filters[_selectedFilter]['gradient'],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Filters Strip
        Container(
          height: 100,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'FILTERS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _filters[_selectedFilter]['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    return _buildFilterPreview(index, index == _selectedFilter);
                  },
                ),
              ),
            ],
          ),
        ),

        // Editing Options Buttons
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildEditingOptionButton(
                  'Remove BG',
                  Icons.auto_fix_high,
                  Colors.purple,
                  _removeBackground,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildEditingOptionButton(
                  'Change BG',
                  Icons.palette,
                  Colors.blue,
                      () {
                    setState(() {
                      _currentFlow = AppFlow.backgroundChange;
                    });
                  },
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildEditingOptionButton(
                  'Save & Share',
                  Icons.download_rounded,
                  Colors.green,
                      () {
                    setState(() {
                      _currentFlow = AppFlow.finalOutput;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditingOptionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundChangeView() {
    return Column(
      children: [
        _buildFlowHeader('CHOOSE BACKGROUND'),

        // Preview Section
        Expanded(
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Show selected background color as fallback
                  if (_selectedBackground != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _selectedBackground!['preview_color'],
                            _selectedBackground!['preview_color'].withOpacity(0.7),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade900,
                      child: CustomPaint(
                        painter: _CheckboardPainter(),
                      ),
                    ),

                  // Show the image (processed or original)
                  if (_processedImage != null)
                    Image.file(_processedImage!, fit: BoxFit.contain)
                  else if (_capturedImage != null)
                    Image.file(_capturedImage!, fit: BoxFit.contain),

                  // Apply selected filter
                  if (_filters[_selectedFilter]['colorFilter'] != null)
                    ColorFiltered(
                      colorFilter: _filters[_selectedFilter]['colorFilter']!,
                      child: Container(color: Colors.transparent),
                    ),

                  if (_filters[_selectedFilter]['gradient'] != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: _filters[_selectedFilter]['gradient'],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Background Selection Strip
        Container(
          height: 140,
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'CHOOSE BACKGROUND',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Spacer(),
                    if (_selectedBackground != null)
                      Text(
                        _selectedBackground!['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _backgroundOptions.length,
                  itemBuilder: (context, index) {
                    return _buildBackgroundOption(index);
                  },
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              // Back Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    color: Colors.transparent,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: _goBack,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: Text(
                            'BACK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),

              // Apply Button
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: _selectedBackground != null
                        ? LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)])
                        : LinearGradient(colors: [Colors.grey, Colors.grey]),
                    boxShadow: _selectedBackground != null
                        ? [BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: _selectedBackground != null
                          ? () => _applyBackground(_selectedBackground!)
                          : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'APPLY BACKGROUND',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildFinalOutputView() {
    return Column(
      children: [
        _buildFlowHeader('FINAL RESULT'),
        Expanded(
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Show the processed image with background (this is the main image)
                  if (_processedImage != null)
                    Image.file(_processedImage!, fit: BoxFit.cover)
                  else if (_capturedImage != null)
                    Image.file(_capturedImage!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.grey.shade900,
                      child: Center(
                        child: Text(
                          'No Image Available',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  // Apply selected filter overlay
                  if (_filters[_selectedFilter]['colorFilter'] != null)
                    ColorFiltered(
                      colorFilter: _filters[_selectedFilter]['colorFilter']!,
                      child: Container(color: Colors.transparent),
                    ),

                  if (_filters[_selectedFilter]['gradient'] != null)
                    Container(
                      decoration: BoxDecoration(
                        gradient: _filters[_selectedFilter]['gradient'],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              // In your main camera file, update the PRINT button section:
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () {
                        final imageToPrint = _processedImage ?? _capturedImage;
                        if (imageToPrint != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PrintingOptionsPage(
                                imageFile: imageToPrint,
                                onProceedToPayment: (printingOptions) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PaymentPage(
                                        printingOptions: printingOptions,
                                        imageFile: imageToPrint,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No image to print'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'PRINT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () {
                        final imageToShare = _processedImage ?? _capturedImage;
                        if (imageToShare != null) {
                          SocialSharer.shareWithOptions(
                            imageToShare,
                            context,
                            caption: 'Created with AI Photo Magic! 🎨\n#AIPhotoMagic',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No image to share'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'SHARE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.4), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purple.withOpacity(0.8), Colors.deepPurple.withOpacity(0.6)],
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: _goBack,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (_currentFlow == AppFlow.editingOptions)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _filters[_selectedFilter]['name'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOption(int index) {
    final option = _backgroundOptions[index];
    final isSelected = _selectedBackground == option;

    return GestureDetector(
      onTap: () => _applyBackground(option),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 70,
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [option['preview_color'], option['preview_color'].withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: option['preview_color'].withOpacity(isSelected ? 0.6 : 0.3),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(Icons.photo, color: option['preview_color'], size: 14),
            ),
            SizedBox(height: 6),
            Text(
              option['name'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            message,
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

  Widget _buildErrorWidget() {
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
              child: Icon(Icons.error, color: Colors.red, size: 40),
            ),
            SizedBox(height: 20),
            Text(
              'ERROR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
              ),
              child: ElevatedButton(
                onPressed: _resetFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text('TRY AGAIN', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
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

    try {
      _controller = CameraController(
        selectedDescription,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to switch camera: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB), Color(0xFF7C4DFF)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.3)),
                      strokeWidth: 4,
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 1000),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                        ),
                      ),
                      child: Icon(
                        _isRemovingBg ? Icons.auto_fix_high : Icons.palette,
                        color: Colors.purple,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                _isRemovingBg ? 'REMOVING BACKGROUND' : 'PROCESSING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content based on current flow
            if (_currentFlow == AppFlow.camera) _buildCameraView(),
            if (_currentFlow == AppFlow.editingOptions) _buildEditingOptionsView(),
            if (_currentFlow == AppFlow.backgroundChange) _buildBackgroundChangeView(),
            if (_currentFlow == AppFlow.finalOutput) _buildFinalOutputView(),

            // Processing Overlay
            if (_isProcessing) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }
}

enum AppFlow { camera, editingOptions, backgroundChange, finalOutput }

class _CheckboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.grey.shade800;
    final paint2 = Paint()..color = Colors.grey.shade700;
    const squareSize = 20.0;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isDark = ((x ~/ squareSize) + (y ~/ squareSize)) % 2 == 0;
        final paint = isDark ? paint1 : paint2;
        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}