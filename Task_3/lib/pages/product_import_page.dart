// import 'dart:io';
// import 'package:excel/excel.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:myapp/db_helper.dart';

// class ProductImportPage extends StatefulWidget {
//   @override
//   _ProductImportPageState createState() => _ProductImportPageState();
// }

// class _ProductImportPageState extends State<ProductImportPage> {
//   bool isLoading = false;
//   String message = "";

//   // Function to pick and process the Excel file
//   Future<void> pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx', 'xls'],
//     );

//     if (result != null) {
//       File file = File(result.files.single.path!);

//       // Parse the Excel file and insert data into SQLite
//       await processExcelFile(file);
//     }
//   }

//   // Function to process the Excel file and save data to SQLite
//   Future<void> processExcelFile(File file) async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       var bytes = file.readAsBytesSync();
//       var excel = Excel.decodeBytes(bytes);
//       List<Map<String, dynamic>> products = [];

//       // Parse the data
//       for (var sheet in excel.tables.keys) {
//         var table = excel.tables[sheet];
//         if (table != null) {
//           for (int i = 1; i < table.rows.length; i++) {
//             var row = table.rows[i];
//             if (row.length >= 4) {
//               // Handle SharedString or null values explicitly
//               products.add({
//                 "name": row[0]?.value?.toString() ?? "",         // Product name
//                 "sellingPrice": row[1]?.value ?? 0.0,             // Selling price
//                 "mrp": row[2]?.value ?? 0.0,                      // MRP
//                 "stockQuantity": row[3]?.value ?? 0,              // Stock Quantity
//               });
//             }
//           }
//         }
//       }

//       // Insert into SQLite
//       final dbHelper = DatabaseHelper();
//       for (var product in products) {
//         await dbHelper.insertProduct({
//           "name": product['name'],
//           "sellingPrice": product['sellingPrice'],
//           "mrp": product['mrp'],
//           "stockQuantity": product['stockQuantity'],
//         });
//       }

//       setState(() {
//         message = "Products imported successfully!";
//       });
//     } catch (e) {
//       setState(() {
//         message = "Error processing file: $e";
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blueAccent,
//         title: Text(
//           'Import Products',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (isLoading)
//                 CircularProgressIndicator(color: Colors.blueAccent)
//               else ...[
//                 Icon(Icons.upload_file, size: 100, color: Colors.blueAccent),
//                 SizedBox(height: 30),
//                 Text(
//                   'Select an Excel file to import products',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: pickFile,
//                   child: Text('Pick Excel File', style: TextStyle(fontSize: 16)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 5,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 if (message.isNotEmpty)
//                   Text(
//                     message,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: message.contains('success') ? Colors.green : Colors.red,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class ProductImportPage extends StatefulWidget {
  @override
  _ProductImportPageState createState() => _ProductImportPageState();
}

class _ProductImportPageState extends State<ProductImportPage> {
  bool isLoading = false;
  String message = "";
  bool _isPicking = false; // Prevent multiple file picker instances

  // Function to show a loading dialog
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from closing it manually
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(width: 20),
              Text("File is being loaded..."),
            ],
          ),
        );
      },
    );
  }

  // Function to pick and process the Excel file
  Future<void> pickFile() async {
    if (_isPicking) return; // Prevent multiple file picker calls
    _isPicking = true;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        // Show loading popup
        showLoadingDialog();

        // Parse the Excel file and insert data into SQLite
        await processExcelFile(file);
      }
    } catch (e) {
      setState(() {
        message = "Error picking file: $e";
      });
    } finally {
      _isPicking = false;
    }
  }

  // Function to process the Excel file and save data to SQLite
  Future<void> processExcelFile(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> products = [];

      // Parse the data
      for (var sheet in excel.tables.keys) {
        var table = excel.tables[sheet];
        if (table != null) {
          for (int i = 1; i < table.rows.length; i++) {
            var row = table.rows[i];
            if (row.length >= 4) {
              products.add({
                "name": row[0]?.value?.toString() ?? "", // Product name
                "sellingPrice": row[1]?.value ?? 0.0, // Selling price
                "mrp": row[2]?.value ?? 0.0, // MRP
                "stockQuantity": row[3]?.value ?? 0, // Stock Quantity
              });
            }
          }
        }
      }

      // Insert into SQLite
      final dbHelper = DatabaseHelper();
      for (var product in products) {
        await dbHelper.insertOrUpdateProduct({
          "name": product['name'],
          "sellingPrice": product['sellingPrice'],
          "mrp": product['mrp'],
          "stockQuantity": product['stockQuantity'],
        });
      }

      setState(() {
        message = "Products imported successfully!";
      });
    } catch (e) {
      setState(() {
        message = "Error processing file: $e";
      });
    } finally {
      Navigator.pop(context); // Close the loading dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Import Products',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: Colors.blueAccent)
              else ...[
                Icon(Icons.upload_file, size: 100, color: Colors.blueAccent),
                SizedBox(height: 30),
                Text(
                  'Select an Excel file to import products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await pickFile();
                  },
                  child: Text('Pick Excel File', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
                SizedBox(height: 20),
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: message.contains('success') ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

