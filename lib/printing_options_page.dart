// printing_options_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'printing_models.dart';

class PrintingOptionsPage extends StatefulWidget {
  final File? imageFile;
  final Function(PrintingOptions) onProceedToPayment;

  const PrintingOptionsPage({
    Key? key,
    required this.imageFile,
    required this.onProceedToPayment,
  }) : super(key: key);

  @override
  State<PrintingOptionsPage> createState() => _PrintingOptionsPageState();
}

class _PrintingOptionsPageState extends State<PrintingOptionsPage> {
  String _selectedSize = '3x3"';
  int _selectedCopies = 1;

  final Map<String, double> _sizePrices = {
    '3x3"': 50.0,
    '5x5"': 100.0,
    '8x8"': 200.0,
  };

  final TextEditingController _copiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _copiesController.text = _selectedCopies.toString();
    _copiesController.addListener(_onCopiesChanged);
  }

  @override
  void dispose() {
    _copiesController.dispose();
    super.dispose();
  }

  void _onCopiesChanged() {
    final text = _copiesController.text;
    if (text.isNotEmpty) {
      final copies = int.tryParse(text) ?? 1;
      setState(() {
        _selectedCopies = copies.clamp(1, 100); // Limit to 100 copies max
      });
    }
  }

  double get _totalAmount => _sizePrices[_selectedSize]! * _selectedCopies;

  void _incrementCopies() {
    setState(() {
      _selectedCopies = (_selectedCopies + 1).clamp(1, 100);
      _copiesController.text = _selectedCopies.toString();
    });
  }

  void _decrementCopies() {
    setState(() {
      _selectedCopies = (_selectedCopies - 1).clamp(1, 100);
      _copiesController.text = _selectedCopies.toString();
    });
  }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),
                    SizedBox(height: 30),
                    _buildSizeSelection(),
                    SizedBox(height: 30),
                    _buildCopiesSelection(),
                    SizedBox(height: 40),
                    _buildTotalAmount(),
                  ],
                ),
              ),
            ),
            _buildProceedButton(),
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
              'PRINTING OPTIONS',
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

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: widget.imageFile != null
            ? Image.file(widget.imageFile!, fit: BoxFit.cover)
            : Container(
          color: Colors.grey.shade800,
          child: Center(
            child: Text(
              'No Image',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT SIZE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: _sizePrices.keys.map((size) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: _buildSizeOption(size),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizeOption(String size) {
    bool isSelected = _selectedSize == size;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSize = size;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)])
                : LinearGradient(
              colors: [Colors.grey.shade800.withOpacity(0.6), Colors.grey.shade900.withOpacity(0.6)],
            ),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                size,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '₹${_sizePrices[size]!.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopiesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUMBER OF COPIES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.orange.withOpacity(0.2), Colors.deepOrange.withOpacity(0.2)],
            ),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Copies:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Max: 100 copies',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrement Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.remove, color: Colors.white),
                      onPressed: _decrementCopies,
                    ),
                  ),

                  SizedBox(width: 20),

                  // Copies Input
                  Container(
                    width: 80,
                    child: TextField(
                      controller: _copiesController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),

                  SizedBox(width: 20),

                  // Increment Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: _incrementCopies,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Total Pages: $_selectedCopies',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per copy:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '₹${_sizePrices[_selectedSize]!.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Copies:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '$_selectedCopies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return Container(
      padding: EdgeInsets.all(20),
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
            onTap: () {
              final options = PrintingOptions(
                size: _selectedSize,
                copies: _selectedCopies,
                price: _sizePrices[_selectedSize]!,
              );
              widget.onProceedToPayment(options);
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'PROCEED TO PAYMENT - ₹${_totalAmount.toStringAsFixed(0)}',
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
    );
  }
}