import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // This will now call the onCreate method
    );
  }
  

  // Properly defining _onCreate method
  Future<void> _onCreate(Database db, int version) async {
    // User table
    await db.execute(''' 
      CREATE TABLE users ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        username TEXT UNIQUE NOT NULL, 
        password TEXT NOT NULL 
      ) 
    ''');

    // Product table
        await db.execute(''' 
      CREATE TABLE products ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        barcode TEXT UNIQUE NOT NULL,
        inStock INTEGER NOT NULL,
        regularPrice INTEGER NOT NULL,
        salePrice INTEGER NOT NULL,
        purchasePrice INTEGER NOT NULL,
        name TEXT NOT NULL
      ) 
    ''');
      //     CREATE TABLE products ( 
      //   id INTEGER PRIMARY KEY AUTOINCREMENT, 
      //   name TEXT UNIQUE NOT NULL, 
      //   sellingPrice REAL NOT NULL, 
      //   mrp REAL NOT NULL, 
      //   stockQuantity INTEGER NOT NULL 
      // ) 
    // name TEXT UNIQUE NOT NULL, 
    //     sellingPrice REAL NOT NULL,  - salePrice
    //     mrp REAL NOT NULL, - regularPrice
    //    purchasePrice REAL NOT NULL, - purchasePrice
    //     stockQuantity INTEGER NOT NULL 

    // Sales table
    await db.execute(''' 
      CREATE TABLE sales ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        productId INTEGER NOT NULL, 
        quantitySold INTEGER NOT NULL, 
        saleDate TEXT NOT NULL, 
        FOREIGN KEY (productId) REFERENCES products (id) 
      ) 
    ''');
    await db.execute('''
      CREATE TABLE Cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (productId) REFERENCES Products (id)
      );
    ''');


    // Additional table creation logic if required
  }
  // Get business overview
  // Get business overview - Adjusted to new profit calculation (sellingPrice(purchasePrice) - mrp(salePrice))
Future<Map<String, dynamic>> getBusinessOverview(String dateRange) async {
  final db = await database;

  // Query to get total revenue, total products sold, and total profit (sellingPrice(purchasePrice) - mrp(salePrice))
  final result = await db.rawQuery(''' 
    SELECT 
      SUM(p.purchasePrice * s.quantitySold) AS totalValue, 
      SUM(s.quantitySold) AS totalQuantity,
      SUM((p.salePrice - p.purchasePrice) * s.quantitySold) AS profit 
    FROM sales s 
    JOIN products p ON s.productId = p.id
  ''');

  if (result.isNotEmpty) {
    var data = result.first;

    // Handle null values explicitly for each field
    double totalValue = data['totalValue'] != null ? (data['totalValue'] as num).toDouble() : 0.0;
    int totalQuantity = data['totalQuantity'] != null ? (data['totalQuantity'] as int) : 0;
    double profit = data['profit'] != null ? (data['profit'] as num).toDouble() : 0.0;

    return {
      'totalValue': totalValue,
      'totalQuantity': totalQuantity,
      'profit': profit,
    };
  } else {
    return {
      'totalValue': 0.0,
      'totalQuantity': 0,
      'profit': 0.0,
    };
  }
}


      //   name TEXT UNIQUE NOT NULL, 
      //   sellingPrice REAL NOT NULL, 
      //   mrp REAL NOT NULL, 
      //   stockQuantity INTEGER NOT NULL 
  // Add a product - Using new sellingPrice and mrp fields
//   Future<void> addProduct(String name, double sellingPrice, double mrp, int stockQuantity) async {
//   final db = await database;

//   // Check if the product already exists
//   final existingProduct = await db.query(
//     'products',
//     where: 'name = ?',
//     whereArgs: [name],
//   );

