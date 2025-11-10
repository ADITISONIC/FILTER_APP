// photo_frame_model.dart
class PhotoFrame {
  final String id;
  final String name;
  final String backgroundAsset; // Full background pattern image
  final double photoPadding; // Space around the photo
  final double borderRadius; // Rounded corners for photo

  PhotoFrame({
    required this.id,
    required this.name,
    required this.backgroundAsset,
    this.photoPadding = 30.0,
    this.borderRadius = 15.0,
  });
}

// Sample frames with background patterns
List<PhotoFrame> photoFrames = [
  PhotoFrame(
    id: '1',
    name: 'Floral Pattern',
    backgroundAsset: 'assets/frames/floral_bg.jpg',
    photoPadding: 25.0,
    borderRadius: 10.0,
  ),
  PhotoFrame(
    id: '2',
    name: 'Wooden Frame',
    backgroundAsset: 'assets/frames/wooden.jpg',
    photoPadding: 20.0,
    borderRadius: 8.0,
  ),
  PhotoFrame(
    id: '3',
    name: 'Marble Luxury',
    backgroundAsset: 'assets/frames/marble_bg.jpg',
    photoPadding: 20.0,
    borderRadius: 0.0,
  ),
  PhotoFrame(
    id: '4',
    name: 'Christmas Theme',
    backgroundAsset: 'assets/frames/christmas_bg.jpg',
    photoPadding: 40.0,
    borderRadius: 12.0,
  ),
  PhotoFrame(
    id: '5',
    name: 'Vintage Paper',
    backgroundAsset: 'assets/frames/vintage_bg.jpg',
    photoPadding: 45.0,
    borderRadius: 5.0,
  ),
  PhotoFrame(
    id: '6',
    name: 'Modern Abstract',
    backgroundAsset: 'assets/frames/abstract_bg.jpg',
    photoPadding: 15.0,
    borderRadius: 20.0,
  ),
];