import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/product_import_page.dart';
import 'pages/sales_inventory_page.dart';
import 'pages/invoice_page.dart';
import 'pages/barcode_scanner_page.dart';
import 'pages/business_overview_page.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/import_products': (context) =>  ProductImportPage(),
        '/sales_inventory': (context) => SalesInventoryPage(),
        '/invoice': (context) => InvoicePage(),
        '/barcode_scanner': (context) =>  BarcodeScannerPage(),
        '/business_overview': (context) => BusinessOverviewPage(),
      },
    );
  }
}
