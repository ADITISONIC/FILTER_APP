import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SocialSharer {
  /// Main share method with WhatsApp only
  static Future<void> shareWithOptions(File imageFile, BuildContext context, {String? caption}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildWhatsAppSheet(context, imageFile, caption),
    );
  }

  static Widget _buildWhatsAppSheet(BuildContext context, File imageFile, String? caption) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SHARE ON WHATSAPP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WHATSAPP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // WhatsApp Button
            GestureDetector(
              onTap: () => _shareToWhatsApp(context, imageFile, caption),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_rounded, color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Text(
                      'SHARE TO WHATSAPP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Cancel Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.1),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Center(
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Directly share image to WhatsApp
  static Future<void> _shareToWhatsApp(BuildContext context, File imageFile, String? caption) async {
    try {
      Navigator.pop(context);
      await _showProcessingDialog(context, 'Opening WhatsApp...');

      final captionText = Uri.encodeComponent(caption ?? '🎨 Created with AI Photo Magic!');
      final whatsappUrl = Uri.parse('whatsapp://send?text=$captionText');

      // Check if WhatsApp is installed
      if (await canLaunchUrl(whatsappUrl)) {
        await Share.shareFiles(
          [imageFile.path],
          text: caption ?? '🎨 Created with AI Photo Magic!',
        );
      } else {
        _showErrorSnackBar(context, 'WhatsApp not installed on this device.');
      }

      Navigator.pop(context); // Close dialog
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(context, 'Sharing failed: $e');
    }
  }

  static Future<void> _showProcessingDialog(BuildContext context, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}