class SellProductPage extends StatefulWidget {
  @override
  _SellProductPageState createState() => _SellProductPageState();
}

class _SellProductPageState extends State<SellProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Add a list to store suggestions
  List<String> suggestions = [];

  // Function to fetch product names from the database that match the entered text
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Product Name TextField
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
              onChanged: (query) {
                getProductSuggestions(query); // Fetch suggestions as user types
              },
            ),

            // Show suggestions below the TextField
            if (suggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
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

            // Quantity TextField
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

// class DatabaseHelper {
//   // Assuming you already have a database connection and query setup
//   Future<List<String>> getProductNamesByQuery(String query) async {
//     final db = await database; // Assuming you have a database instance
//     final List<Map<String, dynamic>> result = await db.query(
//       'products',
//       where: 'name LIKE ?',
//       whereArgs: ['%$query%'],
//     );

//     return List.generate(result.length, (i) {
//       return result[i]['name'] as String;
//     });
//   }
// }
