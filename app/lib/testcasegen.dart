import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

class TestCaseGen extends StatefulWidget {
  const TestCaseGen({super.key});

  @override
  State<TestCaseGen> createState() => _TestCaseGenState();
}

class _TestCaseGenState extends State<TestCaseGen> {
  // holds user uploaded csv
  List<List<dynamic>> _rowsOfColumns = [];
  // column name that contains the request
  final _codeColumnController = TextEditingController(text: "code");
  final _filenameColumnController = TextEditingController(text: "filename");
  // uploaded file name to display to the user
  String _fileName = "not selected";
  final _endpiont = "/blockgen";
  final _reportFilenameController =
      TextEditingController(text: "testcasegen-report.csv");
  String _userLog = '';
  final _sampleBlockgenInput = '''code,idx
"public with sharing class CryptoUtils {
  @AuraEnabled
  public static String decodeAndDecrypt(String encryptedBase64) {
    Blob cryptoKey = EncodingUtil.base64Decode(Constants.CRYPTO_SYMMETRIC_KEY);
    Blob encrypted = EncodingUtil.base64Decode(encryptedBase64);
    Blob decrypted = Crypto.decryptWithManagedIV(
      Constants.SYMMETRIC_ALGORITHM_NAME,
      cryptoKey,
      encrypted
    );
    return decrypted.toString();
  }
}",0
"public with sharing class CryptoUtils {
  @AuraEnabled
  public static String encryptAndEncode(String unencrypted) {
    Blob cryptoKey = EncodingUtil.base64Decode(Constants.CRYPTO_SYMMETRIC_KEY);
    Blob encrypted = Crypto.encryptWithManagedIV(
      Constants.SYMMETRIC_ALGORITHM_NAME,
      cryptoKey,
      Blob.valueOf(unencrypted)
    );
    return EncodingUtil.base64Encode(encrypted);
  }
}",1
''';

  bool _isValidCsv(List<List<dynamic>> content) {
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
      var content =
          const CsvToListConverter().convert(utf8.decode(file.bytes!));
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

  Future<List<String>> _postRequest(Uri endpoint, List<String> bodies) async {
    List<String> responses = [];
    for (final (idx, body) in bodies.indexed) {
      _log("Querying input ${idx + 1} out of ${bodies.length}...");
      var response = await http.post(endpoint,
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode({
            "inputPrompt": body,
            "keep-only-code": true, // this is test case generation
            "maxOutputToken": 4096,
          }));
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
    final codeColumn = _codeColumnController.text;
    final filenameColum = _filenameColumnController.text;
    if (codeColumn.isEmpty || filenameColum.isEmpty) {
      return _error("Column name can't be empty");
    }
    if (_rowsOfColumns.isEmpty) {
      return _error("Input csv file can't be empty");
    }

    final codeIdx = _rowsOfColumns[0].indexOf(codeColumn);
    final fileIdx = _rowsOfColumns[0].indexOf(filenameColum);
    if (codeIdx < 0) {
      return _error("Colunm '$codeColumn' not found in '$_fileName'");
    }
    if (fileIdx < 0) {
      return _error("Colunm '$filenameColum' not found in '$_fileName'");
    }

    final List<String> bodies = [];
    for (var ix = 1; ix < _rowsOfColumns.length; ++ix) {
      final code = _rowsOfColumns[ix][codeIdx];
      final filename = _rowsOfColumns[ix][fileIdx];
      final body = '''Here is some Apex code.

***Apex Code Context***
$code

Now please write Apex code following the instruction below. Also remember to consider the Apex Schema above.
write unit test for class $filename''';
      bodies.add(body);
    }

    try {
      _postRequest(Uri.parse(_endpiont), bodies).then((responses) {
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
                "testcasegen-sample-input.csv",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () => _createAndDownloadFile(
                  _sampleBlockgenInput, "testcasegen-sample-input.csv"),
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
              controller: _codeColumnController,
              decoration: const InputDecoration(
                labelText: 'Code column',
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
              controller: _filenameColumnController,
              decoration: const InputDecoration(
                labelText: 'Filename column',
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
