import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MonthlyExpensesScreen extends StatefulWidget {
  const MonthlyExpensesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MonthlyExpensesScreenState createState() => _MonthlyExpensesScreenState();
}

class _MonthlyExpensesScreenState extends State<MonthlyExpensesScreen> {
  Map<String, double> monthlyExpenses = {};
  Map<String, Map<String, double>> monthlyExpensesByCategory = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyExpenses();
  }

  Future<void> _loadMonthlyExpenses() async {
    setState(() {
      isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expenses = jsonDecode(expensesJson);

    Map<String, double> tempMonthlyExpenses = {};
    Map<String, Map<String, double>> tempMonthlyExpensesByCategory =
        calculateMonthlyExpensesByCategory(expenses);

    for (var monthYear in tempMonthlyExpensesByCategory.keys) {
      tempMonthlyExpenses[monthYear] = tempMonthlyExpensesByCategory[monthYear]!
          .values
          .reduce((a, b) => a + b);
    }

    setState(() {
      monthlyExpenses = tempMonthlyExpenses;
      monthlyExpensesByCategory = tempMonthlyExpensesByCategory;
      isLoading = false;
    });
  }

  Map<String, Map<String, double>> calculateMonthlyExpensesByCategory(
      List<dynamic> expenses) {
    Map<String, Map<String, double>> monthlyExpensesByCategory = {};

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense['date']);
      String monthYear =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      String category = expense['category'];
      double amount = expense['amount'];

      if (!monthlyExpensesByCategory.containsKey(monthYear)) {
        monthlyExpensesByCategory[monthYear] = {};
      }
      monthlyExpensesByCategory[monthYear]![category] =
          (monthlyExpensesByCategory[monthYear]![category] ?? 0) + amount;
    }

    return monthlyExpensesByCategory;
  }

  void _showMonthDetails(BuildContext context, String monthYear) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        Map<String, double> categoryExpenses =
            monthlyExpensesByCategory[monthYear] ?? {};
        List<MapEntry<String, double>> sortedCategoryExpenses =
            categoryExpenses.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Expenses for ${DateFormat('MMMM yyyy').format(DateTime.parse('$monthYear-01'))}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: sortedCategoryExpenses.length,
                    itemBuilder: (context, index) {
                      final entry = sortedCategoryExpenses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_getCategoryIcon(entry.key)),
                        ),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value.toStringAsFixed(2)} ₺',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'utilities':
        return Icons.lightbulb;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, double>> sortedEntries = monthlyExpenses.entries
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expenses'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    final monthYear = entry.key;
                    final totalExpense = entry.value;
                    final date = DateTime.parse('$monthYear-01');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () => _showMonthDetails(context, monthYear),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(date),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to see details',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Text(
                                '${totalExpense.toStringAsFixed(2)} ₺',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
