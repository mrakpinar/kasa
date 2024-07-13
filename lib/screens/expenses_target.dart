// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesTarget extends StatefulWidget {
  const ExpensesTarget({super.key});

  @override
  State<ExpensesTarget> createState() => _ExpensesTargetState();
}

class _ExpensesTargetState extends State<ExpensesTarget> {
  final _formKey = GlobalKey<FormState>();
  double? _targetAmount;
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTargetAmount();
  }

  Future<void> _loadTargetAmount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetAmount = prefs.getDouble('targetAmount');
      _targetController.text = _targetAmount?.toString() ?? '';
    });
  }

  Future<void> _saveTargetAmount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('targetAmount', _targetAmount!);

      setState(() {
        // Update the displayed target amount
        _targetAmount = _targetAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target amount saved')),
      );
    }
  }

  Future<void> _resetTargetAmount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('targetAmount');
    setState(() {
      _targetAmount = null;
      _targetController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Target amount reset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses Target"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          "Current Target",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _targetAmount == null
                              ? "Not set"
                              : "${_targetAmount!.toStringAsFixed(2)}₺",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: 'Set New Target Amount',
                    prefixIcon: const Icon(Icons.money_sharp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      _targetAmount = double.tryParse(value ?? '0'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a target amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveTargetAmount,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child:
                      const Text('Save Target', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _resetTargetAmount,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text('Reset Target',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}
