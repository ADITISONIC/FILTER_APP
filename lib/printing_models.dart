// printing_models.dart
class PrintingOptions {
  final String size;
  final int copies;
  final double price;

  PrintingOptions({
    required this.size,
    required this.copies,
    required this.price,
  });

  double get totalAmount => price * copies;
}

class PaymentDetails {
  final String orderId;
  final double amount;
  final String status;
  final DateTime timestamp;

  PaymentDetails({
    required this.orderId,
    required this.amount,
    required this.status,
    required this.timestamp,
  });
}