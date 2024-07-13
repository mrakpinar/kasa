import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditExpensesScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  final int index;

  const EditExpensesScreen({
    super.key,
    required this.expense,
    required this.index,
  });

  @override
  State<EditExpensesScreen> createState() => _EditExpensesScreenState();
}

class _EditExpensesScreenState extends State<EditExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late String? _title;
  late double _amount;
  late DateTime _date;
  File? _imageFile;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Utilities',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.expense['category'];
    _title = widget.expense['title'];
    _amount = widget.expense['amount'];
    _date = DateTime.parse(widget.expense['date']);
    if (widget.expense['photo'] != null) {
      _imageFile = File(widget.expense['photo']);
    }
  }

  Future<void> _getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String expensesJson = prefs.getString('expenses') ?? '[]';
      List<dynamic> expenseList = jsonDecode(expensesJson);

      expenseList[widget.index] = {
        'category': _category,
        'title': _title,
        'amount': _amount,
        'date': _date.toIso8601String(),
        'photo': _imageFile?.path,
      };

      await prefs.setString('expenses', jsonEncode(expenseList));

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Expense"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onSaved: (value) => _title = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount.toString(),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _amount = double.parse(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
                readOnly: true,
                controller: TextEditingController(
                  text: '${_date.day}/${_date.month}/${_date.year}',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _date) {
                    setState(() {
                      _date = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _getImage,
                icon: const Icon(Icons.photo),
                label: const Text('Change Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(_imageFile!, height: 200),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Update Expense',
                    style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
