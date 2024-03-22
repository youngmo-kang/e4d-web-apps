import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const ReportApp());
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'E4D Web App',
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<List<dynamic>> _rowsOfColumns = [];
  String _colName = "";
  String _fileName = "";

  bool _isValidCsv(List<List<dynamic>> content) {
    if (content.length < 3) return false;
    return true;
  }

  void _pickFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null && picked.files.first.bytes != null) {
      var file = picked.files.first;
      var content = const CsvToListConverter(eol: '\n')
          .convert(utf8.decode(file.bytes!).replaceAll('\r\n', '\n'));
      setState(() {
        if (_isValidCsv(content)) {
          _rowsOfColumns = content;
          _fileName = file.name;
        } else {
          _rowsOfColumns = [];
          _fileName = "";
        }
      });
    }
    if (_rowsOfColumns.isEmpty) {
      _error(
          'Please upload a valid CSV file with a header and at least one record');
    }
  }

  void _generate() {
    bool err = _colName.isEmpty ||
        _rowsOfColumns.isEmpty ||
        !_rowsOfColumns[0].contains(_colName);

    if (err) {
      _error(
          'Make sure to upload a csv and indicate which column corresponds to the input requests');
    }
  }

  _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'E4D Autocomplete Report Generation',
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Upload input csv file'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_fileName),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Input column: "),
              SizedBox(
                height: 24,
                width: 128,
                child: TextField(
                  onChanged: (value) => _colName = value,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Center(
            child: ElevatedButton(
              onPressed: _generate,
              child: const Text('Generate report'),
            ),
          ),
        ],
      ),
    );
  }
}
