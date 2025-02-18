import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // Required to load fonts

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0.0;
  pw.Font? regularFont;
  pw.Font? boldFont;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    loadFonts(); // Load custom fonts
  }

  Future<void> loadFonts() async {
    // Load the custom fonts
    final fontRegular =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final fontBold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    setState(() {
      regularFont = pw.Font.ttf(fontRegular);
      boldFont = pw.Font.ttf(fontBold);
    });
  }

  Future<void> fetchCartItems() async {
    final items =
        await dbHelper.getCartItems(); // Retrieve cart items from the database
    double total = 0.0;
    for (var item in items) {
      total += (item['salePrice'] as int) * (item['quantity'] as int);
    }
    setState(() {
      cartItems =
          List<Map<String, dynamic>>.from(items); // Create a mutable copy
      totalAmount = total;
    });
  }

  Future<void> generateInvoice(BuildContext context) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cart is empty. Add items to generate an invoice.')),
      );
      return;
    }

    try {
      // Ensure fonts are loaded
      if (regularFont == null || boldFont == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fonts are still loading. Try again.')),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add page to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      font: boldFont),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Items:', style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                ...cartItems.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item['name'], style: pw.TextStyle(font: regularFont)),
                      pw.Text('x${item['quantity']}', style: pw.TextStyle(font: regularFont)),
                      pw.Text(
                          '₹${(item['salePrice'] as int) * (item['quantity'] as int)}',
                          style: pw.TextStyle(font: regularFont)),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Amount:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, font: boldFont)),
                    pw.Text('\$${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, font: boldFont)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF to the device
      final output = await getExternalStorageDirectory();
      final file = File('${output?.path}/invoice.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice generated successfully.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // Code to open the generated PDF
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cart Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Text('No items in the cart.'),
                    )
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading:
                                Icon(Icons.shopping_bag, color: Colors.blue),
                            title: Text(item['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity: ${item['quantity']}'),
                                Text('Price: ₹${item['salePrice']}'),
                              ],
                            ),
                            trailing: Text(
                              'Total: ₹${(item['salePrice'] as int) * (item['quantity'] as int)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => generateInvoice(context),
              child: Text('Generate Invoice'),
            ),
          ],
        ),
      ),
    );
  }
}
