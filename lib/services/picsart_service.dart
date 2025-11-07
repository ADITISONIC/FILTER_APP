import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PicsArtService {
  static String? _apiKey;
  static const String _baseUrl = 'https://api.picsart.io/tools/1.0';
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      _apiKey = dotenv.get('PICSART_API_KEY', fallback: '');
      _isInitialized = true;
      print('✅ PicsArtService initialized - API Key: ${_apiKey != null && _apiKey!.isNotEmpty ? "Loaded" : "Not found"}');
    } catch (e) {
      print('❌ PicsArtService initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Remove background using PicsArt API
  static Future<Uint8List?> removeBackground(String imagePath) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // If no API key, use local processing immediately
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('🔄 No PicsArt API key found, using local processing');
      return await _localBackgroundRemoval(imagePath);
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ Image file not found: $imagePath');
        return await _localBackgroundRemoval(imagePath);
      }

      final bytes = await file.readAsBytes();
      print('📤 Sending image to PicsArt API (${bytes.length} bytes)');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/removebg'),
      );

      request.headers['x-picsart-api-key'] = _apiKey!;

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.png',
        ),
      );

      request.fields['output_type'] = 'cutout';
      request.fields['format'] = 'PNG';

      final response = await request.send();
      print('📥 PicsArt API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBytes = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseBytes);
        final jsonResponse = jsonDecode(responseString);

        print('✅ PicsArt API success: ${jsonResponse}');

        if (jsonResponse['data'] != null && jsonResponse['data']['url'] != null) {
          // Download the processed image from the URL
          final downloadResponse = await http.get(Uri.parse(jsonResponse['data']['url']));
          if (downloadResponse.statusCode == 200) {
            print('✅ Downloaded processed image (${downloadResponse.bodyBytes.length} bytes)');
            return downloadResponse.bodyBytes;
          }
        }
      } else {
        print('❌ PicsArt API error: ${response.statusCode}');
        final errorResponse = await response.stream.bytesToString();
        print('❌ PicsArt API error details: $errorResponse');
        return await _localBackgroundRemoval(imagePath);
      }
    } catch (e) {
      print('❌ PicsArt background removal error: $e');
      return await _localBackgroundRemoval(imagePath);
    }
    return null;
  }

  // Change background using PicsArt API
  static Future<Uint8List?> changeBackground(
      String imagePath, String backgroundImagePath) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // If no API key, use local processing immediately
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('🔄 No PicsArt API key found, using local processing');
      return await _localBackgroundChange(imagePath, backgroundImagePath);
    }

    try {
      final file = File(imagePath);
      final backgroundFile = File(backgroundImagePath);

      if (!await file.exists() || !await backgroundFile.exists()) {
        print('❌ Image files not found');
        return await _localBackgroundChange(imagePath, backgroundImagePath);
      }

      final imageBytes = await file.readAsBytes();
      final backgroundBytes = await backgroundFile.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/removebg'),
      );

      request.headers['x-picsart-api-key'] = _apiKey!;

      // Main image
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.png',
        ),
      );

      // Background image
      request.files.add(
        http.MultipartFile.fromBytes(
          'bg_image',
          backgroundBytes,
          filename: 'background.png',
        ),
      );

      request.fields['output_type'] = 'cutout';
      request.fields['format'] = 'PNG';

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBytes = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseBytes);
        final jsonResponse = jsonDecode(responseString);

        if (jsonResponse['data'] != null && jsonResponse['data']['url'] != null) {
          final downloadResponse = await http.get(Uri.parse(jsonResponse['data']['url']));
          if (downloadResponse.statusCode == 200) {
            return downloadResponse.bodyBytes;
          }
        }
      } else {
        print('❌ PicsArt background change error: ${response.statusCode}');
        return await _localBackgroundChange(imagePath, backgroundImagePath);
      }
    } catch (e) {
      print('❌ PicsArt background change error: $e');
      return await _localBackgroundChange(imagePath, backgroundImagePath);
    }
    return null;
  }

  // Local fallback for background removal
  static Future<Uint8List?> _localBackgroundRemoval(String imagePath) async {
    try {
      print('🔄 Using local background removal');
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final result = img.Image(width: image.width, height: image.height);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r as int;
          final g = pixel.g as int;
          final b = pixel.b as int;

          // Simple green screen removal
          if (g > r * 1.2 && g > b * 1.2) {
            result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          } else {
            result.setPixel(x, y, pixel);
          }
        }
      }

      print('✅ Local background removal completed');
      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      print('❌ Local background removal error: $e');
      return null;
    }
  }

  // Local fallback for background change
  static Future<Uint8List?> _localBackgroundChange(
      String imagePath, String backgroundImagePath) async {
    try {
      print('🔄 Using local background change');
      final imageFile = File(imagePath);
      final bgFile = File(backgroundImagePath);

      final imageBytes = await imageFile.readAsBytes();
      final bgBytes = await bgFile.readAsBytes();

      final originalImage = img.decodeImage(imageBytes);
      final backgroundImage = img.decodeImage(bgBytes);

      if (originalImage == null || backgroundImage == null) return null;

      // Resize background to match original image
      final resizedBg = img.copyResize(
        backgroundImage,
        width: originalImage.width,
        height: originalImage.height,
      );

      // Create result with background
      final result = img.Image(width: resizedBg.width, height: resizedBg.height);

      // Draw background
      for (int y = 0; y < resizedBg.height; y++) {
        for (int x = 0; x < resizedBg.width; x++) {
          result.setPixel(x, y, resizedBg.getPixel(x, y));
        }
      }

      // Draw foreground (with simple transparency)
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          final pixel = originalImage.getPixel(x, y);
          final r = pixel.r as int;
          final g = pixel.g as int;
          final b = pixel.b as int;

          // Only draw non-green pixels
          if (!(g > r * 1.2 && g > b * 1.2)) {
            result.setPixel(x, y, pixel);
          }
        }
      }

      print('✅ Local background change completed');
      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      print('❌ Local background change error: $e');
      return null;
    }
  }

  // Check if service is ready to use
  static bool get isReady => _isInitialized && _apiKey != null && _apiKey!.isNotEmpty;
}