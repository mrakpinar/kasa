class Expense {
  final String category;
  final String? title;
  final double amount;
  final DateTime date;
  final String? photo; // Burada string yerine File tipinde veri tutabilirsin.

  Expense({
    required this.category,
    this.title,
    required this.amount,
    required this.date,
    this.photo,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'photo': photo,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      category: json['category'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      photo: json['photo'],
    );
  }
}
