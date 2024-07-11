import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kasa/components/expense_card.dart';
import 'package:kasa/screens/expense_screen.dart';
import 'package:kasa/screens/monthly_expenses_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpenses = 0.0;

  final Map<String, Color> categoryColors = {
    'Food': Colors.blue,
    'Transport': Colors.green,
    'Shopping': Colors.red,
    'Utilities': Colors.yellow,
    'Other': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Map<String, double> _calculateCategoryExpenses() {
    Map<String, double> categoryExpenses = {};
    for (var expense in _expenses) {
      String category = expense['category'];
      double amount = expense['amount'];
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
    }
    return categoryExpenses;
  }

  Future<void> _loadExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    setState(() {
      _expenses = List<Map<String, dynamic>>.from(jsonDecode(expensesJson));
      _calculateTotalExpenses();
    });
  }

  void _calculateTotalExpenses() {
    _totalExpenses =
        _expenses.fold(0.0, (sum, expense) => sum + (expense['amount'] as num));
  }

  Future<void> _saveExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_expenses);
    await prefs.setString('expenses', jsonString);
  }

  Future<void> _clearExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('expenses');
    setState(() {
      _expenses.clear();
      _totalExpenses = 0.0;
    });
  }

  void _showCategoryExpensesModal(
      BuildContext context, Map<String, double> categoryExpenses) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Category Expenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: categoryExpenses.length,
                  itemBuilder: (context, index) {
                    String category = categoryExpenses.keys.elementAt(index);
                    double amount = categoryExpenses[category]!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            categoryColors[category] ?? Colors.grey,
                      ),
                      title: Text(category),
                      trailing: Text(
                        '${amount.toStringAsFixed(2)} ₺',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart() {
    Map<String, double> categoryExpenses = _calculateCategoryExpenses();
    List<PieChartSectionData> sections = [];

    categoryExpenses.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: categoryColors[category] ?? Colors.grey,
          value: amount,
          title: '${(amount / _totalExpenses * 100).toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            _showCategoryExpensesModal(context, categoryExpenses);
          },
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/kasa2.png',
          height: 250,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFFF914D),
              ),
              child: Image.asset(
                'assets/images/kasa_menu.png',
                height: 250,
                fit: BoxFit.fitWidth,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Monthly Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MonthlyExpensesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear All Expenses'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Clear All Expenses'),
                      content: const Text(
                          'Are you sure you want to delete all expenses?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('Clear'),
                          onPressed: () {
                            _clearExpenses();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber[900],
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_totalExpenses.toStringAsFixed(2)}₺',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPieChart(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (BuildContext context, int index) {
                final expense = _expenses[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpenseCard(
                    category: expense['category'],
                    title: expense['title'],
                    amount: expense['amount'],
                    date: DateTime.parse(expense['date']),
                    photo: expense['photo'] != null
                        ? File(expense['photo'])
                        : null,
                    onEdit: () {
                      // Implement edit functionality
                      // For example, navigate to ExpenseScreen with current expense data
                    },
                    onDelete: () {
                      setState(() {
                        _expenses.removeAt(index);
                        _calculateTotalExpenses();
                      });
                      _saveExpenses();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(25.0),
        child: FloatingActionButton(
          backgroundColor: Colors.amber[900],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExpenseScreen(),
              ),
            ).then((result) {
              if (result != null) {
                setState(() {
                  _expenses.add(result);
                  _calculateTotalExpenses();
                });
                _saveExpenses();
              }
            });
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }
}
