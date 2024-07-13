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
    final ThemeData theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    Color cardColor = isDarkTheme ? Colors.grey[800]! : Colors.white;
    Color textColor = isDarkTheme ? Colors.white : Colors.black;
    Color amountColor = Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: cardColor,
      elevation: 3,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title ?? 'Expense Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category: $category',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Amount:',
                            style: TextStyle(fontSize: 18, color: textColor)),
                        const SizedBox(width: 5),
                        Text('${amount.toStringAsFixed(2)}₺',
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${_formatDate(date)}',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    if (photo != null && File(photo!.path).existsSync())
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            _showFullScreenImage(context);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(photo!.path), height: 200),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onEdit != null) onEdit!();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onDelete != null) onDelete!();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
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
            style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
          ),
          subtitle: Row(
            children: [
              Text('$category - ', style: TextStyle(color: textColor)),
              Text('${amount.toStringAsFixed(2)}₺',
                  style: TextStyle(
                      color: amountColor, fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: Text(_formatDate(date), style: TextStyle(color: textColor)),
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
