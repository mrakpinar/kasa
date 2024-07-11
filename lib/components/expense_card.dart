import 'dart:io';

import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final String category;
  final String? title;
  final double amount;
  final DateTime date;
  final File? photo;
  final Function()? onEdit;
  final Function()? onDelete;

  const ExpenseCard({
    super.key,
    required this.category,
    this.title,
    required this.amount,
    required this.date,
    this.photo,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title ?? 'Expense Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: $category'),
                    Row(
                      children: [
                        const Text('Amount:'),
                        Text('${amount.toStringAsFixed(2)}₺',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold))
                      ],
                    ),
                    Text('Date: ${_formatDate(date)}'),
                    if (photo != null && File(photo!.path).existsSync())
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Mevcut dialog'u kapat
                          _showFullScreenImage(
                              context); // Tam ekran fotoğrafı göster
                        },
                        child: Image.file(File(photo!.path), height: 100),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Edit'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onEdit != null) onEdit!();
                    },
                  ),
                  TextButton(
                    child: const Text('Delete'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onDelete != null) onDelete!();
                    },
                  ),
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        },
        child: ListTile(
          leading: photo != null && File(photo!.path).existsSync()
              ? CircleAvatar(backgroundImage: FileImage(File(photo!.path)))
              : const CircleAvatar(child: Icon(Icons.receipt)),
          title: Text(
            title ?? '',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              Text(
                '$category - ',
              ),
              Text('${amount.toStringAsFixed(2)}₺',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))
            ],
          ),
          // ignore: unnecessary_string_interpolations
          trailing: Text('${_formatDate(date)}'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Image.file(File(photo!.path)),
          ),
        );
      },
    );
  }
}
