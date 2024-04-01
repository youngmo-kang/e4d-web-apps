import 'package:flutter/material.dart';
import 'package:report/blockgen.dart';

void main() {
  runApp(const ReportApp());
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'E4D Web App',
      home: BlockGen(),
    );
  }
}
