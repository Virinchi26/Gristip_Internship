import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';


class PointOfSalePage extends StatefulWidget {
  const PointOfSalePage({super.key});

  @override
  _PointOfSalePageState createState() => _PointOfSalePageState();
}

class _PointOfSalePageState extends State<PointOfSalePage> {
  List<Product> cartItems = [];
  double totalAmount = 0.0;
  double discount = 0.0;
  double tax = 0.18; // Example: GST Tax (18%)
  String paymentMethod = 'Cash';
  TextEditingController barcodeController = TextEditingController();

  // Dummy Product Data
  List<Product> products = [
    Product(id: '1', name: 'Product A', price: 100.0),
    Product(id: '2', name: 'Product B', price: 200.0),
    Product(id: '3', name: 'Product C', price: 300.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POS System'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Cart'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: cartItems.map((item) {
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('Price: ₹${item.price}'),
                      );
                    }).toList(),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Checkout'),
                      onPressed: _checkout,
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barcode scanner input
            TextField(
              controller: barcodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Scan Barcode or Enter Product ID',
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              child: Text('Add Product to Cart'),
              onPressed: _addProductToCart,
            ),
            SizedBox(height: 16.0),
            // Payment details
            TextField(
              decoration: InputDecoration(
                labelText: 'Discount (%)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  discount = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
              value: paymentMethod,
              onChanged: (String? newValue) {
                setState(() {
                  paymentMethod = newValue!;
                });
              },
              items: ['Cash', 'Card', 'UPI']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _completeTransaction,
              child: Text('Complete Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to add product to cart
  void _addProductToCart() {
    // Example: Simply searching by Product ID
    Product? product = products.firstWhere(
      (product) => product.id == barcodeController.text,
      orElse: () => Product(id: '', name: '', price: 0.0),
    );

    if (product.id.isNotEmpty) {
      setState(() {
        cartItems.add(product);
        totalAmount += product.price;
        barcodeController.clear();
      });
    } else {
      _showError('Product not found!');
    }
  }

  // Barcode scan function (via a simple input)
  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.type == ResultType.Barcode) {
      setState(() {
        barcodeController.text = result.rawContent;
      });
    }
  }

  // Checkout function
  void _checkout() {
    Navigator.pop(context);
    _completeTransaction();
  }

  // Complete transaction
  void _completeTransaction() {
    double discountAmount = (totalAmount * discount) / 100;
    double taxedAmount = totalAmount * tax;
    double finalAmount = totalAmount - discountAmount + taxedAmount;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
            Text('Discount: ₹${discountAmount.toStringAsFixed(2)}'),
            Text('Tax (GST): ₹${taxedAmount.toStringAsFixed(2)}'),
            Text('Final Amount: ₹${finalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            Text('Payment Method: $paymentMethod'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Print Invoice'),
            onPressed: () {
              // Handle invoice printing (to be implemented)
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}
