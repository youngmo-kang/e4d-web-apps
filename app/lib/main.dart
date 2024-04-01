import 'package:flutter/material.dart';
import 'package:report/autocomplete.dart';
import 'package:report/blockgen.dart';

void main() {
  runApp(const ReportApp());
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E4D Web App',
      home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(
                    text: "BlockGen",
                  ),
                  Tab(text: "Autocomplete"),
                ],
              ),
              title: const Text("E4D Repor Generation"),
            ),
            body: const TabBarView(
              children: [
                BlockGen(),
                AutoComplete(),
              ],
            ),
          )),
    );
  }
}
