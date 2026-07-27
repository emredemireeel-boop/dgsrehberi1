class RoutineItem {
  String id;
  String title;
  bool isCompleted;

  RoutineItem(
      {required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'] ?? false,
      );
}

class DailyRoutine {
  String dateString;
  List<RoutineItem> items;
  bool get isSuccessful => items.where((i) => i.isCompleted).length >= 3;

  DailyRoutine({required this.dateString, required this.items});

  Map<String, dynamic> toJson() => {
        'dateString': dateString,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory DailyRoutine.fromJson(Map<String, dynamic> json) => DailyRoutine(
        dateString: json['dateString'],
        items: (json['items'] as List)
            .map((i) => RoutineItem.fromJson(i))
            .toList(),
      );
}
