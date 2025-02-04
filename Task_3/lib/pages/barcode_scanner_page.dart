import 'package:flutter/material.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: const Center(
        child: Text(
          'This is the Barcode Scanner Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
