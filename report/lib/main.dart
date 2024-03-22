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
  List<List<dynamic>> rowsOfColumns = [];

  bool _isValidCsv(List<List<dynamic>> content) {
    if (content.length < 3) return false;
    return true;
  }

  void _pickFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null && picked.files.first.bytes != null) {
      var file = picked.files.first;
      var content =
          const CsvToListConverter(eol: '\n').convert(utf8.decode(file.bytes!).replaceAll('\r\n', '\n'));
      if (_isValidCsv(content)) {
        rowsOfColumns = content;
      } else {
        rowsOfColumns = [];
      }
    }
    if (rowsOfColumns.isEmpty) {
      // TODO: fix context warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a valid CSV file with a header and at least one record')),
      );
    }
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _pickFile,
            child: const Text('UPLOAD FILE'),
          ),
        ],
      ),
    );
  }
}
