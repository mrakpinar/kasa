import 'package:flutter/material.dart';

class EditExpensesScreen extends StatefulWidget {
  const EditExpensesScreen({super.key});

  @override
  State<EditExpensesScreen> createState() => _EditExpensesScreenState();
}

class _EditExpensesScreenState extends State<EditExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Expenses"),
      ),
    );
  }
}
