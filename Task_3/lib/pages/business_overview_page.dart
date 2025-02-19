import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String selectedDateRange = 'Today'; // Default range

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchBusinessData(selectedDateRange);
  }
Future<void> fetchBusinessData(String filter) async {
    try {
      // Get the date range based on the selected filter
      String dateRange = getDateRange(filter);

      // Fetch business overview data with the selected date filter
      final data = await dbHelper.getBusinessOverview(dateRange);

      // Fetch top-selling products within the selected date range
      final topSelling = await dbHelper.getTopSellingProducts(dateRange);

      // Fetch low-stock products (no date filter for this)
      final lowStock =
          await dbHelper.getLowStockProducts(10); // Low stock threshold is 10

      // Fetch remaining stock data (no date filter for this)
      final stock = await dbHelper.getRemainingStock();

      setState(() {
        totalRevenue = (data['totalValue'] ?? 0.0).toDouble();
        totalProductsSold = data['totalQuantity'] ?? 0;
        totalProfit = (data['profit'] ?? 0.0).toDouble();
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

// Helper function to return the date range query condition
  String getDateRange(String filter) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (filter) {
      case 'Yesterday':
        startDate = now.subtract(Duration(days: 1));
        endDate = startDate;
        break;
      case 'LastMonth':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'LastYear':
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year - 1, 12, 31);
        break;
      case 'Today':
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate
            .add(Duration(days: 1))
            .subtract(Duration(milliseconds: 1));
        break;
    }

    String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    return "WHERE s.saleDate BETWEEN '$startDateStr' AND '$endDateStr'";
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
          // Date Range Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedDateRange,
              onChanged: (newValue) {
                setState(() {
                  selectedDateRange = newValue!;
                  fetchBusinessData(selectedDateRange); // Re-fetch data when range changes
                });
              },
              items: ['Today', 'Yesterday', 'Last Month', 'Last Year']
                  .map((range) => DropdownMenuItem<String>(
                        value: range,
                        child: Text(range),
                      ))
                  .toList(),
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
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
                    itemCount:
                        topSellingProducts.length + lowStockProducts.length,
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                            leading:
                                Icon(Icons.trending_up, color: Colors.green),
                            title: Text('${product['name']}'),
                            subtitle: Text('Sold: ${product['totalSold']}'),
                          ),
                        );
                      } else {
                        final product =
                            lowStockProducts[index - topSellingProducts.length];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                            leading: Icon(Icons.warning, color: Colors.orange),
                            title: Text('${product['name']}'),
                            subtitle:
                                Text('Remaining Stock: ${product['inStock']}'),
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
                          subtitle:
                              Text('Remaining Stock: ${product['inStock']}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
  