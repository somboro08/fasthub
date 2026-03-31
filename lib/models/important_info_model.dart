class ImportantInfoModel {
  final String id;
  final String authorId;
  final String title;
  final String author;
  final DateTime publishedAt;
  final String content;

  ImportantInfoModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.author,
    required this.publishedAt,
    required this.content,
  });

  factory ImportantInfoModel.fromJson(Map<String, dynamic> json) {
    return ImportantInfoModel(
      id: json['id'],
      authorId: json['author_id'] ?? '',
      title: json['title'],
      author: json['author'],
      publishedAt: DateTime.parse(json['published_at']),
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'author': author,
      'published_at': publishedAt.toIso8601String(),
      'content': content,
    };
  }
}