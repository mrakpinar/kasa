import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MonthlyExpensesScreen extends StatefulWidget {
  const MonthlyExpensesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MonthlyExpensesScreenState createState() => _MonthlyExpensesScreenState();
}

class _MonthlyExpensesScreenState extends State<MonthlyExpensesScreen> {
  Map<String, double> monthlyExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlyExpenses();
  }

  Future<void> _loadMonthlyExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expenses = jsonDecode(expensesJson);

    Map<String, double> tempMonthlyExpenses = {};

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense['date']);
      String monthYear =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      double amount = expense['amount'];

      tempMonthlyExpenses[monthYear] =
          (tempMonthlyExpenses[monthYear] ?? 0) + amount;
    }

    setState(() {
      monthlyExpenses = tempMonthlyExpenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, double>> sortedEntries = monthlyExpenses.entries
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Expenses'),
      ),
      body: ListView.builder(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final monthYear = entry.key;
          final totalExpense = entry.value;

          return ListTile(
            title: Text(monthYear),
            trailing: Text('${totalExpense.toStringAsFixed(2)} ₺'),
          );
        },
      ),
    );
  }
}
