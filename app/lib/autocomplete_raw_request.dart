import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

class AutoCompleteRawRequest extends StatefulWidget {
  const AutoCompleteRawRequest({super.key});

  @override
  State<AutoCompleteRawRequest> createState() => _AutoCompleteRawRequestState();
}

class _AutoCompleteRawRequestState extends State<AutoCompleteRawRequest> {
  // holds user uploaded csv
  List<List<String>> _rowsOfColumns = [];
  // columns that contains the request
  // raw request, e.g., additionalProperties
  final _requestController =
      TextEditingController(text: "additionalProperties");
  // uploaded file name to display to the user
  String _fileName = "not selected";
  final _endpiont = "/autocomplete";
  final _reportFilenameController =
      TextEditingController(text: "autocomplete-raw-report.csv");
  String _userLog = '';
  final _sampleAutocompleteInput =
      'idx,additionalProperties\r\n0,"{""prefix"": ""public with sharing class User {\\n    public String name;\\n    public User(String name) {\\n        this.name = name;\\n    }\\n\\n    public static getUsers() {\\n        "", ""suffix"": ""\\n    }\\n    \\n\\n\\n        \\n}"", ""context"": ""{\\""current_file_path\\"":\\""./force-app/main/default/classes/User.cls\\"",\\""windows\\"":[{\\""file_path\\"":\\""./force-app/main/default/classes/UserTest.cls\\"",\\""text\\"":\\""@isTest\\\\nprivate class UserTest {\\\\n\\\\n}\\"",\\""similarity\\"":0.07692307692307693},{\\""file_path\\"":\\""./force-app/main/default/lwc/CompOne/CompOne.js\\"",\\""text\\"":\\""import { LightningElement } from \'lwc\';\\\\n\\\\nexport default class CompOne extends LightningElement {\\\\n    doWork() {\\\\n        let users = [\'one\', \'two\', \'three\'];\\\\n        for()\\\\n\\\\n    }\\\\n}\\"",\\""similarity\\"":0.04},{\\""file_path\\"":\\""./force-app/main/default/classes/UserTest.cls-meta.xml\\"",\\""text\\"":\\""<?xml version=\\\\\\""1.0\\\\\\"" encoding=\\\\\\""UTF-8\\\\\\""?>\\\\n<ApexClass xmlns=\\\\\\""http://soap.sforce.com/2006/04/metadata\\\\\\"">\\\\n    <apiVersion>59.0</apiVersion>\\\\n    <status>Active</status>\\\\n</ApexClass>\\"",\\""similarity\\"":0},{\\""file_path\\"":\\""./force-app/main/default/classes/User.cls-meta.xml\\"",\\""text\\"":\\""<?xml version=\\\\\\""1.0\\\\\\"" encoding=\\\\\\""UTF-8\\\\\\""?>\\\\n<ApexClass xmlns=\\\\\\""http://soap.sforce.com/2006/04/metadata\\\\\\"">\\\\n    <apiVersion>59.0</apiVersion>\\\\n    <status>Active</status>\\\\n</ApexClass>\\"",\\""similarity\\"":0}]}""}"\r\n1,"{""prefix"": ""def hello_world():"", ""suffix"": ""if __name__ == \'__main__\':\\n    main()"", ""lang_prefix"": ""<|python|>"", ""context"": ""{\\""current_file_path\\"": \\""/path/to/current/file.py\\"", \\""windows\\"": [{\\""file_path\\"": \\""/path/to/file1.py\\"", \\""text\\"": \\""import os\\\\ndef hello_file1(name):\\\\n    print(\'hello\')\\""}, {\\""file_path\\"": \\""/path/to/file2.py\\"", \\""text\\"": \\""import os\\\\ndef hello_file2(name):\\\\n    print(\'hello\')\\""}, {\\""file_path\\"": \\""/path/to/file3.py\\"", \\""text\\"": \\""import os\\\\ndef hello_file3(name):\\\\n    print(\'hello\')\\""}]}""}"\n';

