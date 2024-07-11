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

  @override
  void initState() {
    super.initState();
    _loadTargetAmount();
  }

  Future<void> _loadTargetAmount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetAmount = prefs.getDouble('targetAmount');
    });
  }

  Future<void> _saveTargetAmount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('targetAmount', _targetAmount!);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target amount saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses Target"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$_targetAmount",
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 100),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Set Target Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                initialValue: _targetAmount?.toString(),
                onSaved: (value) =>
                    _targetAmount = double.tryParse(value ?? '0'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTargetAmount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Save Target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
