import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kasa/components/expense_card.dart';
import 'package:kasa/screens/expense_screen.dart';
import 'package:kasa/screens/expenses_target.dart';
import 'package:kasa/screens/future_expenses.dart';
import 'package:kasa/screens/income_screen.dart';
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
  List<Map<String, dynamic>> _incomes = [];
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;
  double _balance = 0.0;
  bool _showDetails = false;

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
    _loadExpenses().then((_) {
      setState(() {
        _expenses = _expenses.reversed.toList();
      });
    });
    _loadIncomes();
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
      _calculateBalance();
    });
  }

  Future<void> _loadIncomes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String incomesJson = prefs.getString('incomes') ?? '[]';
    setState(() {
      _incomes = List<Map<String, dynamic>>.from(jsonDecode(incomesJson));
      _calculateTotalIncome();
      _calculateBalance();
    });
  }

  void _calculateTotalExpenses() {
    _totalExpenses =
        _expenses.fold(0.0, (sum, expense) => sum + (expense['amount'] as num));
  }

  void _calculateTotalIncome() {
    _totalIncome =
        _incomes.fold(0.0, (sum, income) => sum + (income['amount'] as num));
  }

  void _calculateBalance() {
    _balance = _totalIncome - _totalExpenses;
  }

  Future<void> _saveExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_expenses.reversed.toList());
    await prefs.setString('expenses', jsonString);
  }

  Future<void> _saveIncomes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_incomes);
    await prefs.setString('incomes', jsonString);
  }

  Future<void> _clearExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('expenses');
    setState(() {
      _expenses.clear();
      _totalExpenses = 0.0;
      _calculateBalance();
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

    if (categoryExpenses.isEmpty) {
      // Hiç harcama yoksa, tek bir gri bölüm göster
      sections.add(
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: 'No Data',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    } else {
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
    }

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: categoryExpenses.isNotEmpty
              ? () {
                  _showCategoryExpensesModal(context, categoryExpenses);
                }
              : null,
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

  void _showAddOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.money_off),
                title: const Text('Add Expense'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseScreen(),
                    ),
                  ).then((result) {
                    if (result != null) {
                      setState(() {
                        _expenses.insert(0, result);
                        _calculateTotalExpenses();
                        _calculateBalance();
                      });
                      _saveExpenses();
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Add Income'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncomeScreen(),
                    ),
                  ).then((result) {
                    if (result != null) {
                      setState(() {
                        _incomes.add(result);
                        _calculateTotalIncome();
                        _calculateBalance();
                      });
                      _saveIncomes();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialSummary() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7828),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      _balance >= 0
                          ? '${_balance.toStringAsFixed(2)}₺'
                          : '-${_balance.abs().toStringAsFixed(2)}₺',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _showDetails
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
            if (_showDetails) ...[
              const Divider(color: Colors.white, thickness: 1, height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${_totalIncome.toStringAsFixed(2)}₺',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${_totalExpenses.toStringAsFixed(2)}₺',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                color: Color(0xFFFF7828),
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
              leading: const Icon(Icons.add_alarm_outlined),
              title: const Text('Future Expenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FutureExpenses()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes_outlined),
              title: const Text('Expenses Target'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExpensesTarget()),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildFinancialSummary(),
              const SizedBox(height: 20),
              _buildPieChart(),
              const SizedBox(height: 20),
              if (_expenses.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 45),
                      const Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add an expense',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _expenses.length,
                  itemBuilder: (BuildContext context, int index) {
                    final expense = _expenses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        },
                        onDelete: () {
                          setState(() {
                            _expenses.removeAt(index);
                            _calculateTotalExpenses();
                            _calculateBalance();
                          });
                          _saveExpenses();
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(25.0),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFF7828),
          onPressed: () {
            _showAddOptionsModal(context);
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
