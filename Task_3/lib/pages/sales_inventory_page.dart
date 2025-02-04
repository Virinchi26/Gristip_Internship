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

class AddProductPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sellingPriceController =
      TextEditingController(); // For selling price
  final TextEditingController mrpController =
      TextEditingController(); // For MRP
  final TextEditingController quantityController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();

  void addProduct(BuildContext context) async {
    final name = nameController.text.trim();
    final sellingPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
    final mrp = double.tryParse(mrpController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 0;

    try {
      await dbHelper.addProduct(
          name, sellingPrice, mrp, quantity); // Save only selling price and MRP
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully.')),
      );
      nameController.clear();
      sellingPriceController.clear();
      mrpController.clear();
      quantityController.clear();
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
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: sellingPriceController,
              decoration: InputDecoration(labelText: 'Selling Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: mrpController,
              decoration: InputDecoration(labelText: 'MRP'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
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

class SellProductPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  void sellProduct(BuildContext context) async {
  final name = nameController.text.trim();
  final quantity = int.tryParse(quantityController.text) ?? 0;

  try {
    final product = await dbHelper.getProductByName(name);
    if (product != null) {
      final productId = product['id'] as int;
      final currentStock = product['stockQuantity'] as int;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
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
    );
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
