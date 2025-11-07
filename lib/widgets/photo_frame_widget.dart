import 'package:flutter/material.dart';

class PhotoFrameWidget extends StatelessWidget {
  final Widget child;
  final String frameAsset;
  final double padding;

  const PhotoFrameWidget({
    super.key,
    required this.child,
    required this.frameAsset,
    this.padding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The actual image/content
        Container(
          margin: EdgeInsets.all(padding),
          child: child,
        ),
        // Frame overlay
        if (frameAsset.isNotEmpty)
          Image.asset(
            frameAsset,
            fit: BoxFit.contain,
          ),
      ],
    );
  }
}

// Pre-defined frame styles
class FrameStyles {
  static const List<Map<String, dynamic>> frames = [
    {
      'name': 'Classic',
      'asset': 'assets/frames/classic_frame.png',
      'padding': 15.0,
    },
    {
      'name': 'Modern',
      'asset': 'assets/frames/modern_frame.png',
      'padding': 10.0,
    },
    {
      'name': 'Vintage',
      'asset': 'assets/frames/vintage_frame.png',
      'padding': 20.0,
    },
    {
      'name': 'Floral',
      'asset': 'assets/frames/floral_frame.png',
      'padding': 25.0,
    },
    {
      'name': 'Polaroid',
      'asset': 'assets/frames/polaroid_frame.png',
      'padding': 30.0,
    },
    {
      'name': 'Elegant',
      'asset': 'assets/frames/elegant_frame.png',
      'padding': 12.0,
    },
  ];
}