import 'package:flutter/material.dart';
import 'helpers/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() async {
    _history = await _dbHelper.getWalkingHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Walking History")),
      body: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final session = _history[index];
          return ListTile(
            title: Text("${session['date']} - ${session['dayname']}"),
            subtitle: Text(
                "Steps: ${session['steps']}, Calories: ${session['calories'].toStringAsFixed(2)}, Distance: ${session['distance'].toStringAsFixed(2)} km"),
          );
        },
      ),
    );
  }
}
