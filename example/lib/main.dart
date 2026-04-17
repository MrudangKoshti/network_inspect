import 'package:flutter/material.dart';
import 'package:network_inspect/network_inspect.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkMonitorOverlayHost(
      child: MaterialApp(
        title: 'network_inspect example',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const ExampleHomePage(),
      ),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _counter = 0;

  void _addLog() {
    setState(() => _counter++);
    NetworkMonitorFacade.instance.log(
      method: 'GET',
      url: 'https://api.example.com/orders?page=$_counter',
      requestHeaders: '{"authorization":"Bearer xyz"}',
      responseHeaders: '{"content-type":"application/json"}',
      requestBody: '{"page":$_counter}',
      responseBody: '{"success":true,"items":[1,2,3]}',
      statusCode: 200,
      durationMs: 80 + _counter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('network_inspect example')),
      body: Center(
        child: Text('Manual log count: $_counter'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLog,
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
      ),
    );
  }
}