//   if (existingProduct.isNotEmpty) {
//     // If product exists, update stock
//     await db.rawUpdate('''
//       UPDATE products 
//       SET stockQuantity = stockQuantity + ?
//       WHERE name = ?
//     ''', [stockQuantity, name]);
//   } else {
//     // Insert new product
//     await db.insert(
//       'products',
//       {
//         'name': name,
//         'sellingPrice': sellingPrice,
//         'mrp': mrp,
//         'stockQuantity': stockQuantity
//       },
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
// }
        // barode TEXT UNIQUE NOT NULL,
        // inStock INTEGER NOT NULL,
        // regularPrice INTEGER NOT NULL,
        // salePrice INTEGER NOT NULL,
        // purchasePrice INTEGER NOT NULL,
        // name TEXT NOT NULL,
  Future<void> addProduct(String barcode, int inStock, double regularPrice, double salePrice, double purchasePrice, String name ) async{
    final db = await database;
    await db.insert(
      'products',
      {
        'barcode': barcode,
        'inStock': inStock,
        'regularPrice': regularPrice,
        'salePrice': salePrice,
        'purchasePrice': purchasePrice,
        'name': name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  // Add the method to fetch product by barcode
Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
  final db = await database;
  final result = await db.query(
    'products',
    where: 'barcode = ?',
    whereArgs: [barcode],
  );
  
  if (result.isNotEmpty) {
    // Return the first matching product's details
    return result.first;
  } else {
    // Return null if no product is found
    return null;
  }
}

// Get product names by query
Future<List<String>> getProductNamesByQuery(String query) async {
  final db = await database;
  final result = await db.query(
    'products',
    columns: ['name'],
    where: 'name LIKE ?',
    whereArgs: ['%$query%'],
  );

  return result.map((product) => product['name'] as String).toList();
}

//    Future<void> insertOrUpdateProduct(Map<String, dynamic> product) async {
//   final db = await database;

//   final existingProduct = await db.query(
//     'products',
//     where: 'name = ?',
//     whereArgs: [product['name']],
//   );

//   if (existingProduct.isNotEmpty) {
//     // If product exists, update stockQuantity
//     await db.rawUpdate('''
//       UPDATE products 
//       SET stockQuantity = stockQuantity + ?
//       WHERE name = ?
//     ''', [product['stockQuantity'], product['name']]);
//   } else {
//     // If product doesn't exist, insert it as new product
//     await db.rawInsert('''
//       INSERT INTO products (name, sellingPrice, mrp, stockQuantity) 
//       VALUES (?, ?, ?, ?)
//     ''', [
//       product['name'],
//       product['sellingPrice'],
//       product['mrp'],
//       product['stockQuantity']
//     ]);
//   }
// }

  Future <void> insertOrUpdateProduct(Map<String, dynamic> product) async{
    final db = await database;
    final existingProduct = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [product['name']],
    );
    if (existingProduct.isNotEmpty){
      await db.rawUpdate('''
        UPDATE products
        SET inStock = inStock + ?
        WHERE name = ?
''', [product['inStock'], product['name']]);
    } else{
      await db.rawInsert('''
        INSERT INTO products (barcode, inStock, regularPrice, salePrice, purchasePrice, name)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        product['barcode'],
        product['inStock'],
        product['regularPrice'],
        product['salePrice'],
        product['purchasePrice'],
        product['name'],
      ]);
    }
  }


  // Get top-selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts(String dateRange) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.name, SUM(s.quantitySold) AS totalSold
      FROM sales s
      JOIN products p ON s.productId = p.id
      GROUP BY p.name
      ORDER BY totalSold DESC
      LIMIT 5
    ''');
  }

  // Get products with low stock (below a threshold, e.g., 10)
  Future<List<Map<String, dynamic>>> getLowStockProducts(int threshold) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'inStock < ?',
      whereArgs: [threshold],
    );
  }

  // Get remaining stock by product
  Future<List<Map<String, dynamic>>> getRemainingStock() async {
    final db = await database;
    return await db.query('products');
  }

  // Insert a sale record
  Future<void> insertSale(int productId, int quantitySold) async {
  final db = await database;

  // Insert the sale record into the sales table
  await db.insert(
    'sales',
    {
      'productId': productId,
      'quantitySold': quantitySold,
      'saleDate': DateTime.now().toIso8601String(),
    },
  );

  // Update the stock quantity by subtracting the quantity sold
  final updated = await db.rawUpdate('''
    UPDATE products 
    SET inStock = inStock - ? 
    WHERE id = ?
  ''', [quantitySold, productId]);

  if (updated > 0) {
    // Optionally check if stock is negative
    final product = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (product.isNotEmpty) {
      // Cast 'stockQuantity' to int (or double if required)
      final inStock = product.first['inStock'] as int? ?? 0;
      
      // Now you can safely compare it with '<'
      if (inStock < 0) {
        throw Exception("Not enough stock available.");
      }
    }
  }
}



  // Generate sales report
