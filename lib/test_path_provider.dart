import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TestPathProvider extends StatefulWidget {
  const TestPathProvider({super.key});

  @override
  State<TestPathProvider> createState() => _TestPathProviderState();
}

class _TestPathProviderState extends State<TestPathProvider> {
  String _result = 'Testing...';

  @override
  void initState() {
    super.initState();
    _testPathProvider();
  }

  Future<void> _testPathProvider() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();

      setState(() {
        _result = 'SUCCESS!\n\n'
            'Temp Dir: ${tempDir.path}\n\n'
            'App Dir: ${appDir.path}';
      });
    } catch (e) {
      setState(() {
        _result = 'ERROR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Path Provider Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_result),
        ),
      ),
    );
  }
}