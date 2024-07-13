import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kasa/components/expense_card.dart';
import 'package:kasa/screens/edit_expenses_screen.dart';
import 'package:kasa/screens/expense_screen.dart';
import 'package:kasa/screens/expenses_target.dart';
import 'package:kasa/screens/income_screen.dart';
import 'package:kasa/screens/monthly_finance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeMode;

  const HomeScreen({super.key, required this.themeMode});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];
  List<Map<String, dynamic>> _futureExpenses = [];
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
    _loadExpenses();
    _loadIncomes();
    _loadFutureExpenses();
  }

  Future<void> _loadExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    setState(() {
      _expenses = List<Map<String, dynamic>>.from(jsonDecode(expensesJson));
      _expenses = _expenses.reversed.toList();
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

  Future<void> _loadFutureExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String futureExpensesJson = prefs.getString('futureExpenses') ?? '[]';
    setState(() {
      _futureExpenses =
          List<Map<String, dynamic>>.from(jsonDecode(futureExpensesJson));
      _futureExpenses.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
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

  Future<void> _clearIncomes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('incomes');
    setState(() {
      // You may update any UI components here as needed
      _incomes.clear();
      _totalIncome = 0.0;
      _calculateBalance();
    });
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
      color: widget.themeMode.value == ThemeMode.dark
          ? Colors.grey[800] // Dark theme app bar color
          : Colors.white, // Light theme app bar color
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
              // ListTile(
              //   leading: const Icon(Icons.calendar_today),
              //   title: const Text('Add Future Expense'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const FutureExpenses(),
              //       ),
              //     ).then((result) {
              //       if (result != null) {
              //         setState(() {
              //           _futureExpenses.add(result);
              //           _futureExpenses.sort((a, b) => DateTime.parse(a['date'])
              //               .compareTo(DateTime.parse(b['date'])));
              //         });
              //         _loadFutureExpenses();
              //       }
              //     });
              //   },
              // ),
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
          color: widget.themeMode.value == ThemeMode.light
              ? const Color(0xFFFF7828)
              : Colors.grey[800],
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
                      '-${_totalExpenses.toStringAsFixed(2)}₺',
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

  // Widget _buildFutureExpensesList() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.symmetric(vertical: 8.0),
  //         child: Text(
  //           'Upcoming Expenses',
  //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //       if (_futureExpenses.isEmpty)
  //         const Padding(
  //           padding: EdgeInsets.all(8.0),
  //           child: Text('No upcoming expenses'),
  //         )
  //       else
  //         ListView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           itemCount: _futureExpenses.length,
  //           itemBuilder: (BuildContext context, int index) {
  //             final expense = _futureExpenses[index];
  //             return ListTile(
  //               title: Text(expense['title']),
  //               subtitle: Text(expense['category']),
  //               trailing: Text(
  //                 '${expense['amount'].toStringAsFixed(2)}₺\n${DateTime.parse(expense['date']).toString().split(' ')[0]}',
  //                 textAlign: TextAlign.end,
  //               ),
  //             );
  //           },
  //         ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeMode.value == ThemeMode.dark
            ? const Color(0xFFFF7828) // Dark theme app bar color
            : Colors.white, // Light theme app bar color
        title: Image.asset(
          widget.themeMode.value == ThemeMode.dark
              ? 'assets/images/kasa3.png'
              : 'assets/images/kasa2.png',
          height: widget.themeMode.value == ThemeMode.dark ? 200 : 250,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                size: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6), // Theme toggle icon
            onPressed: () {
              // Toggle theme logic
              if (widget.themeMode.value == ThemeMode.light) {
                widget.themeMode.value = ThemeMode.dark;
              } else {
                widget.themeMode.value = ThemeMode.light;
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
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
                    title: const Text('Monthly Finance'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MonthlyFinancesScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    thickness: 0.5,
                  ),
                  ListTile(
                    leading: const Icon(Icons.track_changes_outlined),
                    title: const Text('Expenses Target'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpensesTarget(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    thickness: 0.5,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('Clear Data'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Clear Data'),
                            content: const Text(
                              'What do you want to clear?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Expenses'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Clear Expenses'),
                                        content: const Text(
                                          'Are you sure you want to delete all expenses?',
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
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
                              TextButton(
                                child: const Text('Incomes'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Clear Incomes'),
                                        content: const Text(
                                          'Are you sure you want to delete all incomes?',
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                          TextButton(
                                            child: const Text('Clear'),
                                            onPressed: () {
                                              _clearIncomes();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    thickness: 0.5,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Switch Theme'),
              trailing: Switch(
                value: widget.themeMode.value == ThemeMode.dark,
                onChanged: (value) {
                  widget.themeMode.value =
                      value ? ThemeMode.dark : ThemeMode.light;
                  // Navigator.pop(context); // Optional: Close drawer after theme change
                },
                activeColor: Colors.orange,
                inactiveThumbColor: Colors.blueGrey[900],
                inactiveTrackColor: Colors.grey[300],
              ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditExpensesScreen(
                                expense: expense, // Mevcut harcama verisi
                                index: index, // Harcamanın listedeki indeksi
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              // Harcama güncellendi, listeyi yenile
                              _loadExpenses();
                            }
                          });
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
