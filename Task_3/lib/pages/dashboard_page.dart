import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            BlockTile(
              icon: Icons.import_export,
              label: 'Import Products',
              onTap: () {
                Navigator.pushNamed(context, '/import_products');
              },
            ),
            BlockTile(
              icon: Icons.inventory,
              label: 'Sales & Inventory',
              onTap: () {
                Navigator.pushNamed(context, '/sales_inventory');
              },
            ),
            BlockTile(
              icon: Icons.receipt,
              label: 'Invoice Generation',
              onTap: () {
                Navigator.pushNamed(context, '/invoice');
              },
            ),
            BlockTile(
              icon: Icons.qr_code_scanner,
              label: 'Barcode Scanner',
              onTap: () {
                Navigator.pushNamed(context, '/barcode_scanner');
              },
            ),
            BlockTile(
              icon: Icons.business,
              label: 'Business Overview',
              onTap: () {
                Navigator.pushNamed(context, '/business_overview');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BlockTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BlockTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
