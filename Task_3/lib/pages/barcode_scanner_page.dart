import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart'; // Import the barcode_scan2 package
import 'package:myapp/db_helper.dart'; // Import your database helper to query the database

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String barcodeResult = "";
  String barcodeFormat = "";
  String rawContent = "";
  Map<String, dynamic>? productDetails;
  TextEditingController barcodeController =
      TextEditingController(); // Controller for manual input

  @override
  void initState() {
    super.initState();
  }

  // Function to handle the barcode scan
  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan(); // Start scanning the barcode

      if (result.rawContent.isNotEmpty) {
        setState(() {
          barcodeResult = result.rawContent;
          barcodeFormat = result.format.toString();
          rawContent = result.rawContent;
          barcodeController.clear(); // Clear manual input field when scanning
        });

        // Query the database for product details using the scanned barcode
        await fetchProductDetails(barcodeResult);
      }
    } catch (e) {
      print('Error scanning barcode: $e');
    }
  }

  // Function to fetch product details from the database
  Future<void> fetchProductDetails(String barcode) async {
    final product = await DatabaseHelper().getProductByBarcode(barcode);
    if (product != null) {
      setState(() {
        productDetails = product;
      });
    } else {
      setState(() {
        productDetails = null; // Product not found
      });
    }
  }

  // Function to handle manual barcode input
  Future<void> submitManualBarcode() async {
    String manualBarcode = barcodeController.text.trim();

    if (manualBarcode.isNotEmpty) {
      setState(() {
        barcodeResult = manualBarcode;
        barcodeController.clear(); // Clear manual input field after submitting
      });

      // Fetch product details from the database based on the entered barcode
      await fetchProductDetails(barcodeResult);
    }
  }

  // Function to reset all data
  void reset() {
    setState(() {
      barcodeResult = "";
      barcodeFormat = "";
      rawContent = "";
      productDetails = null;
      barcodeController.clear(); // Clear manual input field
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan or Enter Barcode'),
      ),
      body: SingleChildScrollView(
        // Make body scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Button to scan barcode
              ElevatedButton(
                onPressed: scanBarcode,
                child: Text('Scan Barcode'),
              ),
              SizedBox(height: 20),

              // Manual barcode input field (show it only if barcode is not scanned)
              if (barcodeResult.isEmpty)
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Enter Barcode Manually',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              SizedBox(height: 10),

              // Button to submit manually entered barcode
              if (barcodeResult.isEmpty)
                ElevatedButton(
                  onPressed: submitManualBarcode,
                  child: Text('Submit Barcode'),
                ),
              SizedBox(height: 20),

              // Display barcode and details only if a barcode is scanned or entered
              if (barcodeResult.isNotEmpty) ...[
                Text('Scanned/Entered Barcode: $barcodeResult'),
                if (barcodeFormat.isNotEmpty)
                  Text('Barcode Format: $barcodeFormat'),
                if (rawContent.isNotEmpty) Text('Raw Content: $rawContent'),
                if (productDetails != null) ...[
                  // Show all available product details
                  Text('Product Name: ${productDetails!['name']}'),
                  Text('Barcode: ${productDetails!['barcode']}'),
                  Text('Regular Price: \$${productDetails!['regularPrice']}'),
                  Text('Sale Price: \$${productDetails!['salePrice']}'),
                  Text('In Stock: ${productDetails!['inStock']}'),
                ] else ...[
                  Text('Product not found in the database.'),
                ],
                SizedBox(height: 20),
              ],

              // Reset Button to clear all fields
              if (barcodeResult.isNotEmpty || productDetails != null)
                ElevatedButton(
                  onPressed: reset,
                  child: Text('Reset'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
