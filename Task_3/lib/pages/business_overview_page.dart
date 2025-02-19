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
  List<Map<String, dynamic>> remainingStock = [];
  List<Map<String, dynamic>> lowStockProducts = [];
  String selectedFilter = "Today";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchBusinessData();

    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> fetchBusinessData() async {
    try {
      final data = await dbHelper.getBusinessOverview(selectedFilter);
      final topSelling = await dbHelper.getTopSellingProducts();
      final stock = await dbHelper.getRemainingStock();
      final lowStock = await dbHelper.getLowStockProducts(10);

      setState(() {
        totalRevenue = (data['totalValue'] ?? 0).toDouble();
        totalProductsSold = (data['totalQuantity'] ?? 0).toInt();
        totalProfit = (data['profit'] ?? 0).toDouble();
        topSellingProducts = topSelling;
        remainingStock = stock;
        lowStockProducts = lowStock;
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
      body: Column(
        children: [
          if (_tabController.index == 0)
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedFilter,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedFilter = newValue;
                      });
                      fetchBusinessData();
                    }
                  },
                  underline: SizedBox(),
                  items: ["Today", "Last Week", "Last Month", "Last Year"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProductPerformanceTab(),
                _buildStockInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildOverviewCard('Total Revenue',
              '₹${totalRevenue.toStringAsFixed(2)}', Icons.monetization_on),
          _buildOverviewCard(
              'Total Products Sold', '$totalProductsSold', Icons.shopping_cart),
          _buildOverviewCard('Total Profit',
              '₹${totalProfit.toStringAsFixed(2)}', Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: topSellingProducts
            .map((product) => Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.star, color: Colors.orange),
                    title: Text(product['name'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Sold: ${product['totalSold']}'),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStockInsightsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Remaining Stock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...remainingStock.map((product) => Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.store, color: Colors.green),
                  title: Text(product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stock: ${product['inStock']}'),
                ),
              )),
          SizedBox(height: 16),
          Text('Low Stock Products',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
          ...lowStockProducts.map((product) => Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.warning, color: Colors.red),
                  title: Text(product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stock: ${product['inStock']}'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blueAccent),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle:
            Text(value, style: TextStyle(fontSize: 18, color: Colors.black87)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
