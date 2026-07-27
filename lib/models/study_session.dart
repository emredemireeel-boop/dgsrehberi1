class StudySession {
  final String id;
  final DateTime date;
  final int durationSeconds;
  final int breakSeconds;
  final int verbalQuestions;
  final int numericalQuestions;
  final String subject; // yeni alan

  StudySession({
    required this.id,
    required this.date,
    required this.durationSeconds,
    this.breakSeconds = 0,
    this.verbalQuestions = 0,
    this.numericalQuestions = 0,
    this.subject = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
        'breakSeconds': breakSeconds,
        'verbalQuestions': verbalQuestions,
        'numericalQuestions': numericalQuestions,
        'subject': subject,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'],
        date: DateTime.parse(json['date']),
        durationSeconds: json['durationSeconds'],
        breakSeconds: json['breakSeconds'] ?? 0,
        verbalQuestions:
            json['verbalQuestions'] ?? json['questionsSolved'] ?? 0,
        numericalQuestions: json['numericalQuestions'] ?? 0,
        subject: json['subject'] ?? '',
      );
}
