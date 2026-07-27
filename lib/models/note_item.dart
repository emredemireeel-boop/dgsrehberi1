class NoteItem {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  final int colorIndex;
  bool isPinned;

  NoteItem({
    required this.id,
    this.title = '',
    required this.content,
    required this.createdAt,
    this.colorIndex = 0,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'colorIndex': colorIndex,
        'isPinned': isPinned,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'],
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        colorIndex: json['colorIndex'] ?? 0,
        isPinned: json['isPinned'] ?? false,
      );
}
