class PlanBlock {
  final String id;
  final String dateKey; // 'yyyy-MM-dd'
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final String subject;
  final String? note;
  bool isCompleted;

  PlanBlock({
    required this.id,
    required this.dateKey,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.subject,
    this.note,
    this.isCompleted = false,
  });

  int get endHour => ((startHour * 60 + startMinute + durationMinutes) ~/ 60);
  int get endMinute => ((startHour * 60 + startMinute + durationMinutes) % 60);

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'startHour': startHour,
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
        'subject': subject,
        'note': note,
        'isCompleted': isCompleted,
      };

  factory PlanBlock.fromJson(Map<String, dynamic> json) => PlanBlock(
        id: json['id'],
        dateKey: json['dateKey'],
        startHour: json['startHour'] ?? 8,
        startMinute: json['startMinute'] ?? 0,
        durationMinutes: json['durationMinutes'] ?? 60,
        subject: json['subject'] ?? 'Genel',
        note: json['note'],
        isCompleted: json['isCompleted'] ?? false,
      );
}
