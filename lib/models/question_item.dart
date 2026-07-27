class QuestionItem {
  final String filePath; // Dosya yolu, ID olarak da kullanılacak
  String category; // 'Sayisal', 'Sozel', veya ''
  List<int> reminderDays; // [3, 7, 21] vs
  final DateTime createdAt;

  QuestionItem({
    required this.filePath,
    this.category = '',
    this.reminderDays = const [],
    required this.createdAt,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    return QuestionItem(
      filePath: json['filePath'] as String,
      category: json['category'] as String? ?? '',
      reminderDays: (json['reminderDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'category': category,
      'reminderDays': reminderDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Bugün soru tekrar edilmesi gerekiyor mu?
  bool isDueToday() {
    if (reminderDays.isEmpty) return false;
    final today = DateTime.now();
    for (int day in reminderDays) {
      final due = createdAt.add(Duration(days: day));
      if (due.year == today.year &&
          due.month == today.month &&
          due.day == today.day) {
        return true;
      }
    }
    return false;
  }
}
