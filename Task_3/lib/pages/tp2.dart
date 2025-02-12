import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class SalesInventoryPage extends StatefulWidget {
  @override
  _SalesInventoryPageState createState() => _SalesInventoryPageState();
}

class _SalesInventoryPageState extends State<SalesInventoryPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales and Inventory Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(context, 'Add Product', Icons.add, AddProductPage()),
            _buildTile(context, 'Sell Product', Icons.shopping_cart,
                SellProductPage()),
            _buildTile(
                context, 'Sales Report', Icons.bar_chart, SalesReportPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Future<void> addProduct(String barcode, int inStock, int regularPrice,
//     int salePrice, int purchasePrice, String name) async {
//   final db = await database;
//   await db.insert(
//     'products',
//     {
//       'barcode': barcode,
//       'inStock': inStock,
//       'regularPrice': regularPrice,
//       'salePrice': salePrice,
//       'purchasePrice': purchasePrice,
//       'name': name,
//     },
//     conflictAlgorithm: ConflictAlgorithm.replace,
//   );
class AddProductPage extends StatelessWidget {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController inStockController = TextEditingController();
  final TextEditingController regularPriceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();

  void addProduct(BuildContext context) async {
    final barcode = barcodeController.text.trim();
    final inStock = int.tryParse(inStockController.text) ?? 0;
    final regularPrice = double.tryParse(regularPriceController.text) ?? 0.0;
    final salePrice = double.tryParse(salePriceController.text) ?? 0.0;
    final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0.0;
    final name = nameController.text.trim();

    try {
      await dbHelper.addProduct(
          barcode, inStock, regularPrice, salePrice, purchasePrice, name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully.')),
      );
      barcodeController.clear();
      inStockController.clear();
      regularPriceController.clear();
      salePriceController.clear();
      purchasePriceController.clear();
      nameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(labelText: 'Barcode'),
            ),
            TextField(
              controller: inStockController,
              decoration: InputDecoration(labelText: 'In Stock'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: regularPriceController,
              decoration: InputDecoration(labelText: 'Regular Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: salePriceController,
              decoration: InputDecoration(labelText: 'Sale Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: purchasePriceController,
              decoration: InputDecoration(labelText: 'Purchase Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => addProduct(context),
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class SellProductPage extends StatefulWidget {
  @override
  _SellProductPageState createState() => _SellProductPageState();
}

class _SellProductPageState extends State<SellProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();

  List<String> suggestions = [];
  ScrollController _scrollController = ScrollController();

  void getProductSuggestions(String query) async {
    if (query.isNotEmpty) {
      // Assuming dbHelper has a method `getProductNamesByQuery`
      List<String> products = await dbHelper.getProductNamesByQuery(query);
      setState(() {
        suggestions = products;
      });
    } else {
      setState(() {
        suggestions = [];
      });
    }
  }

  void sellProduct(BuildContext context) async {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text) ?? 0;

    try {
      final product = await dbHelper.getProductByName(name);
      if (product != null) {
        final productId = product['id'] as int;
        final currentStock = product['inStock'] as int;

        if (currentStock >= quantity) {
          await dbHelper.insertSale(productId, quantity);
          await dbHelper.updateProductStock(productId, currentStock - quantity);

          // Add the product to the cart
          await dbHelper.addToCart(productId, quantity);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sale completed successfully.')),
          );
          nameController.clear();
          quantityController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not enough stock available.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sale: $e')),
      );
    }
  }

  // Reset the product name
  void resetProductName() {
    setState(() {
      nameController.clear(); // Clear the product name input
      suggestions = []; // Clear any product suggestions
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.grey),
                    onPressed:
                        resetProductName, // Reset the text when the cancel button is pressed
                  ),
                ),
                onChanged: (query) {
                  getProductSuggestions(query);
                },
              ),
              if (suggestions.isNotEmpty)
                SizedBox(
                  height: 200, // Fixed height for the suggestion list
                  child: Scrollbar(
                    thumbVisibility: true, // Make the scrollbar always visible
                    thickness:
                        6.0, // Make the scrollbar thicker for better visibility
                    radius: Radius.circular(
                        10), // Optional: Rounded edges for the scrollbar
                    controller:
                        _scrollController, // Attach the ScrollController here
                    child: ListView.builder(
                      controller:
                          _scrollController, // Attach the ScrollController here too
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.search,
                              color: Colors
                                  .grey), // Add a search icon to each suggestion
                          title: Text(suggestions[index]),
                          onTap: () {
                            nameController.text = suggestions[index];
                            setState(() {
                              suggestions =
                                  []; // Clear suggestions when one is selected
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => sellProduct(context),
                child: Text('Sell Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Don't forget to dispose of the controller
    super.dispose();
  }
}

class SalesReportPage extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> fetchSalesReport() async {
    return await dbHelper.getSalesReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Report')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchSalesReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sales data available.'));
          } else {
            final sales = snapshot.data!;
            return ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: Icon(Icons.receipt, color: Colors.blue),
                    title: Text('Product: ${sale['name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity Sold: ${sale['quantitySold']}'),
                        Text('Date: ${sale['saleDate']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