// Modify getSalesReport to accept a date range filter
Future<List<Map<String, dynamic>>> getSalesReport(String startDate, String endDate) async {
  final db = await database;
  return await db.rawQuery('''
    SELECT p.name, s.quantitySold, s.saleDate
    FROM sales s
    JOIN products p ON s.productId = p.id
    WHERE s.saleDate BETWEEN ? AND ?
  ''', [startDate, endDate]);
}


  // User registration
  Future<void> registerUser(String username, String password) async {
    final db = await database;
    String hashedPassword = _hashPassword(password);
    await db.insert(
      'users',
      {
        'username': username,
        'password': hashedPassword,
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }
  // Add item to the cart
  Future<void> addToCart(int productId, int quantity) async {
    final db = await database;
    await db.insert('Cart', {
      'productId': productId,
      'quantity': quantity,
    });
  }

  // Get all cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return await db.rawQuery(
      'SELECT Cart.id, Products.name, Products.salePrice, Cart.quantity '
      'FROM Cart '
      'INNER JOIN Products ON Cart.productId = Products.id'
    );
  }

  // Clear the cart
  Future<void> clearCart() async {
    final db = await database;
    try {
      await db.delete('Cart');
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }


  Future<bool> loginUser(String username, String password) async {
  if (username.isEmpty || password.isEmpty) {
    return false; // Prevent empty username/password from being checked
  }
      // Use a logging framework instead of print
  final db = await database;
  String hashedPassword = _hashPassword(password);

  final result = await db.query(
    'users',
    where: 'username = ? AND password = ?',
    whereArgs: [username, hashedPassword],
  );

  return result.isNotEmpty; // Return true only if there's a match
}


  // Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return crypto.sha256.convert(bytes).toString();
  }

  // Get product by name
  Future<Map<String, dynamic>?> getProductByName(String name) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update product stock
  Future<void> updateProductStock(int productId, int newStock) async {
    final db = await database;
    await db.update(
      'products',
      {'inStock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Generate sales insight
  Future<Map<String, dynamic>> getSalesInsight() async {
    final db = await database;

    // Query to get total sales, total products sold, and products with low stock
    final totalSalesResult = await db.rawQuery('''
      SELECT SUM(s.quantitySold) AS totalSold, SUM(p.price * s.quantitySold) AS totalSales
      FROM sales s
      JOIN products p ON s.productId = p.id
    ''');

    final lowStockResult = await db.query(
      'products',
      where: 'inStock < ?',
      whereArgs: [10], // Low stock threshold
    );

    final totalSales = totalSalesResult.isNotEmpty
        ? totalSalesResult.first['totalSales'] ?? 0.0
        : 0.0;
    final totalProductsSold = totalSalesResult.isNotEmpty
        ? totalSalesResult.first['totalSold'] ?? 0
        : 0;

    return {
      'totalSales': totalSales,
      'totalProductsSold': totalProductsSold,
      'lowStockProducts': lowStockResult.length,
    };
  }
  // Add a method to mark a sale as invoiced
  Future<void> markSaleAsInvoiced(int saleId) async {
    final db = await database;
    await db.update(
      'sales', 
      {'isInvoiced': 1}, 
      where: 'id = ?', 
      whereArgs: [saleId]
    );
  }

  // Retrieve only non-invoiced sales
  Future<List<Map<String, dynamic>>> getNonInvoicedSales() async {
    final db = await database;
    return await db.query(
      'sales', 
      where: 'isInvoiced = ?', 
      whereArgs: [0]
    );
  }

  // Add a method to store the invoice details
  Future<void> addInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    await db.insert('invoices', invoice);
  }

  // Add method to retrieve all invoices (optional)
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    return await db.query('invoices');
  }
}