  bool _isValidCsv(List<List<String>> content) {
    if (content.length < 2) return false; // at least one header and one body
    return true;
  }

  void _log(String text) {
    setState(() {
      _userLog = '${DateTime.now()}: $text\n$_userLog';
    });
  }

  // updates _fileName and _rowsOfColumns
  void _pickFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null && picked.files.first.bytes != null) {
      var file = picked.files.first;
      var content = const CsvToListConverter()
          .convert(utf8.decode(file.bytes!))
          .map((e) => e.map((e) => e.toString()).toList())
          .toList();
      setState(() {
        if (_isValidCsv(content)) {
          _log("'${file.name}' is a valid CSV");
          _rowsOfColumns = content;
          _fileName = file.name;
        } else {
          // not uploaded
          _log("'${file.name}' is a NOT valid CSV");
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

  Future<List<String>> _postRequest(Uri endpoint, List<Object> bodies) async {
    List<String> responses = [];
    const encoder = JsonEncoder.withIndent("    ");
    for (final (idx, body) in bodies.indexed) {
      _log("Querying input ${idx + 1} out of ${bodies.length}...");
      var encoded = encoder.convert(body);
      var response = await http.post(endpoint,
          headers: {
            "Content-Type": "application/json",
          },
          body: encoded);
      if (response.statusCode == 200) {
        responses.add(response.body);
      } else {
        const msg = 'Failed to query';
        _error(msg);
        throw Exception(msg);
      }
    }
    return responses;
  }

  void _createAndDownloadFile(String text, String filename) {
    final bytes = utf8.encode(text);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    _log("'$filename' has been downloaded");
  }

  // generate report
  void _generate() async {
    final rawRequest = _requestController.text;
    if (rawRequest.isEmpty) {
      return _error("Column name can't be empty");
    }
    if (_rowsOfColumns.isEmpty) {
      return _error("Input csv file can't be empty");
    }

    final requestIdx = _rowsOfColumns[0].indexOf(rawRequest);
    if (requestIdx < 0) {
      return _error("Colunm '$rawRequest' not found in '$_fileName'");
    }

    final List<Object> requests = [];
    for (var ix = 1; ix < _rowsOfColumns.length; ++ix) {
      final additionalProperties = json.decode(_rowsOfColumns[ix][requestIdx]);
      var request = {"additionalProperties": additionalProperties};
      requests.add(request);
    }

    try {
      _postRequest(Uri.parse(_endpiont), requests).then((responses) {
        List<List<dynamic>> result = List.from(_rowsOfColumns);
        result[0].add("output");
        for (var ix = 1; ix < _rowsOfColumns.length; ++ix) {
          result[ix].add(responses[ix - 1]);
        }

        final csv = const ListToCsvConverter().convert(result);
        _createAndDownloadFile(csv, _reportFilenameController.text);
      });
    } catch (e) {
      return _error(e.toString());
    }
  }

  void _error(String msg) {
    _log(msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 24,
        ),
        const Text(
          "codegen25-apex-lwc-7B-2k-triton-Dev-AutoComplete-0.10.0-20240314",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(
          height: 24,
        ),
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
            const SizedBox(
              width: 20,
            ),
            GestureDetector(
              child: const Text(
                "autocomplete-raw-sample-input.csv",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () => _createAndDownloadFile(_sampleAutocompleteInput,
                  "autocomplete-raw-sample-input.csv"),
            )
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
              controller: _requestController,
              decoration: const InputDecoration(
                labelText: 'request column',
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
          width: 256,
          child: Form(
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              controller: _reportFilenameController,
              validator: (String? value) {
                return value != null &&
                        RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(value)
                    ? null
                    : "not a valid filename";
              },
              decoration: const InputDecoration(
                labelText: 'Report filename',
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
        const SizedBox(
          height: 24,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Text(_userLog),
          ),
        ),
      ],
    );
  }
}
