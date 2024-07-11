import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _source;
  double? _amount;
  DateTime? _date;

  final List<String> _sources = ['Salary', 'Freelance', 'Investment', 'Other'];

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      String incomesJson = prefs.getString('incomes') ?? '[]';
      List<dynamic> incomeList = jsonDecode(incomesJson);

      final Map<String, dynamic> newIncome = {
        'source': _source,
        'amount': _amount,
        'date': _date!.toIso8601String(),
      };

      incomeList.add(newIncome);

      await prefs.setString('incomes', jsonEncode(incomeList));

      // ignore: use_build_context_synchronously
      Navigator.pop(context, newIncome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _source,
                decoration: InputDecoration(
                  labelText: 'Source',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                items: _sources.map((String source) {
                  return DropdownMenuItem<String>(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _source = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a source';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _amount = double.tryParse(value ?? '0'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = picked;
                    });
                  }
                },
                readOnly: true,
                controller: TextEditingController(
                  text: _date == null ? '' : _date!.toString().split(' ')[0],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveIncome,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Save Income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
