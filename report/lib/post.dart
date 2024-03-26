import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  final endpoint = Uri.parse("http://35.223.0.29:8080/predictions/blockgen");
  http
      .post(endpoint,
          headers: {"Content-Type": "application/json"},
          body: json.encode({"inputPrompt": "write me hello world in dart"}))
      .then(
        (response) => print(response.body),
      );
}
