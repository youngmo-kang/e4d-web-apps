import 'dart:convert';
import 'package:http/http.dart' as http;
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
  // holds user uploaded csv
  List<List<dynamic>> _rowsOfColumns = [];
  // column name that contains the request
  final _colNameController = TextEditingController(text: "input");
  // uploaded file name to display to the user
  String _fileName = "not uploaded";
  final _endpointController =
      TextEditingController(text: "http://localhost:8080/predictions/blockgen");

  bool _isValidCsv(List<List<dynamic>> content) {
    if (content.length < 3) return false;
    return true;
  }

  // updates _fileName and _rowsOfColumns
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
          // not uploaded
          _rowsOfColumns = [];
          _fileName = "not uploaded";
        }
      });
    }
    if (_rowsOfColumns.isEmpty) {
      _error(
          'Please upload a valid CSV file with a header and at least one record');
    }
  }

  Future<List<String>> _postRequest(Uri endpoint, List<String> bodies) async {
    List<String> responses = [];
    for (var body in bodies) {
      var response = await http.post(endpoint,
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode({"inputPrompt": body}));
      if (response.statusCode == 200) {
        responses.add(response.body);
      } else {
        throw Exception('Failed to post\n$body');
      }
    }
    return responses;
  }

  // generate report
  void _generate() async {
    final colName = _colNameController.text;
    bool err = colName.isEmpty ||
        _rowsOfColumns.isEmpty ||
        !_rowsOfColumns[0].contains(colName);
    if (err) {
      return _error(
          'Make sure to upload a csv and indicate which column corresponds to the input requests');
    }

    final colIdx = _rowsOfColumns[0].indexOf(colName);
    final List<String> bodies = [];
    for (var ix = 1; ix < _rowsOfColumns.length; ++ix) {
      final body = _rowsOfColumns[ix][colIdx];
      bodies.add(body);
    }

    try {
      _postRequest(Uri.parse(_endpointController.text), bodies)
          .then((responses) {
        List<List<dynamic>> result = List.from(_rowsOfColumns);
        result[0].add("output");
        for (var ix = 1; ix < _rowsOfColumns.length; ++ix) {
          result[ix].add(responses[ix - 1]);
        }
      });
    } catch (e) {
      return _error(e.toString());
    }
  }

  void _error(String msg) {
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
          SizedBox(
            width: 256,
            child: Form(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.always,
                controller: _colNameController,
                decoration: const InputDecoration(
                  labelText: 'Input column',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return (value == null ||
                          value.isEmpty ||
                          value == "output" ||
                          value.contains(RegExp(r'\s')))
                      ? "not a valid column name"
                      : null;
                },
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          SizedBox(
            width: 512,
            child: Form(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.always,
                controller: _endpointController,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "not a valid endpoint";
                  }
                  try {
                    Uri.parse(value);
                  } catch (_) {
                    return "not a valid endpoint";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Endpoint',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
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
