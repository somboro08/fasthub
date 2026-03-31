class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final String? parentId; // For nested comments
  final String targetId; // ID of the publication or important info
  final String targetType; // 'publication' or 'important_info'

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.parentId,
    required this.targetId,
    required this.targetType,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      authorId: json['author_id'],
      authorName: json['author_name'],
      authorAvatarUrl: json['author_avatar_url'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      parentId: json['parent_id'],
      targetId: json['target_id'],
      targetType: json['target_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'parent_id': parentId,
      'target_id': targetId,
      'target_type': targetType,
    };
  }
}
