import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PhotoFrame {
  final String id;
  final String name;
  final String assetPath;
  final bool isPremium;
  final double? price;

  PhotoFrame({
    required this.id,
    required this.name,
    required this.assetPath,
    this.isPremium = false,
    this.price,
  });
}

class PhotoFramesPage extends StatefulWidget {
  final File? imageFile;
  final Function(File, int, String)? onFrameApplied; // Updated to include frame info

  const PhotoFramesPage({
    super.key,
    required this.imageFile,
    this.onFrameApplied,
  });

  @override
  State<PhotoFramesPage> createState() => _PhotoFramesPageState();
}

class _PhotoFramesPageState extends State<PhotoFramesPage> {
  int _selectedFrameIndex = -1;
  bool _isProcessing = false;
  File? _framedImage;

  // Frame data - Make sure these asset paths match your actual files
  final List<PhotoFrame> _photoFrames = [
    PhotoFrame(
      id: '1',
      name: 'Classic White',
      assetPath: 'assets/frames/frame1.png',
    ),
    PhotoFrame(
      id: '2',
      name: 'Vintage Brown',
      assetPath: 'assets/frames/frame2.png',
    ),
    PhotoFrame(
      id: '3',
      name: 'Golden Elegant',
      assetPath: 'assets/frames/frame3.png',
      isPremium: true,
      price: 9.99,
    ),
    PhotoFrame(
      id: '4',
      name: 'Floral Design',
      assetPath: 'assets/frames/frame4.png',
    ),
    PhotoFrame(
      id: '5',
      name: 'Modern Black',
      assetPath: 'assets/frames/frame5.png',
    ),
    PhotoFrame(
      id: '6',
      name: 'Luxury Gold',
      assetPath: 'assets/frames/frame6.png',
      isPremium: true,
      price: 12.99,
    ),
    PhotoFrame(
      id: '7',
      name: 'Heart Shape',
      assetPath: 'assets/frames/frame7.png',
    ),
    PhotoFrame(
      id: '8',
      name: 'Polaroid Style',
      assetPath: 'assets/frames/frame8.png',
    ),
    PhotoFrame(
      id: '9',
      name: 'Circle Frame',
      assetPath: 'assets/frames/frame9.png',
    ),
    PhotoFrame(
      id: '10',
      name: 'Oval Vintage',
      assetPath: 'assets/frames/frame10.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CHOOSE FRAME',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedFrameIndex != -1)
            TextButton(
              onPressed: _removeFrame,
              child: Text(
                'REMOVE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview Section
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
                    // Background
                    Container(
                      color: Colors.grey.shade900,
                      child: CustomPaint(
                        painter: _CheckboardPainter(),
                      ),
                    ),

                    // Image with frame overlay
                    if (widget.imageFile != null)
                      _buildFramedImage(),

                    // Processing overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Applying Frame...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Frames Selection
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.image_aspect_ratio_outlined, color: Colors.white70, size: 16), // Fixed icon
                        SizedBox(width: 8),
                        Text(
                          'AVAILABLE FRAMES',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Spacer(),
                        if (_selectedFrameIndex != -1)
                          Text(
                            _photoFrames[_selectedFrameIndex].name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Frames Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _photoFrames.length,
                        itemBuilder: (context, index) {
                          return _buildFrameOption(_photoFrames[index], index);
                        },
                      ),
                    ),
                  ),

                  // Apply Button
                  if (_selectedFrameIndex != -1)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            onTap: _applySelectedFrame,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'APPLY FRAME',
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
          ),
        ],
      ),
    );
  }

  Widget _buildFramedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Original image
        Image.file(widget.imageFile!, fit: BoxFit.contain),

        // Frame overlay using actual PNG asset
        if (_selectedFrameIndex != -1)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_photoFrames[_selectedFrameIndex].assetPath),
                fit: BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFrameOption(PhotoFrame frame, int index) {
    final isSelected = _selectedFrameIndex == index;

    return GestureDetector(
      onTap: () => _selectFrame(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Color(0xFF6A1B9A) : Colors.grey.shade800,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.6),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Frame Preview with actual asset
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(frame.assetPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 6),

            // Frame Name
            Text(
              frame.name.split(' ').first,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),

            // Premium Badge
            if (frame.isPremium) ...[
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectFrame(int index) {
    setState(() {
      _selectedFrameIndex = index;
    });
  }

  void _removeFrame() {
    setState(() {
      _selectedFrameIndex = -1;
      _framedImage = null;
    });
  }

  Future<void> _applySelectedFrame() async {
    if (widget.imageFile == null || _selectedFrameIndex == -1) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/framed_${DateTime.now().millisecondsSinceEpoch}.png';

      // Copy the original image
      final framedFile = await widget.imageFile!.copy(outputPath);

      setState(() {
        _framedImage = framedFile;
        _isProcessing = false;
      });

      // Notify parent about the framed image AND frame info
      if (widget.onFrameApplied != null) {
        widget.onFrameApplied!(
            _framedImage!,
            _selectedFrameIndex,
            _photoFrames[_selectedFrameIndex].assetPath
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Frame applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply frame: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

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