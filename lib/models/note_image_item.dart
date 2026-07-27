class NoteImageItem {
  final String filePath;
  String tag; // Kullanıcının atadığı etiket (ör. 'Formül', 'Özet', '')
  final DateTime createdAt;

  NoteImageItem({
    required this.filePath,
    this.tag = '',
    required this.createdAt,
  });

  factory NoteImageItem.fromJson(Map<String, dynamic> json) {
    return NoteImageItem(
      filePath: json['filePath'] as String,
      tag: json['tag'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'tag': tag,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
