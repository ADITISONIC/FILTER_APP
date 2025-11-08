import 'dart:io';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'printing_models.dart';

class PaymentPage extends StatefulWidget {
  final PrintingOptions printingOptions;
  final File? imageFile;

  const PaymentPage({
    Key? key,
    required this.printingOptions,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isPaymentProcessing = false;
  String _paymentStatus = 'pending';
  String? _orderId;

  // Replace with your actual Razorpay Key ID from dashboard
  final String _razorpayKey = "rzp_test_RcqpomJCIaIkrt"; // Test key
  // For production: "rzp_live_YOUR_LIVE_KEY_ID"

  // Replace with your actual UPI ID
  final String _merchantUPI = 'your-business@ybl'; // Change to your UPI ID

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _createOrder();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _createOrder() async {
    // In a real app, you would call your backend to create an order
    // For demo purposes, we're generating a client-side order ID
    setState(() {
      _orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  // Generate UPI QR code data
  String get _upiQRData {
    return 'upi://pay?pa=$_merchantUPI&pn=AI%20Photo%20Magic&am=${widget.printingOptions.totalAmount.toStringAsFixed(0)}&cu=INR&tn=Photo%20Print%20${widget.printingOptions.size}';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment Success: ${response.paymentId}');
    setState(() {
      _isPaymentProcessing = false;
      _paymentStatus = 'success';
    });

    _showPaymentSuccessDialog(response.paymentId!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    setState(() {
      _isPaymentProcessing = false;
      _paymentStatus = 'failed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openRazorpayCheckout() {
    setState(() {
      _isPaymentProcessing = true;
    });

    var options = {
      'key': _razorpayKey,
      'amount': (widget.printingOptions.totalAmount * 100).toInt(), // Amount in paise
      'name': 'AI Photo Magic',
      'description': 'Photo Print - ${widget.printingOptions.size} (${widget.printingOptions.copies} copies)',
      'order_id': _orderId, // Optional: if you have order_id from backend
      'prefill': {
        'contact': '8888888888', // You can get this from user input
        'email': 'customer@example.com', // You can get this from user input
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay']
      },
      'theme': {
        'color': '#7C4DFF', // Match your app theme
        'hide_topbar': false
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isPaymentProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Payment Successful! 🎉',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text(
                'Your order has been confirmed!\n\n'
                    '📸 ${widget.printingOptions.copies} x ${widget.printingOptions.size} Photo\n'
                    '💰 Amount: ₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}\n'
                    '📦 Order ID: ${_orderId?.substring(0, 8)}...\n'
                    '💳 Payment ID: ${paymentId.substring(0, 8)}...\n\n'
                    'Your photo will be printed shortly and delivered to you.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK', style: TextStyle(color: Colors.blue, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  // Rest of your UI code remains the same...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildOrderSummary(),
                    SizedBox(height: 30),
                    _buildQRCodeSection(),
                    SizedBox(height: 25),
                    _buildUPIIdSection(),
                    SizedBox(height: 25),
                    _buildRazorpayButton(),
                    SizedBox(height: 20),
                    _buildPaymentInstructions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'SECURE PAYMENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'ORDER SUMMARY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          _buildOrderDetail('Photo Size', widget.printingOptions.size),
          _buildOrderDetail('Number of Copies', '${widget.printingOptions.copies}'),
          _buildOrderDetail('Price per Copy', '₹${widget.printingOptions.price.toStringAsFixed(0)}'),
          Divider(color: Colors.white30),
          _buildOrderDetail(
            'TOTAL AMOUNT',
            '₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? Colors.green : Colors.white,
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Column(
      children: [
        Text(
          'Scan QR Code to Pay',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Amount: ₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: _upiQRData,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
              SizedBox(height: 15),
              Text(
                'AI Photo Magic',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'UPI Payment',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Scan with any UPI app',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUPIIdSection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'OR Send Payment to UPI ID',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _merchantUPI,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'AI Photo Magic',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.blue),
                  onPressed: () async {
                    await FlutterClipboard.copy(_merchantUPI);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('UPI ID copied to clipboard'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Amount: ₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Note: Photo Print ${widget.printingOptions.size}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRazorpayButton() {
    return Column(
      children: [
        Text(
          'Other Payment Methods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Container(
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
              onTap: _isPaymentProcessing ? null : _openRazorpayCheckout,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPaymentProcessing)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(Icons.credit_card, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      _isPaymentProcessing ? 'PROCESSING...' : 'PAY WITH CARD/BANK',
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
      ],
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '• Scan QR code with any UPI app\n'
                '• Or send payment to UPI ID shown above\n'
                '• Amount: ₹${widget.printingOptions.totalAmount.toStringAsFixed(0)}\n'
                '• Include note: "Photo Print ${widget.printingOptions.size}"\n'
                '• Payment confirmation is automatic\n'
                '• Your photos will be printed after payment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}