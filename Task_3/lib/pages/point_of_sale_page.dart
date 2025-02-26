import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:pdf/widgets.dart' as pw;

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  _POSPageState createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController productSearchController = TextEditingController();

  List<Map<String, dynamic>> cart = [];
  String paymentMethod = "Cash"; // Default payment method
  Map<String, dynamic>? lastInvoice;
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> productList = [];

  FocusNode productSearchFocusNode = FocusNode();
  bool showSuggestions = false; // Flag to control suggestion visibility

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    productSearchFocusNode.addListener(() {
      if (productSearchFocusNode.hasFocus) {
        setState(() {
          showSuggestions = true;
        });
      } else {
        setState(() {
          showSuggestions = false;
        });
      }
    });
  }

  // Handle the "Complete Sale" button action
  void completeSale() async {
    // Reset the cart and customer fields inside setState to ensure the UI updates
    setState(() {
      // Reset cart and customer fields
      cart.clear();
      customerNameController.clear();
      customerPhoneController.clear();
      productSearchController.clear();
      filteredProducts = List<Map<String, dynamic>>.from(
          productList); // Reset product list view
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchProducts() async {
    List<Map<String, dynamic>> products =
        await DatabaseHelper().getRemainingStock();
    setState(() {
      productList = List<Map<String, dynamic>>.from(products);
      filteredProducts = List<Map<String, dynamic>>.from(
          products); // Initially show all products
    });
  }

  void filterProducts(String query) {
    if (customerNameController.text.isEmpty ||
        customerPhoneController.text.isEmpty) {
      // If the customer name or phone number is not entered, show an alert or prompt the user
      _showCustomerDetailsPrompt();
    } else {
      setState(() {
        filteredProducts = productList
            .where((product) =>
                product["barcode"].contains(query) ||
                product["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void addProductToCart(Map<String, dynamic> product) {
    if (customerNameController.text.isEmpty ||
        customerPhoneController.text.isEmpty) {
      // If the customer name or phone number is not entered, show an alert or prompt the user
      _showCustomerDetailsPrompt();
    } else {
      setState(() {
        cart.add({
          "srNo": cart.length + 1,
          "name": product["name"],
          "barcode": product["barcode"],
          "quantity": 1,
          "price": product["salePrice"],
          "discount": 0.0,
          "tax": 0.0,
        });
        productSearchController.clear();
        filteredProducts.clear();
      });
    }
  }

  void _showCustomerDetailsPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Customer Details Missing"),
          content:
              Text("Please enter the customer name and phone number first."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  double calculateSubtotal(Map<String, dynamic> item) {
    return (item["price"] * item["quantity"]) -
        item["discount"] +
        (item["price"] * item["tax"] / 100);
  }

  double calculateTotal() {
    return cart.fold(0.0, (sum, item) => sum + calculateSubtotal(item));
  }

  void removeCartItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void editCartItem(int index) {
    Map<String, dynamic> item = cart[index];
    TextEditingController quantityController =
        TextEditingController(text: item["quantity"].toString());
    TextEditingController discountController =
        TextEditingController(text: item["discount"].toString());
    TextEditingController taxController =
        TextEditingController(text: item["tax"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantity"),
              ),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Discount"),
              ),
              TextField(
                controller: taxController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Tax (%)"),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  cart[index]["quantity"] = int.parse(quantityController.text);
                  cart[index]["discount"] =
                      double.parse(discountController.text);
                  cart[index]["tax"] = double.parse(taxController.text);
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Print invoice function
  Future<void> printInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text("Customer: ${customerNameController.text}"),
            pw.Text("Phone: ${customerPhoneController.text}"),
            pw.Text("Payment Method: $paymentMethod"),
            pw.Text("Invoice:"),
            pw.Table.fromTextArray(
              headers: ["Sr. No", "Product Name", "Qty", "Price", "Total"],
              data: cart.map((item) {
                return [
                  item["srNo"],
                  item["name"],
                  item["quantity"],
                  item["price"],
                  calculateSubtotal(item),
                ];
              }).toList(),
            ),
            pw.Text("Total: Rs. ${calculateTotal().toStringAsFixed(2)}"),
          ],
        );
      },
    ));

    // Get the application's documents directory
    final outputDirectory = await getExternalStorageDirectory();
    final filePath =
        '${outputDirectory!.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Write the PDF file to storage
    await file.writeAsBytes(await pdf.save());

    // Open the file after saving
    OpenFile.open(filePath);

    // Optionally, you can set the path of the last invoice here for reference
    setState(() {
      lastInvoice = {
        "filePath": filePath,
        "invoiceNumber": DateTime.now().millisecondsSinceEpoch.toString()
      };
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("POS System")),
      body: SingleChildScrollView(
        // Wrap the entire body in a scrollable view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Customer Name and Phone Fields (Required)
              TextField(
                controller: customerNameController,
                decoration: InputDecoration(labelText: "Customer Name"),
              ),

              TextField(
                controller: customerPhoneController,
                keyboardType:
                    TextInputType.phone, // Set the keyboard type to phone
                decoration: InputDecoration(labelText: "Customer Phone"),
                maxLength: 10, // Limit the input to 10 digits
              ),

              // Product Search Field
              TextField(
                controller: productSearchController,
                focusNode: productSearchFocusNode,
                decoration:
                    InputDecoration(labelText: "Scan Barcode / Search Product"),
                onChanged: (query) => filterProducts(query),
              ),

              // Product Suggestions
              if (showSuggestions && filteredProducts.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(filteredProducts[index]["name"]),
                        onTap: () => addProductToCart(filteredProducts[index]),
                      );
                    },
                  ),
                ),

              // Cart Items List
              ListView.builder(
                shrinkWrap:
                    true, // This prevents the overflow by making the list's height fit the content
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  var item = cart[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Customer: ${customerNameController.text}"),
                                Text("Phone: ${customerPhoneController.text}"),
                                Text("Product Name: ${item["name"]}"),
                                Text("Qty: ${item["quantity"]}"),
                                Text("Sale Price: Rs. ${item["price"]}"),
                                Text("Discount: Rs. ${item["discount"]}"),
                                Text("Tax: ${item["tax"]}%"),
                                Text(
                                    "Subtotal: Rs. ${calculateSubtotal(item)}"),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => editCartItem(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => removeCartItem(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Final Total and Payment Method (Right-aligned)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total: Rs. ${calculateTotal().toStringAsFixed(2)}"),
                    DropdownButton<String>(
                      value: paymentMethod,
                      onChanged: (String? newValue) {
                        setState(() {
                          paymentMethod = newValue!;
                        });
                      },
                      items: <String>['Cash', 'Card', 'Multiple']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Complete Sale and Print Invoice buttons
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed:
                          completeSale, // Trigger the completeSale function
                      child: Text("Complete Sale"),
                    ),
                    IconButton(
                      onPressed: () async {
                        await printInvoice(); // Ensure the invoice is printed first
                        setState(() {
                          // Reset cart and customer details after printing the invoice
                          cart.clear();
                          customerNameController.clear();
                          customerPhoneController.clear();
                          productSearchController.clear();
                          filteredProducts = List<Map<String, dynamic>>.from(
                              productList); // Reset the products as well
                        });
                      },
                      icon: Icon(Icons.download),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}