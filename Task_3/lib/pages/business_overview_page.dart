import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class BusinessOverviewPage extends StatefulWidget {
  @override
  _BusinessOverviewPageState createState() => _BusinessOverviewPageState();
}

class _BusinessOverviewPageState extends State<BusinessOverviewPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper dbHelper = DatabaseHelper();
  double totalRevenue = 0.0;
  int totalProductsSold = 0;
  double totalProfit = 0.0;
  List<Map<String, dynamic>> topSellingProducts = [];
  List<Map<String, dynamic>> lowStockProducts = [];
  List<Map<String, dynamic>> remainingStock = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchBusinessData();
  }

  Future<void> fetchBusinessData() async {
    try {
      final data = await dbHelper.getBusinessOverview();
      final topSelling = await dbHelper.getTopSellingProducts();
      final lowStock = await dbHelper.getLowStockProducts(10); // Low stock threshold is 10
      final stock = await dbHelper.getRemainingStock();

      setState(() {
        totalRevenue = data['totalValue'] ?? 0.0;
        totalProductsSold = data['totalQuantity'] ?? 0;
        totalProfit = data['profit'] ?? 0.0;
        topSellingProducts = topSelling;
        lowStockProducts = lowStock;
        remainingStock = stock;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching business data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Overview'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Product Performance'),
            Tab(text: 'Stock Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Business Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      'Total Revenue',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '₹${totalRevenue.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      'Total Products Sold',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$totalProductsSold',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      'Total Profit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '₹${totalProfit.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Performance Tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: topSellingProducts.length + lowStockProducts.length,
              itemBuilder: (context, index) {
                if (index < topSellingProducts.length) {
                  final product = topSellingProducts[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                      leading: Icon(Icons.trending_up, color: Colors.green),
                      title: Text('${product['name']}'),
                      subtitle: Text('Sold: ${product['totalSold']}'),
                    ),
                  );
                } else {
                  final product = lowStockProducts[index - topSellingProducts.length];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                      leading: Icon(Icons.warning, color: Colors.orange),
                      title: Text('${product['name']}'),
                      subtitle: Text('Remaining Stock: ${product['stockQuantity']}'),
                    ),
                  );
                }
              },
            ),
          ),

          // Stock Insights Tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: remainingStock.length,
              itemBuilder: (context, index) {
                final product = remainingStock[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    leading: Icon(Icons.inventory, color: Colors.blue),
                    title: Text('${product['name']}'),
                    subtitle: Text('Remaining Stock: ${product['stockQuantity']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
