import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:pdf/widgets.dart' as pw;
import 'past_transactions_page.dart';

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
  bool isDeliveryMode = false; // Toggle for On-Site / Delivery mode
  List<String> phoneNumberSuggestions = [];
  List<String> previousPhoneNumbers =
      []; // Store previously entered phone numbers

  FocusNode productSearchFocusNode = FocusNode();
  FocusNode customerPhoneFocusNode = FocusNode();

  bool showPhoneSuggestions = false; // Flag for phone number suggestions
  bool showProductSuggestions = false; // Flag for product search suggestions
  @override
  void initState() {
    super.initState();
    _fetchProducts();
      _fetchPhoneNumbers(); // Fetch phone numbers
      customerPhoneFocusNode.addListener(() {
      setState(() {
        // When the focus changes, toggle visibility of phone number suggestions
        showPhoneSuggestions = customerPhoneFocusNode.hasFocus;
      });
    });

       productSearchFocusNode.addListener(() {
      setState(() {
        showProductSuggestions = productSearchFocusNode.hasFocus;
      });
    });
  }
  Future<void> _fetchPhoneNumbers() async {
    List<String> numbers = await DatabaseHelper().getAllPhoneNumbers();
    setState(() {
      phoneNumberSuggestions = numbers;
    });
  }
  //   void toggleMode(bool value) {
  //   setState(() {
  //     isDelivery = value;
  //     customerNameController.clear();
  //     customerPhoneController.clear();
  //   });
  // }

  // void handlePhoneNumberInput(String value) {
  //   if (isDelivery) {
  //     // Add suggestions for phone number if in Delivery mode
  //     setState(() {
  //       showSuggestions = true;
  //     });
  //   }
  // }


  // // Handle the "Complete Sale" button action
  // void completeSale() async {
  //   // Reset the cart and customer fields inside setState to ensure the UI updates
  //   setState(() {
  //     // Reset cart and customer fields
  //     cart.clear();
  //     customerNameController.clear();
  //     customerPhoneController.clear();
  //     productSearchController.clear();
  //     filteredProducts = List<Map<String, dynamic>>.from(
  //         productList); // Reset product list view
  //   });
  //   FocusScope.of(context).unfocus();
  // }
  // Show prompt when the cart is empty
  void _showCartEmptyPrompt(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cart is Empty"),
          content: Text(message),
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
void completeSale() async {
  if (cart.isEmpty) {
      // If the cart is empty, show a dialog to inform the user
      _showCartEmptyPrompt(
          "Add product to the cart before completing the sale.");
      return; // Stop further execution if cart is empty
    }
  if (isDeliveryMode && customerPhoneController.text.isEmpty ){
    _showCustomerDetailsPrompt("Phone number is required for delivery.");
    return;
  }
    // // Ensure customer details are entered before proceeding
    // if (isDelivery && customerPhoneController.text.isEmpty) {
    //   _showCustomerDetailsPrompt("Phone number is required for delivery.");
    //   return;
    // }

    // Prepare transaction data
    Map<String, dynamic> transaction = {
      "customerName": customerNameController.text,
      "customerPhone": customerPhoneController.text,
      "totalAmount": calculateTotal(),
      "paymentMethod": paymentMethod,
      "transactionDate": DateTime.now().toIso8601String(), // Store current date
    };

    // Insert transaction into the database and get the transaction ID
    int transactionId = await DatabaseHelper().insertTransaction(transaction);

    if (transactionId <= 0) {
      print("Failed to insert transaction.");
      return;
    }

    // Insert items into the transaction_items table
    for (var item in cart) {
      Map<String, dynamic> transactionItem = {
        "transactionId": transactionId, // Link to the transaction
        "productId": item["barcode"], // Using barcode as the unique identifier
        "quantity": item["quantity"],
        "salePrice": item["price"],
        "discount": item["discount"],
        "tax": item["tax"],
        "subtotal": calculateSubtotal(item),
      };

      // Insert the transaction item into the database
      int result =
          await DatabaseHelper().insertTransactionItem(transactionItem);

      if (result <= 0) {
        print("Failed to insert transaction item: ${item["name"]}");
      }
    }

    // Generate and print the invoice PDF
    await printInvoice();

    // Reset the UI after completing the sale and generating the invoice
    setState(() {
      cart.clear();
      customerNameController.clear();
      customerPhoneController.clear();
      productSearchController.clear();
      filteredProducts = List<Map<String, dynamic>>.from(productList);
    });

    // Focus out
    FocusScope.of(context).unfocus();

    // Optionally show a success message or perform further actions (like printing the invoice)
    print("Sale completed successfully. Transaction ID: $transactionId");
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

      setState(() {
        filteredProducts = productList
            .where((product) =>
                product["barcode"].contains(query) ||
                product["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    
  }

  void addProductToCart(Map<String, dynamic> product) {

      if (product["barcode"] == null) {
        print("Product barcode is missing for item: ${product["name"]}");
        return; // Exit if the product barcode is missing
      }

      setState(() {
        cart.add({
          "srNo": cart.length + 1,
          "name": product["name"],
          "barcode": product["barcode"], // Use barcode as the unique identifier
          "quantity": 1,
          "price": product["salePrice"],
          "discount": 0.0,
          "tax": 0.0,
        });
        productSearchController.clear();
        filteredProducts.clear();
      });
    
  }

  // Show prompt for missing customer details
  void _showCustomerDetailsPrompt(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Customer Details Missing"),
          content: Text(message),
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

  //   // Add suggestions for phone number input
  // Widget phoneNumberSuggestions() {
  //   return showSuggestions
  //       ? ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: previousPhoneNumbers.length,
  //           itemBuilder: (context, index) {
  //             return ListTile(
  //               title: Text(previousPhoneNumbers[index]),
  //               onTap: () {
  //                 setState(() {
  //                   customerPhoneController.text = previousPhoneNumbers[index];
  //                   showSuggestions = false; // Hide suggestions after selecting
  //                 });
  //               },
  //             );
  //           },
  //         )
  //       : SizedBox.shrink();
  // }

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
      appBar: AppBar(
        title: Text("POS System"),
        actions: [
          IconButton(
            icon: Icon(isDeliveryMode ? Icons.delivery_dining : Icons.store),
            onPressed: () {
              setState(() {
                isDeliveryMode = !isDeliveryMode;
                customerPhoneController
                    .clear(); // Clear phone number when switching modes
                phoneNumberSuggestions.clear(); // Clear suggestions
                if (isDeliveryMode) {
                  _fetchPhoneNumbers(); // Fetch phone numbers only when in Delivery mode
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PastTransactionsPage(),
                ),
              );
            }, // Navigate to the past transactions page
          ),
          
        ],
        ),
      body: SingleChildScrollView(
        // Wrap the entire body in a scrollable view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Customer Name and Phone Fields (Required)
              // if (!isDeliveryMode)
                TextField(
                  controller: customerNameController,
                  decoration: InputDecoration(labelText: "Customer Name (Optional)"),
                ),
                
              TextField(
                controller: customerPhoneController,
                focusNode: customerPhoneFocusNode,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  // labelText: "Customer Phone",
                  labelText: isDeliveryMode
                      ? "Customer Phone (Required)"
                      : "Customer Phone (Optional)",
                ),
                maxLength: 10,
                onChanged: (query) {
                  setState(() {
                    // Filter phone number suggestions based on user input
                    phoneNumberSuggestions = phoneNumberSuggestions
                        .where((phone) => phone.startsWith(query))
                        .toList();
                  });
                },
              ),
              // // if (isDeliveryMode && customerPhoneController.text.isEmpty)
              // //   Text(
              // //     "Phone number is required for delivery.",
              // //     style: TextStyle(color: Colors.red),
              // //   ),

              if (showPhoneSuggestions && phoneNumberSuggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ListView.builder(
                    shrinkWrap:
                        true, // Prevent the list from taking up unnecessary space
                    itemCount: phoneNumberSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(phoneNumberSuggestions[index]),
                        onTap: () {
                          setState(() {
                            customerPhoneController.text =
                                phoneNumberSuggestions[index];
                            phoneNumberSuggestions
                                .clear(); // Hide suggestions after selection
                          });
                        },
                      );
                    },
                  ),
                ),


              // Show phone number suggestions in Delivery mode

              // Product Search Field
              TextField(
                controller: productSearchController,
                focusNode: productSearchFocusNode,
                decoration: InputDecoration(
                  labelText: "Search by Product Name or Barcode",
                ),
                onChanged: (query) => filterProducts(query),
              ),

              // Product Suggestions
              if (showProductSuggestions && filteredProducts.isNotEmpty)
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
                                // Text(
                                //     "Customer: ${customerNameController.text}"),
                                // Text("Phone: ${customerPhoneController.text}"),
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
