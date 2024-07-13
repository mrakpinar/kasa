// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureExpenses extends StatefulWidget {
  const FutureExpenses({super.key});

  @override
  State<FutureExpenses> createState() => _FutureExpensesState();
}

class _FutureExpensesState extends State<FutureExpenses> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  String? _title;
  double? _amount;
  DateTime? _date;
  File? _imageFile;
  bool _imageSelected = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Utilities',
    'Other'
  ];
  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        _imageSelected = true;
      } else {
        // ignore: avoid_print
        print('No image selected.');
      }
    });
  }

  Future<void> _saveFutureExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get current future expenses list
      String futureExpensesJson = prefs.getString('futureExpenses') ?? '[]';
      List<dynamic> futureExpenseList = jsonDecode(futureExpensesJson);

      final Map<String, dynamic> newFutureExpense = {
        'category': _category,
        'title': _title,
        'amount': _amount,
        'date': _date!.toIso8601String(),
        'photo': _imageFile?.path,
      };

      // Add new future expense to list
      futureExpenseList.add(newFutureExpense);

      // Save list as a JSON
      await prefs.setString('futureExpenses', jsonEncode(futureExpenseList));

      // // Schedule notification
      // await NotificationsService.scheduleNotification(
      //   id: futureExpenseList.length - 1,
      //   title: 'Expense Reminder',
      //   body: 'You have a scheduled expense: $_title',
      //   scheduledDate: _date!,
      // );

      // Return to previous screen
      Navigator.pop(context, newFutureExpense);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Future Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                    _category = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onSaved: (value) => _title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                    firstDate: DateTime.now(),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take a picture'),
                            onTap: () {
                              _getImage(ImageSource.camera);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('Choose from gallery'),
                            onTap: () {
                              _getImage(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.photo),
                label: const Text('Add Photo'),
              ),
              if (_imageSelected && _imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 200,
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFutureExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text('Save Future Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
