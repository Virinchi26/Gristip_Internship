import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class ProductImportPage extends StatefulWidget {
  const ProductImportPage({super.key});

  @override
  _ProductImportPageState createState() => _ProductImportPageState();
}

class _ProductImportPageState extends State<ProductImportPage> {
  bool isLoading = false;
  String message = "";
  bool _isPicking = false; // Prevent multiple file picker instances
  List<Map<String, dynamic>> products = []; // Store imported products
  List<String> dbColumns = [
    'barcode',
    'inStock',
    'regularPrice',
    'salePrice',
    'purchasePrice',
    'name',
  ];
  List<String> excelColumns = [];
  bool manualMapping = false; // Whether manual mapping is selected

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
      var excelFile = excel.Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> tempProducts = [];

      // Parse the data
      for (var sheet in excelFile.tables.keys) {
        var table = excelFile.tables[sheet];
        if (table != null) {
          excelColumns = table.rows[0]
              .map((col) => col?.value?.toString() ?? "")
              .toList(); // Get column names

          for (int i = 1; i < table.rows.length; i++) {
            var row = table.rows[i];
            if (row.length >= 6) {
              tempProducts.add({
                "barcode": row[0]?.value?.toString() ?? "", // Barcode
                "inStock": row[1]?.value.toString() ?? 0, // In Stock
                "regularPrice":
                    row[2]?.value.toString() ?? 0.0, // Regular Price
                "salePrice": row[3]?.value.toString() ?? 0.0, // Sale Price
                "purchasePrice":
                    row[4]?.value.toString() ?? 0.0, // Purchase Price
                "name": row[5]?.value?.toString() ?? "", // Product name
              });
            }
          }
        }
      }

      setState(() {
        products = tempProducts;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: Text('Pick Excel File', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        message.contains('success') ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text("Manual column mapping"),
                value: manualMapping,
                onChanged: (bool? value) {
                  setState(() {
                    manualMapping = value ?? false;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (manualMapping) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDataMappingPage(
                          excelColumns: excelColumns,
                          dbColumns: dbColumns,
                          manualMapping: manualMapping,
                          excelData: products,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPreviewPage(
                          excelData: products,
                          dbColumns: dbColumns,
                          manualMapping: manualMapping,
                          columnMapping: List.filled(dbColumns.length, null),
                        ),
                      ),
                    );
                  }
                },
                child: Text('Next'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductDataMappingPage extends StatefulWidget {
  final List<String> excelColumns;
  final List<String> dbColumns;
  final bool manualMapping;
  final List<Map<String, dynamic>> excelData;

  ProductDataMappingPage({
    required this.excelColumns,
    required this.dbColumns,
    required this.manualMapping,
    required this.excelData,
  });

  @override
  _ProductDataMappingPageState createState() => _ProductDataMappingPageState();
}
class _ProductDataMappingPageState extends State<ProductDataMappingPage> {
  List<String?> columnMapping = [];

  @override
  void initState() {
    super.initState();
    columnMapping = List.filled(widget.dbColumns.length, null);
  }

  String getColumnDescription(String column) {
    switch (column) {
      case 'barcode':
        return "A barcode is a small image of lines (bars) and spaces that is affixed to retail store items, identification cards, and postal mail to identify a particular product number, person, or location.";
      case 'inStock':
        return "Represents the current quantity of the product available in the inventory.";
      case 'regularPrice':
        return "The standard price of the product before any discounts or promotions.";
      case 'salePrice':
        return "The price of the product after a discount has been applied, usually during a sale.";
      case 'purchasePrice':
        return "The price at which the product was purchased from a supplier or manufacturer.";
      case 'name':
        return "The name or description of the product being sold.";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Column Mapping'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (widget.manualMapping) ...[
              Expanded(
                child: Scrollbar(
                  thickness: 8.0,
                  radius: Radius.circular(10),
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(widget.dbColumns.length, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                            // color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side - Database column and description
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Database column name
                                    Text(
                                      '${widget.dbColumns[index]}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 5),
                                    // Description of the column
                                    Text(
                                      getColumnDescription(
                                          widget.dbColumns[index]),
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  width: 20), // Spacer between the two columns

                              // Right side - Dropdown for mapping the Excel columns
                              Expanded(
                                flex: 2,
                                child: DropdownButton<String?>(
                                  hint: Text("Select column"),
                                  value: columnMapping[index],
                                  onChanged: (newValue) {
                                    setState(() {
                                      columnMapping[index] = newValue;
                                    });
                                  },
                                  items: widget.excelColumns.map((column) {
                                    return DropdownMenuItem<String?>(
                                      value: column,
                                      child: Text(column),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPreviewPage(
                      excelData: widget.excelData,
                      dbColumns: widget.dbColumns,
                      manualMapping: widget.manualMapping,
                      columnMapping: columnMapping,
                    ),
                  ),
                );
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}


class ProductPreviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> excelData;
  final List<String> dbColumns;
  final bool manualMapping;
  final List<String?> columnMapping;

  ProductPreviewPage({
    required this.excelData,
    required this.dbColumns,
    required this.manualMapping,
    required this.columnMapping,
  });

  void updateDatabase(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> dataToInsert = [];

    for (var row in excelData) {
      Map<String, dynamic> mappedProduct = {};
      if (manualMapping) {
        for (int i = 0; i < dbColumns.length; i++) {
          String? excelColumn = columnMapping[i];
          if (excelColumn != null) {
            mappedProduct[dbColumns[i]] = row[excelColumn];
          }
        }
      } else {
        mappedProduct = row;
      }
      dataToInsert.add(mappedProduct);
    }

    for (var product in dataToInsert) {
      await dbHelper.insertOrUpdateProduct(product);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data updated successfully!")),
    );

    // Navigate to the Dashboard page after the operation
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview and Done'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Barcode')),
                    DataColumn(label: Text('In Stock')),
                    DataColumn(label: Text('Regular Price')),
                    DataColumn(label: Text('Sale Price')),
                    DataColumn(label: Text('Purchase Price')),
                    DataColumn(label: Text('Name')),
                  ],
                  rows: excelData.map((product) {
                    // Apply column mapping when displaying the data
                    List<DataCell> cells = [];
                    for (int i = 0; i < dbColumns.length; i++) {
                      String column = columnMapping[i] ?? dbColumns[i];
                      var value = product[column];
                      if (value == null) value = '';
                      cells.add(DataCell(Text(value.toString())));
                    }
                    return DataRow(cells: cells);
                  }).toList(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => updateDatabase(context),
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
