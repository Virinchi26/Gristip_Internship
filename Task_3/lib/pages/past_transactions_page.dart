import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class PastTransactionsPage extends StatefulWidget {
  const PastTransactionsPage({super.key});

  @override
  _PastTransactionsPageState createState() => _PastTransactionsPageState();
}

class _PastTransactionsPageState extends State<PastTransactionsPage> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchPastTransactions();
  }

  // Fetch all transactions and their items
  void _fetchPastTransactions() async {
    List<Map<String, dynamic>> fetchedTransactions =
        await DatabaseHelper().getTransactionWithItems();
    setState(() {
      transactions = fetchedTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Transactions")),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          var transaction = transactions[index];
          return ExpansionTile(
            title: Text("Customer: ${transaction['customerName']}"),
            subtitle: Text("Phone: ${transaction['customerPhone']}"),
            children: [
              Column(
                children: [
                  Text("Transaction Date: ${transaction['transactionDate']}"),
                  Text("Payment Method: ${transaction['paymentMethod']}"),
                  Divider(),
                  Text("Items Ordered:"),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, itemIndex) {
                      var item = transactions[itemIndex];
                      if (item['id'] == transaction['id']) {
                        return Card(
                          child: ListTile(
                            title: Text("Product ID: ${item['productId']}"),
                            subtitle: Text(
                                "Quantity: ${item['quantity']} | Price: Rs. ${item['salePrice']} | Discount: Rs. ${item['discount']} | Tax: ${item['tax']}%"),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  Divider(),
                  Text(
                      "Total: Rs. ${transaction['totalAmount'].toStringAsFixed(2)}"),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
