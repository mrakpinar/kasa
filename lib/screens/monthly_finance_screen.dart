import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MonthlyFinancesScreen extends StatefulWidget {
  const MonthlyFinancesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MonthlyFinancesScreenState createState() => _MonthlyFinancesScreenState();
}

class _MonthlyFinancesScreenState extends State<MonthlyFinancesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> monthlyExpenses = {};
  Map<String, double> monthlyIncomes = {};
  Map<String, Map<String, double>> monthlyExpensesByCategory = {};
  Map<String, Map<String, double>> monthlyIncomesBySource = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMonthlyFinances();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyFinances() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _loadMonthlyExpenses(),
      _loadMonthlyIncomes(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadMonthlyExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expenses = jsonDecode(expensesJson);

    monthlyExpensesByCategory =
        calculateMonthlyByCategory(expenses, 'category');
    monthlyExpenses = calculateMonthlyTotal(monthlyExpensesByCategory);
  }

  Future<void> _loadMonthlyIncomes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String incomesJson = prefs.getString('incomes') ?? '[]';
    final List<dynamic> incomes = jsonDecode(incomesJson);

    monthlyIncomesBySource = calculateMonthlyByCategory(incomes, 'source');
    monthlyIncomes = calculateMonthlyTotal(monthlyIncomesBySource);
  }

  Map<String, Map<String, double>> calculateMonthlyByCategory(
      List<dynamic> items, String categoryKey) {
    Map<String, Map<String, double>> monthlyItemsByCategory = {};

    for (var item in items) {
      DateTime date = DateTime.parse(item['date']);
      String monthYear =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      String category = item[categoryKey];
      double amount = item['amount'];

      monthlyItemsByCategory.putIfAbsent(monthYear, () => {});
      monthlyItemsByCategory[monthYear]!
          .update(category, (value) => value + amount, ifAbsent: () => amount);
    }

    return monthlyItemsByCategory;
  }

  Map<String, double> calculateMonthlyTotal(
      Map<String, Map<String, double>> monthlyItemsByCategory) {
    return monthlyItemsByCategory.map(
        (key, value) => MapEntry(key, value.values.reduce((a, b) => a + b)));
  }

  void _showMonthDetails(
      BuildContext context, String monthYear, bool isExpense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        Map<String, double> categoryItems = isExpense
            ? monthlyExpensesByCategory[monthYear] ?? {}
            : monthlyIncomesBySource[monthYear] ?? {};
        List<MapEntry<String, double>> sortedCategoryItems =
            categoryItems.entries.toList()
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
                    '${isExpense ? 'Expenses' : 'Incomes'} for ${DateFormat('MMMM yyyy').format(DateTime.parse('$monthYear-01'))}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: sortedCategoryItems.length,
                    itemBuilder: (context, index) {
                      final entry = sortedCategoryItems[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_getCategoryIcon(entry.key, isExpense)),
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

  IconData _getCategoryIcon(String category, bool isExpense) {
    if (isExpense) {
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
    } else {
      switch (category.toLowerCase()) {
        case 'salary':
          return Icons.work;
        case 'freelance':
          return Icons.computer;
        case 'investment':
          return Icons.trending_up;
        default:
          return Icons.attach_money;
      }
    }
  }

  Widget _buildFinanceList(Map<String, double> items, bool isExpense) {
    List<MapEntry<String, double>> sortedEntries = items.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedEntries.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isExpense ? Icons.money_off : Icons.account_balance_wallet,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${isExpense ? 'expenses' : 'incomes'} found',
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
              final totalAmount = entry.value;
              final date = DateTime.parse('$monthYear-01');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => _showMonthDetails(context, monthYear, isExpense),
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
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to see details',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Finances'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Incomes'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFinanceList(monthlyExpenses, true),
                _buildFinanceList(monthlyIncomes, false),
              ],
            ),
    );
  }
}
