// upi_qr_generator.dart
class UPIQRGenerator {
  static String generateQRData({
    required String upiId,
    required String merchantName,
    required double amount,
    required String transactionNote,
    String currency = 'INR',
  }) {
    // UPI QR code format as per NPCI standards
    final params = {
      'pa': upiId, // Payee Address (VPA)
      'pn': _encodeComponent(merchantName), // Payee Name
      'am': amount.toStringAsFixed(2), // Amount
      'cu': currency, // Currency
      'tn': _encodeComponent(transactionNote), // Transaction Note
    };

    // Build URL parameters
    final queryParams = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return 'upi://pay?$queryParams';
  }

  static String _encodeComponent(String component) {
    return component.replaceAllMapped(
      RegExp(r'[^a-zA-Z0-9\-_.~]'),
          (match) => '%${match.group(0)!.codeUnitAt(0).toRadixString(16).toUpperCase()}',
    );
  }
}