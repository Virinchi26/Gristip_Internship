import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/db_helper.dart';

class ProductImportPage extends StatefulWidget {
  const ProductImportPage({super.key});

  @override
  _ProductImportPageState createState() => _ProductImportPageState();
}

class _ProductImportPageState extends State<ProductImportPage> {
  bool manualMapping = false;
  File? selectedFile;
  List<String> excelColumns = [];
  Map<String, String> columnMapping = {};
  List<Map<String, dynamic>> importedData = [];

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        selectedFile = file;
      });
      extractColumns(file);
    }
  }

  void extractColumns(File file) {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    if (excel.tables.isNotEmpty) {
      var sheet = excel.tables.values.first;
      var headerRow = sheet.rows.first;
      setState(() {
        excelColumns =
            headerRow.map((cell) => cell?.value.toString() ?? '').toList();
      });
    }
  }

  void importData() {
    if (selectedFile == null) return;
    var bytes = selectedFile!.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> tempData = [];
    if (excel.tables.isNotEmpty) {
      var sheet = excel.tables.values.first;
      for (int i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];
        Map<String, dynamic> rowData = {};
        for (var entry in columnMapping.entries) {
          rowData[entry.key] =
              row[excelColumns.indexOf(entry.value)]?.value?.toString() ?? '';
        }
        tempData.add(rowData);
      }
    }
    setState(() {
      importedData = tempData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Products')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text(
                  selectedFile == null ? 'Pick Excel File' : 'File Selected'),
            ),
            CheckboxListTile(
              title: Text('Manually map columns'),
              value: manualMapping,
              onChanged: (bool? value) {
                setState(() {
                  manualMapping = value ?? false;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (manualMapping) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ColumnMappingPage(
                        excelColumns: excelColumns,
                        onMappingComplete: (mapping) {
                          setState(() {
                            columnMapping = mapping;
                          });
                          importData();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ImportResultPage(data: importedData),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  importData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ImportResultPage(data: importedData),
                    ),
                  );
                }
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class ColumnMappingPage extends StatefulWidget {
  final List<String> excelColumns;
  final Function(Map<String, String>) onMappingComplete;

  ColumnMappingPage(
      {required this.excelColumns, required this.onMappingComplete});

  @override
  _ColumnMappingPageState createState() => _ColumnMappingPageState();
}

class _ColumnMappingPageState extends State<ColumnMappingPage> {
  final List<String> dbColumns = [
    'barcode',
    'inStock',
    'regularPrice',
    'salePrice',
    'purchasePrice',
    'name'
  ];
  Map<String, String> selectedMapping = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map Columns')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: dbColumns.length,
                itemBuilder: (context, index) {
                  String dbColumn = dbColumns[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dbColumn, style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: selectedMapping[dbColumn],
                        items: widget.excelColumns.map((col) {
                          return DropdownMenuItem(
                            value: col,
                            child: Text(col),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMapping[dbColumn] = newValue ?? '';
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onMappingComplete(selectedMapping);
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportResultPage extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  ImportResultPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Imported Data')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: data.isNotEmpty
              ? DataTable(
                  columns: data.first.keys
                      .map((key) => DataColumn(label: Text(key)))
                      .toList(),
                  rows: data.map((row) {
                    return DataRow(
                      cells: row.values
                          .map((value) => DataCell(Text(value.toString())))
                          .toList(),
                    );
                  }).toList(),
                )
              : Center(child: Text('No data available')),
        ),
      ),
    );
  }
}
